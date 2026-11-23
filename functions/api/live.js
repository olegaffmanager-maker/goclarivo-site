// GoClarivo · /api/live (Cloudflare Pages Function): marcador en vivo de la sección /futbol/ desde la Marketing API de 1xBet.
// Variables del proyecto en Cloudflare Pages (las pone Oleg): ONEXBET_CLIENT_ID, ONEXBET_CLIENT_SECRET, ONEXBET_REF (+ ONEXBET_GR opcional).
// Sin variables responde una lista vacía (las páginas siguen funcionando). Caché 30 s.
const API = 'https://cpservm.com/gateway';
const KEEP = /^(argentina|mexico|chile|peru|ecuador|bolivia|paraguay|espana)\.|libertadores|sudamericana|^liga de campeones de la uefa$|^uefa champions league$|^inglaterra\. premier league$/;
const SKIP = /femen|women|\(f\)|reserv|sub-?\d|u-?\d\d|juvenil|virtual|ecomp|e-?sport|cyber|fifa|4x4|5x5|short/;
const slug = (s) => String(s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const low = (x) => String(x || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().trim();
let TOK = null, TOKX = 0, MEM = null, MEMX = 0, STAT = '', NALL = 0;
async function token(env) {
  if (TOK && Date.now() < TOKX) return TOK;
  const id = (env.ONEXBET_CLIENT_ID || '').trim(), sec = (env.ONEXBET_CLIENT_SECRET || '').trim();
  for (const cid of [id, id.startsWith('partners-') ? id.slice(9) : 'partners-' + id]) {
    const r = await fetch(API + '/token', { method: 'POST', body: new URLSearchParams({ client_id: cid, client_secret: sec }), headers: { 'content-type': 'application/x-www-form-urlencoded' } });
    if (!r.ok) continue;
    const j = await r.json().catch(() => ({}));
    if (j.access_token) { TOK = j.access_token; TOKX = Date.now() + Math.max(60, (j.expires_in || 1800) - 120) * 1000; return TOK; }
  }
  throw new Error('token');
}
async function live(env) {
  if (!env.ONEXBET_CLIENT_ID || !env.ONEXBET_CLIENT_SECRET || !env.ONEXBET_REF) { STAT = 'sin-claves'; return []; }
  const tok = await token(env);
  const q = new URLSearchParams({ ref: env.ONEXBET_REF.trim(), sportIds: '1', count: '500', lng: 'es' });
  if (env.ONEXBET_GR) q.set('gr', env.ONEXBET_GR.trim());
  const r = await fetch(`${API}/marketing/datafeed/live/api/v2/sportevents?${q}`, { headers: { Authorization: 'Bearer ' + tok } });
  if (r.status === 401) { TOK = null; STAT = 'token-401'; return []; }
  if (!r.ok) { STAT = 'api-' + r.status; return []; }
  const j = await r.json();
  STAT = 'ok'; NALL = (j.items || []).length;
  return (j.items || []).filter((e) => { const t = low(e.tournamentNameLocalization); return KEEP.test(t) && !SKIP.test(t) && !/virtual|esports|\(e\)/i.test((e.opponent1NameLocalization || '') + (e.opponent2NameLocalization || '')); })
    .map((e) => ({ k: slug(e.opponent1NameLocalization) + '|' + slug(e.opponent2NameLocalization), h: e.opponent1NameLocalization, a: e.opponent2NameLocalization, tn: e.tournamentNameLocalization, s: [(e.curScore || {}).sc1 || 0, (e.curScore || {}).sc2 || 0], min: e.timeSec ? Math.floor(e.timeSec / 60) : null, p: e.currentPeriodName || e.periodName || '', st: e.startDate }));
}
export async function onRequestGet({ request, env, waitUntil }) {
  const u = new URL(request.url), cache = caches.default, key = new Request(u.origin + '/api/live');
  const hit = await cache.match(key);
  if (hit) return hit;
  let m = [];
  if (MEM && Date.now() < MEMX) m = MEM;
  else { try { m = await live(env); } catch (e) { m = []; STAT = 'error-' + String(e.message || e).slice(0, 20); } MEM = m; MEMX = Date.now() + 30000; }
  const res = new Response(JSON.stringify({ t: Math.floor(Date.now() / 1000), estado: STAT, en_vivo_total: NALL, m }), { headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'public, max-age=30', 'x-robots-tag': 'noindex' } });
  waitUntil(cache.put(key, res.clone()));
  return res;
}
