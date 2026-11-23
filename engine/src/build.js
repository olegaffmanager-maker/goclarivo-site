// GoClarivo — sección de fútbol. Motor de Liga Chapina / Liga Tica / Marcador Central.
// Una corrida por país: RG=ar|mx|… escribe /<geo>/futbol/…; RG=root escribe /futbol/ (portada internacional, en vivo, copas y ligas europeas, sitemap y búsqueda).
// Las demás páginas de GoClarivo (bonos, casas, guías) no las toca este generador.
const CSSV = require("crypto").createHash("md5").update(require("fs").readFileSync(require("path").join(__dirname, "assets", "style.css"))).digest("hex").slice(0, 8);
// Generador estático -> dist/. Motor de Buteur. Nunca inventa datos: lo desconocido se muestra como «por confirmar» / «sin datos».
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const OUT = path.join(ROOT, 'dist'); // engine/dist → all.js lo copia a la raíz del repo
const COUNTRIES = require('./countries.js');
const RG = process.env.RG || 'root', IS_ROOT = RG === 'root';
const CK = Object.keys(COUNTRIES);
const C = IS_ROOT ? { key: 'root', slug: '', name: 'Internacional', nation: '', de: 'de Argentina', adj: 'internacional', adjf: 'internacional', tz: 'America/Argentina/Buenos_Aires', utc: 'UTC-3', loc: 'es-419', liga: 'fútbol', ligaLong: 'fútbol internacional', ligaKw: 'fútbol', canon: [], info: {}, topc: [], clasicos: {}, money: '', cur: '$', season: ['year', 'Temporada'] } : COUNTRIES[RG];
const PREFIX = IS_ROOT ? '/futbol' : `/${C.key}/futbol`;
// La corrida root (la última) lee lo que dejó cada país en dist/.parts/<país>.json
const PIN = IS_ROOT ? CK.map((k) => { const f = path.join(OUT, '.parts', `${k}.json`); return fs.existsSync(f) ? { k, ...JSON.parse(fs.readFileSync(f, 'utf8')) } : { k, sitemap: [], search: [], hot: [], matches: [], lead: [], lastRes: [] }; }) : [];
const DATA = process.env.DATA_DIR || path.join(ROOT, 'data', IS_ROOT ? 'int' : RG);
const read = (f, d) => (fs.existsSync(path.join(DATA, f)) ? JSON.parse(fs.readFileSync(path.join(DATA, f), 'utf8')) : d);
const site = JSON.parse(fs.readFileSync(path.join(__dirname, 'site.json'), 'utf8'));
const MD = read('matches.json', { groups: [] });
const RD = read('results.json', { matches: [] });

const TZ = C.tz;
const NOW = +process.env.BUILD_NOW || Date.now();
const BASE = site.base.replace(/\/$/, '');
const esc = (s) => String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const slug = (s) => String(s).normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
// Sin enlaces de afiliado donde la publicidad de 1xBet no corresponde (C.aff === false: España, Chile)
const NOAFF = !IS_ROOT && C.aff === false;
const X = NOAFF ? { link: '', apk: '', code: '' } : site.brands['1xbet'];
const CODE = X.code || '';
const updated = new Intl.DateTimeFormat(C.loc, { timeZone: TZ, day: 'numeric', month: 'long', year: 'numeric' }).format(new Date(site.checked + 'T12:00:00Z'));

// ---------- enlaces ----------
// SubID por ubicación: tag=d_<site>m_<ad>c_<subid> → informe «Marketing tools» del partner. Prefijo gc_<geo>_ (gc_int_ en /futbol/).
const SUB = (u, s) => (u ? u.replace(/(tag=d_\d+m_\d+c_)(?=&|$)/, '$1gc_' + (IS_ROOT ? 'int' : C.key) + '_' + s) : u);
const AFF = 'rel="sponsored nofollow noopener" target="_blank"';
const go = (label, cls = 'cta', sub = 'web') => { const L = SUB(X.link, sub); return L ? `<a class="${cls}" href="${esc(L)}" ${AFF}>${label}</a>` : ''; };
const goApk = (label, sub) => (X.apk ? `<a class="cta" href="${esc(SUB(X.apk, sub))}" ${AFF}>${label}</a>` : go(label, 'cta', sub));
const LINK1 = SUB(X.link, 'cuota');
const deep = (m) => { if (!LINK1) return ''; try { const p = new URL(m.link).pathname.replace(/^\/[a-z]{2}\//, '/').replace(/^\//, ''); return p.startsWith('line/') && /r=registration/.test(LINK1) ? LINK1.replace(/r=registration/, 'r=' + encodeURIComponent(p)) : LINK1; } catch (e) { return LINK1; } };
const clink = (m, k) => { const c = X.coupon_links && m.coupon && m.coupon[k]; if (!c || !LINK1 || !/r=registration/.test(LINK1)) return deep(m); return LINK1.replace(/r=registration/, 'r=' + encodeURIComponent((X.coupon_r || '?coupon-code={code}').replace('{code}', c))); };

// ---------- hora (de cada país; ninguno tiene horario de verano) ----------
const f0 = (o) => new Intl.DateTimeFormat(C.loc, { timeZone: TZ, ...o });
const fDay = f0({ weekday: 'short', day: 'numeric', month: 'short' });
const fHour = f0({ hour: 'numeric', minute: '2-digit', hour12: true });
const day = (t) => fDay.format(new Date(t * 1000)).replace(/\./g, '');
const hour = (t) => fHour.format(new Date(t * 1000)).replace(/\s?a\.\s?m\./, ' a. m.').replace(/\s?p\.\s?m\./, ' p. m.');
const when = (t) => `${day(t)} · ${hour(t)} (hora ${C.de})`;
// Hora en cada país (páginas internacionales): «9:00 p. m. Argentina, Chile y Paraguay · 7:00 p. m. Perú y Ecuador…»
const ZONES = [['Argentina', 'America/Argentina/Buenos_Aires'], ['Chile', 'America/Santiago'], ['Paraguay', 'America/Asuncion'], ['Bolivia', 'America/La_Paz'], ['Perú', 'America/Lima'], ['Ecuador', 'America/Guayaquil'], ['México', 'America/Mexico_City'], ['España', 'Europe/Madrid']];
const zfmt = ZONES.map(([n, z]) => [n, new Intl.DateTimeFormat('es-419', { timeZone: z, hour: 'numeric', minute: '2-digit', hour12: true }), new Intl.DateTimeFormat('es-419', { timeZone: z, weekday: 'short', day: 'numeric' })]);
const ylist = (xs) => (xs.length > 1 ? xs.slice(0, -1).join(', ') + ' y ' + xs[xs.length - 1] : xs[0]);
const zoneRows = (t) => { const d0 = zfmt[0][2].format(new Date(t * 1000)), g = []; for (const [n, f, fd] of zfmt) { const d = fd.format(new Date(t * 1000)); const h = f.format(new Date(t * 1000)).replace(/\s?a\.\s?m\./, ' a. m.').replace(/\s?p\.\s?m\./, ' p. m.') + (d !== d0 ? ` (${d.replace(/\./g, '')})` : ''); const x = g.find((y) => y.h === h); if (x) x.n.push(n); else g.push({ h, n: [n] }); } return g; };
const zonesHtml = (t) => `<div class="zones">${zoneRows(t).map((x) => `<span><b>${esc(x.h)}</b> ${esc(ylist(x.n))}</span>`).join('')}</div>`;
const zonesTxt = (t) => zoneRows(t).map((x) => `${x.h} en ${ylist(x.n)}`).join('; ');
const tm = (t) => `<time datetime="${new Date(t * 1000).toISOString()}">${when(t)}</time>`;
const dyear = (t) => f0({ day: 'numeric', month: 'short', year: 'numeric' }).format(new Date(t * 1000)).replace(/\./g, '');
const dshort = (t) => f0({ day: 'numeric', month: 'short' }).format(new Date(t * 1000)).replace(/\./g, '');

// ---------- nombres de equipos (la API escribe cada club de varias formas) ----------
const CANON = C.canon;
const canon = (n) => { const x = String(n || '').replace(/\s*\([^)]*\)\s*$/, '').trim(); const s = slug(x); const c = CANON.find(([re]) => re.test(s)); return c ? c[1] : x; };
const same = (a, b) => slug(a) === slug(b);
// Nombre oficial y apodos (solo los seguros). «rojos vs» 1.4K, «cremas», «club social y deportivo municipal» (posiciones 33K), «csd comunicaciones».
const INFO = C.info;
const nickOf = (n) => (INFO[n] && INFO[n].nick ? INFO[n].nick.replace(/^./, (c) => c.toUpperCase()) : null);

// ---------- partidos ----------
const INTL = new Set(['copa-libertadores', 'copa-sudamericana', 'champions-league', 'laliga', 'premier-league']);
// Copas de clubes: en cada país se muestran los partidos de sus clubes (datos de engine/data/int)
const CUPS = new Set(['copa-libertadores', 'copa-sudamericana']);
if (!IS_ROOT) {
  const ri = (f, d) => { const p = path.join(ROOT, 'data', 'int', f); return fs.existsSync(p) ? JSON.parse(fs.readFileSync(p, 'utf8')) : d; };
  const own = new Set([...(MD.groups || []).filter((g) => g.key === 'liga').flatMap((g) => (g.matches || []).flatMap((m) => [m.home, m.away])), ...(RD.matches || []).filter((r) => r.group === 'liga').flatMap((r) => [r.home, r.away])].map((n) => slug(canon(n))));
  const mine = (m) => own.has(slug(canon(m.home))) || own.has(slug(canon(m.away)));
  MD.groups = [...(MD.groups || []), ...(ri('matches.json', { groups: [] }).groups || []).filter((g) => CUPS.has(g.key)).map((g) => ({ ...g, matches: (g.matches || []).filter(mine) }))];
  RD.matches = [...(RD.matches || []), ...(ri('results.json', { matches: [] }).matches || []).filter((r) => CUPS.has(r.group) && mine(r))];
}
const strip = (n) => String(n || '').replace(/\s*\([^)]*\)\s*$/, '').trim();
const tname = (t) => String(t || '').replace(new RegExp('^' + (C.nation || '#') + '\\.\\s*', 'i'), '');
const groups = (MD.groups || []).map((g) => ({ ...g, matches: (g.matches || []).filter((m) => m.start * 1000 > NOW - 3 * 36e5 && !/divisi[oó]n 2|segunda|jugador/i.test(m.tournament || '')).sort((a, b) => a.start - b.start).map((m) => { const c = INTL.has(g.key) && (IS_ROOT || !CUPS.has(g.key)) ? strip : canon; return { ...m, rk: slug(strip(m.home)) + '|' + slug(strip(m.away)), tournament: tname(m.tournament), home: c(m.home), away: c(m.away) }; }) }));
// Partidos que empezaron hace menos de 3 h siguen en la página (marcador en vivo vía /api/live).
const ALL = (() => { const seen = new Set(), out = []; for (const g of groups) for (const m of g.matches) { const k = slug(m.home) + slug(m.away) + m.start; if (!seen.has(k)) { seen.add(k); out.push({ ...m, group: g.key, gname: g.name }); } } return out.sort((a, b) => a.start - b.start); })();
const LIGA = ALL.filter((m) => m.group === 'liga');
const GNAME = { liga: C.ligaLong, seleccion: 'Selección', 'copa-libertadores': 'Copa Libertadores', 'copa-sudamericana': 'Copa Sudamericana', 'champions-league': 'Champions League', laliga: 'LaLiga', 'premier-league': 'Premier League' };

// ---------- resultados ----------
const RES = (() => {
  const out = {};
  // Partidos suspendidos: 1xBet guarda solo un tiempo («0:0 (0:0)»). No cuentan (se reprograman y vuelven a jugarse).
for (const r of (RD.matches || []).filter((r) => !/^\d+:\d+ \(\d+:\d+\)$/.test(r.detail || '') && !/divisi[oó]n 2|segunda/i.test(r.tname || '')).map((r) => ({ ...r, home: canon(r.home), away: canon(r.away) })).sort((a, b) => a.start - b.start)) out[[r.group, r.tid, Math.floor(r.start / (120 * 86400)), slug(r.home), slug(r.away)].join('|')] = r;
  return Object.values(out).sort((a, b) => b.start - a.start);
})();
// La API mezcla a veces partidos ajenos (p. ej. filiales mexicanas): solo equipos con 3+ partidos en la liga.
const RLIGA = (() => { const all = RES.filter((r) => r.group === 'liga'), c = {}; for (const r of all) for (const t of [r.home, r.away]) c[slug(t)] = (c[slug(t)] || 0) + 1; return all.filter((r) => c[slug(r.home)] >= 3 && c[slug(r.away)] >= 3); })();
// Torneo actual: Apertura (julio–diciembre) o Clausura (enero–junio).
// C.season: ['halves', 'nombre ene–jun', 'nombre jul–dic'] · ['year', 'Campeonato'] · ['euro'] (agosto–mayo)
const TORNEO = (() => {
  const d = new Date(NOW - 6 * 36e5), y = d.getUTCFullYear(), mo = d.getUTCMonth(), S = C.season || ['year', 'Temporada'];
  if (S[0] === 'halves') { const h2 = mo >= 6; return { name: `${h2 ? S[2] : S[1]} ${y}`, from: Date.UTC(y, h2 ? 6 : 0, 1) / 1000, y }; }
  if (S[0] === 'euro') { const y0 = mo >= 6 ? y : y - 1; return { name: `temporada ${y0}-${String(y0 + 1).slice(2)}`, from: Date.UTC(y0, 6, 15) / 1000, y: y0, ys: `${y0}-${String(y0 + 1).slice(2)}` }; }
  return { name: `${S[1]} ${y}`, from: Date.UTC(y, 0, 1) / 1000, y };
})();
const CUR = RLIGA.filter((r) => r.start >= TORNEO.from);
const JORNADAS = C.jornadas || Math.max(2, 2 * (new Set(CUR.flatMap((r) => [slug(r.home), slug(r.away)])).size - 1)); // fase regular: todos contra todos, ida y vuelta; después vienen las finales
function standings(rs) {
  const T = {};
  for (const r of [...rs].sort((a, b) => a.start - b.start)) {
    const [a, b] = r.score;
    const xs = [[r.home, a, b], [r.away, b, a]].map(([t]) => (T[t] = T[t] || { team: t, pj: 0, g: 0, e: 0, p: 0, gf: 0, gc: 0, pts: 0, form: [] }));
    if (xs.some((x) => x.pj >= JORNADAS)) continue; // liguilla: no cuenta para la tabla
    for (const [x, gf, ga] of [[xs[0], a, b], [xs[1], b, a]]) {
      x.pj++; x.gf += gf; x.gc += ga;
      if (gf > ga) { x.g++; x.pts += 3; } else if (gf === ga) { x.e++; x.pts += 1; } else x.p++;
      x.form.push([r.start, gf > ga ? 'G' : gf === ga ? 'E' : 'P']);
    }
  }
  return Object.values(T).map((x) => ({ ...x, dif: x.gf - x.gc, form: x.form.sort((p, q) => q[0] - p[0]).slice(0, 5).map((f) => f[1]) }))
    .sort((p, q) => q.pts - p.pts || q.dif - p.dif || q.gf - p.gf || p.team.localeCompare(q.team));
}
const TABLE = CUR.length >= 6 ? standings(CUR) : [];
const LIGUILLA = CUR.filter((r) => { const n = (t) => CUR.filter((x) => x.start <= r.start && (same(x.home, t) || same(x.away, t))).length; return n(r.home) > JORNADAS && n(r.away) > JORNADAS; });

// ---------- clubes ----------
const CLUBS = (() => { const by = {}; for (const n of [...LIGA, ...CUR].flatMap((m) => [m.home, m.away])) { const s = slug(n); if (s !== slug(C.nation || '#') && !by[s]) by[s] = { slug: s, name: n }; } return Object.values(by).sort((a, b) => a.name.localeCompare(b.name, 'es')); })();
const clubOf = (n) => CLUBS.find((k) => k.slug === slug(n));
// Escudos: scripts/team_logos.py los guarda en src/assets/t/ (64x64 PNG) y data/logos.json da {nombre 1xBet: archivo}
const LOGOS = (() => { const o = {}; const all = {}; for (const d of [DATA, ...CK.map((k) => path.join(ROOT, 'data', k)), path.join(ROOT, 'data', 'int')]) { const f = path.join(d, 'logos.json'); if (fs.existsSync(f)) Object.assign(all, JSON.parse(fs.readFileSync(f, 'utf8')), { ...all }); } for (const [k, f] of Object.entries(all)) { const c = canon(k); if (!o[c] && fs.existsSync(path.join(ROOT, 'assets', 't', f))) o[c] = f; } return o; })();
const ini = (n) => String(n || '').normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^A-Za-z0-9 ]/g, ' ').split(/\s+/).filter((w) => w.length > 1 || /\d/.test(w)).slice(0, 2).map((w) => w[0]).join('').toUpperCase() || '·';
// Selecciones sin escudo en los datos: bandera simplificada dibujada en CSS (solo franjas y colores, sin escudos).
const FH = (...c) => `linear-gradient(180deg,${c.map((x, i) => `${x} ${((i * 100) / c.length).toFixed(1)}% ${(((i + 1) * 100) / c.length).toFixed(1)}%`).join(',')})`;
const FV = (...c) => FH(...c).replace('180deg', '90deg');
const FLAGS = (() => {
  const f = {
    bolivia: FH('#d52b1e', '#f9e300', '#007934'), argentina: FH('#74acdf', '#fff', '#74acdf'), peru: FV('#d91023', '#fff', '#d91023'), ecuador: 'linear-gradient(180deg,#ffd100 0 50%,#034ea2 50% 75%,#ef3340 75%)', paraguay: FH('#d52b1e', '#fff', '#0038a8'), colombia: 'linear-gradient(180deg,#fcd116 0 50%,#003893 50% 75%,#ce1126 75%)', venezuela: FH('#ffcc00', '#00247d', '#cf142b'), chile: 'linear-gradient(90deg,#0039a6 0 33%,transparent 33%) 0 0/100% 50% no-repeat,linear-gradient(180deg,#fff 0 50%,#d52b1e 50%)', uruguay: 'repeating-linear-gradient(180deg,#fff 0 11.1%,#0038a8 11.1% 22.2%)', brasil: 'radial-gradient(circle,#002776 0 18%,transparent 19%),radial-gradient(ellipse 48% 42%,#ffdf00 97%,#009c3b 100%)',
    mexico: FV('#006847', '#fff', '#ce1126'), 'estados-unidos': 'linear-gradient(90deg,#3c3b6e 0 40%,transparent 40%) 0 0/100% 54% no-repeat,repeating-linear-gradient(180deg,#b22234 0 7.7%,#fff 7.7% 15.4%)', canada: 'linear-gradient(90deg,#d52b1e 0 25%,#fff 25% 75%,#d52b1e 75%)', 'costa-rica': 'linear-gradient(180deg,#002b7f 0 16.6%,#fff 16.6% 33.3%,#ce1126 33.3% 66.6%,#fff 66.6% 83.3%,#002b7f 83.3%)', guatemala: FV('#4997d0', '#fff', '#4997d0'), honduras: FH('#0073cf', '#fff', '#0073cf'), 'el-salvador': FH('#0047ab', '#fff', '#0047ab'), nicaragua: FH('#0067c6', '#fff', '#0067c6'), panama: 'conic-gradient(from 90deg,#fff 0 25%,#072357 0 50%,#fff 0 75%,#da121a 0)', 'republica-dominicana': 'linear-gradient(90deg,transparent 44%,#fff 44% 56%,transparent 56%),linear-gradient(180deg,transparent 42%,#fff 42% 58%,transparent 58%),conic-gradient(from 90deg,#002d62 0 25%,#ce1126 0 50%,#002d62 0 75%,#ce1126 0)', jamaica: 'linear-gradient(33deg,transparent 42%,#fed100 42% 58%,transparent 58%),linear-gradient(-33deg,#009b3a 42%,#fed100 42% 58%,#000 58%)', haiti: FH('#00209f', '#d21034'), 'trinidad-y-tobago': 'linear-gradient(135deg,#ce1126 0 38%,#fff 38% 42%,#000 42% 58%,#fff 58% 62%,#ce1126 62%)', curazao: 'linear-gradient(180deg,#002b7f 0 62%,#f9e814 62% 75%,#002b7f 75%)', surinam: 'linear-gradient(180deg,#377e3f 0 20%,#fff 20% 30%,#b40a2d 30% 70%,#fff 70% 80%,#377e3f 80%)',
    espana: 'linear-gradient(180deg,#aa151b 0 25%,#f1bf00 25% 75%,#aa151b 75%)', francia: FV('#0055a4', '#fff', '#ef4135'), alemania: FH('#000', '#dd0000', '#ffce00'), italia: FV('#009246', '#fff', '#ce2b37'), portugal: 'linear-gradient(90deg,#006600 0 40%,#ff0000 40%)', inglaterra: 'linear-gradient(90deg,transparent 43%,#ce1124 43% 57%,transparent 57%),linear-gradient(180deg,#fff 0 40%,#ce1124 40% 60%,#fff 60%)', escocia: 'linear-gradient(33deg,transparent 45%,#fff 45% 55%,transparent 55%),linear-gradient(-33deg,#005eb8 45%,#fff 45% 55%,#005eb8 55%)', 'bosnia-y-herzegovina': 'linear-gradient(135deg,#002395 0 32%,#fecb00 32% 62%,#002395 62%)',
    japon: 'radial-gradient(circle,#bc002d 0 30%,#fff 32%)', 'corea-del-sur': 'radial-gradient(circle,#cd2e3a 0 14%,#0047a0 15% 25%,#fff 26%)', india: FH('#ff9933', '#fff', '#138808'), singapur: FH('#ef3340', '#fff'), kuwait: 'linear-gradient(90deg,#000 0 25%,transparent 25%),' + FH('#007a3d', '#fff', '#ce1126'), 'emiratos-arabes-unidos': 'linear-gradient(90deg,#ff0000 0 25%,transparent 25%),' + FH('#00732f', '#fff', '#000'), 'arabia-saudita': '#006c35', qatar: 'linear-gradient(90deg,#fff 0 30%,#8a1538 30%)', iran: FH('#239f40', '#fff', '#da0000'), 'nueva-zelanda': 'radial-gradient(circle at 74% 50%,#c8102e 0 9%,#012169 11%)', australia: 'radial-gradient(circle at 74% 50%,#fff 0 7%,#012169 9%)',
    // Afrique (noms en français, pour Buteur) + équivalents espagnols
    cameroun: FV('#007a5e', '#ce1126', '#fcd116'), senegal: FV('#00853f', '#fdef42', '#e31b23'), 'cote-d-ivoire': FV('#f77f00', '#fff', '#009e60'), gambie: 'linear-gradient(180deg,#ce1126 0 30%,#fff 30% 35%,#0c1c8c 35% 65%,#fff 65% 70%,#3a7728 70%)', soudan: 'linear-gradient(90deg,#007229 0 25%,transparent 25%),' + FH('#d21034', '#fff', '#000'), namibie: 'linear-gradient(135deg,#003580 0 40%,#fff 40% 43%,#d21034 43% 57%,#fff 57% 60%,#009543 60%)', togo: FH('#006a4e', '#ffce00', '#006a4e', '#ffce00', '#006a4e'), algerie: FV('#006233', '#fff'), angola: FH('#cc092f', '#000'), libye: 'linear-gradient(180deg,#e70013 0 25%,#000 25% 75%,#239e46 75%)', tunisie: 'radial-gradient(circle,#fff 0 28%,#e70013 30%)', kenya: 'linear-gradient(180deg,#000 0 30%,#fff 30% 35%,#bb0000 35% 65%,#fff 65% 70%,#006600 70%)', 'afrique-du-sud': 'linear-gradient(180deg,#e03c31 0 33%,#fff 33% 38%,#007749 38% 62%,#fff 62% 67%,#001489 67%)', 'sierra-leone': FH('#1eb53a', '#fff', '#0072c6'), 'rd-congo': 'linear-gradient(135deg,#007fff 0 40%,#f7d618 40% 44%,#ce1021 44% 56%,#f7d618 56% 60%,#007fff 60%)', 'guinee-bissau': 'linear-gradient(90deg,#ce1126 0 33%,transparent 33%),' + FH('#fcd116', '#009e49'), madagascar: 'linear-gradient(90deg,#fff 0 33%,transparent 33%),' + FH('#fc3d32', '#007e3a'), ethiopie: FH('#078930', '#fcdd09', '#da121a'), mozambique: FH('#007168', '#000', '#fce100'), 'soudan-du-sud': FH('#000', '#da121a', '#078930'), malawi: FH('#000', '#ce1126', '#339e35'), somalie: 'radial-gradient(circle,#fff 0 22%,#4189dd 24%)', ghana: FH('#ce1126', '#fcd116', '#006b3f'), tanzanie: 'linear-gradient(135deg,#1eb53a 0 38%,#fcd116 38% 42%,#000 42% 58%,#fcd116 58% 62%,#00a3dd 62%)', nigeria: FV('#008751', '#fff', '#008751'), burundi: 'linear-gradient(33deg,transparent 44%,#fff 44% 56%,transparent 56%),linear-gradient(-33deg,transparent 44%,#fff 44% 56%,transparent 56%),conic-gradient(from 45deg,#1eb53a 0 25%,#ce1126 0 50%,#1eb53a 0 75%,#ce1126 0)', zambie: 'linear-gradient(90deg,#198a00 0 70%,#de2010 70% 80%,#000 80% 90%,#ef7d00 90%)', lesotho: FH('#00209f', '#fff', '#009543'), gabon: FH('#009e60', '#fcd116', '#3a75c4'), egypte: FH('#ce1126', '#fff', '#000'), erythree: 'linear-gradient(90deg,#ea0437 0 35%,transparent 35%),' + FH('#12ad2b', '#4189dd'), guinee: FV('#ce1126', '#fcd116', '#009460'), centrafrique: 'linear-gradient(90deg,transparent 43%,#d21034 43% 57%,transparent 57%),' + FH('#003082', '#fff', '#289728', '#ffce00'), benin: 'linear-gradient(90deg,#008751 0 40%,transparent 40%),' + FH('#fcd116', '#e8112d'), zimbabwe: FH('#006400', '#ffd200', '#d40000', '#000', '#d40000', '#ffd200', '#006400'), 'guinee-equatoriale': FH('#3e9a00', '#fff', '#e32118'), comores: 'linear-gradient(90deg,#3d8e33 0 30%,transparent 30%),' + FH('#ffc61e', '#fff', '#ce1126', '#3a75c4'), ouganda: FH('#000', '#fcdc04', '#d90000', '#000', '#fcdc04', '#d90000'), botswana: 'linear-gradient(180deg,#75aadb 0 40%,#fff 40% 44%,#000 44% 56%,#fff 56% 60%,#75aadb 60%)', maroc: 'radial-gradient(circle,#006233 0 18%,#c1272d 20%)', niger: FH('#e05206', '#fff', '#0db02b'), mali: FV('#14b53a', '#fcd116', '#ce1126'), rwanda: 'linear-gradient(180deg,#00a1de 0 50%,#fad201 50% 75%,#20603d 75%)', congo: 'linear-gradient(135deg,#009543 0 40%,#fbde4a 40% 60%,#dc241f 60%)', 'cap-vert': 'linear-gradient(180deg,#003893 0 50%,#fff 50% 58%,#cf2027 58% 67%,#fff 67% 75%,#003893 75%)', liberia: 'linear-gradient(90deg,#002868 0 36%,transparent 36%) 0 0/100% 46% no-repeat,repeating-linear-gradient(180deg,#bf0a30 0 9.1%,#fff 9.1% 18.2%)', 'burkina-faso': 'radial-gradient(circle,#fcd116 0 14%,transparent 16%),' + FH('#ef2b2d', '#009e49'), mauritanie: 'linear-gradient(180deg,#d01c1f 0 15%,#00a95c 15% 85%,#d01c1f 85%)', tchad: FV('#002664', '#fecb00', '#c60c30'), france: FV('#0055a4', '#fff', '#ef4135'), eswatini: 'linear-gradient(180deg,#3e5eb9 0 18%,#ffd900 18% 25%,#b10c0c 25% 75%,#ffd900 75% 82%,#3e5eb9 82%)', maurice: FH('#ea2839', '#1a206d', '#ffd500', '#00a551'), djibouti: 'linear-gradient(90deg,#fff 0 35%,transparent 35%),' + FH('#6ab2e7', '#12ad2b'),
  };
  const alias = { argelia: 'algerie', marruecos: 'maroc', sudafrica: 'afrique-du-sud', 'dr-congo': 'rd-congo', 'guinea-bissau': 'guinee-bissau', 'cape-verde': 'cap-vert', 'cabo-verde': 'cap-vert', 'archipel-des-comores': 'comores', 'costa-de-marfil': 'cote-d-ivoire', camerun: 'cameroun', 'estados-unidos-de-america': 'estados-unidos', usa: 'estados-unidos', egipto: 'egypte', tunez: 'tunisie', nigeria: 'nigeria', japan: 'japon', brazil: 'brasil', bresil: 'brasil', argentine: 'argentina', espagne: 'espana', portugal: 'portugal', allemagne: 'alemania', italie: 'italia', angleterre: 'inglaterra', ecosse: 'escocia', mexique: 'mexico', 'etats-unis': 'estados-unidos', colombie: 'colombia', perou: 'peru', bolivie: 'bolivia', equateur: 'ecuador', chili: 'chile', japon: 'japon', 'coree-du-sud': 'corea-del-sur', inde: 'india', haiti: 'haiti' };
  for (const [a, b] of Object.entries(alias)) if (!f[a] && f[b]) f[a] = f[b];
  return f;
})();
const flagOf = (n) => FLAGS[slug(String(n || '').replace(/\s*\([^)]*\)\s*$/, '').trim())] || null;
const flagSpan = (n, sz, big) => `<span class="cr cf${big ? ' crb' : ''}" style="width:${sz}px;height:${Math.round(sz * 0.68)}px;background:${flagOf(n)}"${big ? ` role="img" aria-label="${esc(n)}"` : ' aria-hidden="true"'}></span>`;
const crest = (n, sz = 22, big = false) => { const f = LOGOS[canon(n)]; if (!f && flagOf(n)) return flagSpan(n, sz, big); return f ? `<img class="cr${big ? ' crb' : ''}" src="/futbol/assets/t/${f}" width="${sz}" height="${sz}" loading="${big ? 'eager' : 'lazy'}" decoding="async" alt="${big ? `Escudo de ${esc(n)}` : ''}">` : `<span class="cr ci${big ? ' crb' : ''}" style="width:${sz}px;height:${sz}px;font-size:${Math.round(sz * 0.38)}px" aria-hidden="true">${esc(ini(n))}</span>`; };
const vsBox = (h, a) => `<div class="vsb">${crest(h, 56, true)}<span>vs</span>${crest(a, 56, true)}</div>`;
const curl = (n) => `/equipos/${slug(n)}/`;
const teamLink = (n) => (C.nation && same(n, C.nation) ? `<a href="${SELU}">${esc(n)}</a>` : clubOf(n) ? `<a href="${curl(n)}">${esc(n)}</a>` : esc(n));
const plays = (n) => (m) => same(m.home, n) || same(m.away, n);
const lastOf = (n, k = 5) => RES.filter(plays(n)).slice(0, k);
const nextOf = (n) => ALL.filter(plays(n));
const posOf = (n) => { const i = TABLE.findIndex((x) => same(x.team, n)); return i >= 0 ? { pos: i + 1, ...TABLE[i] } : null; };
const pairKey = (a, b) => [slug(a), slug(b)].sort();
const purl = (a, b) => { const [x, y] = pairKey(a, b); return `/${x}-vs-${y}/`; };
const isPair = (a, b) => clubOf(a) && clubOf(b) && !same(a, b);
const SELU = `/seleccion-de-${slug(C.nation || 'x')}/`;
const bvsUrl = (r) => `/${slug(C.nation || 'x')}-vs-${slug(r)}/`;
const iurl = (B, F) => `/${slug(B)}-vs-${slug(F)}/`;
// Nombres cortos de clubes extranjeros (como se buscan: «blooming vs river», «nacional potosí vs botafogo», «bolívar vs são paulo»)
const FSHORT = { 'sociedade-esportiva-palmeiras': 'Palmeiras', 'gremio-porto-alegrense': 'Grêmio', 'botafogo-de-futebol-e-regatas': 'Botafogo', 'racing-club-de-avellaneda': 'Racing Club', 'river-plate-buenos-aires': 'River Plate', 'cruzeiro-esporte-clube': 'Cruzeiro', 'cr-vasco-da-gama': 'Vasco da Gama', 'club-atletico-penarol': 'Peñarol', 'club-nacional-montevideo': 'Nacional (Uruguay)', 'club-olimpia': 'Olimpia', 'club-libertad': 'Libertad', 'club-atletico-tigre': 'Tigre', 'club-universitario-de-deportes': 'Universitario', 'club-independiente-santa-fe': 'Independiente Santa Fe', 'club-social-y-deportivo-macara': 'Macará', 'club-atletico-boston-river': 'Boston River', 'sao-paulo': 'São Paulo', 'atletico-mineiro': 'Atlético Mineiro', 'america-de-cali': 'América de Cali', 'barcelona-sporting-club': 'Barcelona SC', 'universidad-catolica-santiago': 'Universidad Católica' };
const fname = (n) => FSHORT[slug(strip(n))] || strip(n);
// Selección → /<país>-vs-<rival>/; club local vs extranjero en Concacaf → /<club>-vs-<rival>/; el resto → /partido/
const ownUrl = (m) => { if (C.nation && (same(m.home, C.nation) || same(m.away, C.nation))) return bvsUrl(same(m.home, C.nation) ? m.away : m.home); if (CUPS.has(m.group)) { const h = clubOf(m.home), a = clubOf(m.away); if (!!h !== !!a) return iurl(h ? h.name : a.name, fname(h ? m.away : m.home)); } return null; };
const murl = (m) => m.url || (isPair(m.home, m.away) ? purl(m.home, m.away) : ownUrl(m) || `/partido/${slug(m.home)}-vs-${slug(m.away)}/`);

// ---------- piezas html ----------
const formHtml = (f) => `<span class="form">${f.map((x) => `<i class="f${{ G: 'V', E: 'N', P: 'D' }[x]}">${x}</i>`).join('')}</span>`;
// around: solo las filas de esos equipos y sus vecinos (evita repetir la tabla completa en cada página)
const near = (T, names, k) => { const keep = new Set(); T.forEach((x, i) => { if (names.some((n) => same(n, x.team))) for (let d = -k; d <= k; d++) keep.add(i + d); }); return T.map((x, i) => ({ x, i })).filter(({ i }) => keep.has(i)); };
const tableHtml = (T, { top = 0, mark = [], around = null } = {}) => around ? `<div class="tw"><table class="tab"><tr><th>#</th><th>Equipo</th><th>PJ</th><th>Dif</th><th>Pts</th><th class="fh">Últimos 5</th></tr>${near(T, around, 1).map(({ x, i }) => `<tr${around.some((t) => same(t, x.team)) ? ' class="me"' : ''}><td>${i + 1}</td><td class="tm">${crest(x.team, 20)}${teamLink(x.team)}</td><td>${x.pj}</td><td>${x.dif > 0 ? '+' : ''}${x.dif}</td><td><b>${x.pts}</b></td><td class="fh">${formHtml(x.form)}</td></tr>`).join('')}</table></div>` : `<div class="tw"><table class="tab"><tr><th>#</th><th>Equipo</th><th>PJ</th><th>G</th><th>E</th><th>P</th><th>GF</th><th>GC</th><th>Dif</th><th>Pts</th><th class="fh">Últimos 5</th></tr>
${(top ? T.slice(0, top) : T).map((x, i) => `<tr${mark.some((t) => same(t, x.team)) ? ' class="me"' : ''}><td>${i + 1}</td><td class="tm">${crest(x.team, 20)}${teamLink(x.team)}</td><td>${x.pj}</td><td>${x.g}</td><td>${x.e}</td><td>${x.p}</td><td>${x.gf}</td><td>${x.gc}</td><td>${x.dif > 0 ? '+' : ''}${x.dif}</td><td><b>${x.pts}</b></td><td class="fh">${formHtml(x.form)}</td></tr>`).join('')}</table></div>`;
const tableNote = () => `<div class="disc">Tabla calculada con los resultados publicados por 1xBet desde el inicio del ${TORNEO.name}.${C.tableNote ? ' ' + esc(C.tableNote) : ''} Puede diferir de la tabla oficial de ${esc(C.ligaOrg || C.ligaLong)} (formato del torneo, partidos pendientes o sanciones). PJ jugados · G ganados · E empatados · P perdidos · GF goles a favor · GC goles en contra.</div>`;
const resRow = (r) => `<div class="rr"><span class="rd">${r.start * 1000 < NOW - 150 * 864e5 ? dyear(r.start) : day(r.start)}</span><span class="rt">${isPair(r.home, r.away) ? `<a href="${purl(r.home, r.away)}">` : ''}${crest(r.home, 18)}${esc(r.home)} <b>${r.score[0]}–${r.score[1]}</b> ${esc(r.away)}${crest(r.away, 18)}${isPair(r.home, r.away) ? '</a>' : ''}</span></div>`;
const resList = (rs) => (rs.length ? `<div class="rl">${rs.map(resRow).join('')}</div>` : '');
function probs(m) { const o = ['1', 'X', '2'].map((k) => m.odds && m.odds[k]); if (o.some((x) => !x)) return null; const inv = o.map((x) => 1 / x), s = inv.reduce((a, b) => a + b, 0), p = inv.map((x) => x / s); return { p, fav: p.indexOf(Math.max(...p)), margin: (s - 1) * 100 }; }
const oddsRow = (m) => { const r = probs(m); return `<div class="odds">${['1', 'X', '2'].map((k, i) => { const cls = r && r.fav === i ? 'fav' : '', inner = `<i>${k}</i>${m.odds[k] ? m.odds[k].toFixed(2) : '–'}`, L = clink(m, k); return L ? `<a class="${cls}" href="${esc(L)}" ${AFF} title="Abre 1xBet con esta apuesta en tu cupón">${inner}</a>` : `<span class="${cls}">${inner}</span>`; }).join('')}</div>`; };
const probTxt = (r) => `Probabilidad según las cuotas: ${['1', 'X', '2'].map((k, i) => `${k}: ${Math.round(r.p[i] * 100)} %`).join(' · ')}`;
function card(m, link = true) {
  const r = probs(m);
  return `<div class="m" data-k="${esc(m.rk || '')}" data-t="${m.start}"><div class="t"><span class="tb tbs" data-t="${m.start}"></span>${esc(m.tournament || m.gname)} · ${tm(m.start)}</div>
<div class="n">${link ? `<a href="${murl(m)}">${crest(m.home)}${esc(m.home)} <em>vs</em> ${crest(m.away)}${esc(m.away)}</a>` : `${crest(m.home)}${teamLink(m.home)} <em>vs</em> ${crest(m.away)}${teamLink(m.away)}`}</div>${IS_ROOT || CUPS.has(m.group) || INTL.has(m.group) ? zonesHtml(m.start) : ''}${oddsRow(m)}
${r ? `<div class="p">${probTxt(r)}</div>` : ''}</div>`;
}
const noMatches = '<div class="disc">Por ahora no hay partidos con cuotas publicadas. Las cuotas se actualizan cada 3 horas.</div>';
const list = (ms) => (ms.length ? `<div class="ms">${ms.map((m) => card(m)).join('')}</div>` : noMatches);
const todayBox = (who, next, last) => `<div class="today">${next ? `<div class="tn"><span class="tb" data-t="${next.start}">Próximo partido</span><b><a href="${murl(next)}">${esc(next.home)} vs ${esc(next.away)}</a></b><span class="small">${esc(next.tournament || next.gname)} · ${tm(next.start)}</span><span class="cd" data-u="${next.start}"></span></div>` : `<div class="tn"><span class="tb">Próximo partido</span><b>Todavía sin fecha publicada</b><span class="small">Aún no hay cuotas para el próximo partido de ${esc(who)}. La página se actualiza cada 3 horas.</span></div>`}${last ? `<div class="tl"><span class="tb tb2">Último resultado</span>${resRow(last)}</div>` : ''}</div>`;
const TODAY_JS = `<script>(function(){var f=new Intl.DateTimeFormat('en-CA',{timeZone:'${TZ}',year:'numeric',month:'2-digit',day:'2-digit'}),d=function(t){return Math.round(new Date(f.format(t)+'T00:00:00Z')/864e5)},dur=function(ms){var m=Math.round(ms/6e4),h=Math.floor(m/60),j=Math.floor(h/24);return j>=1?j+' d '+(h%24)+' h':h>=1?h+' h '+String(m%60).padStart(2,'0'):m+' min'};
function tick(){var n=Date.now();document.querySelectorAll('.tb[data-t]').forEach(function(e){var t=+e.dataset.t*1000,k=d(t)-d(n);e.classList.remove('hot');if(t<n-3*36e5)return;if(t<=n){e.textContent='En vivo';e.classList.add('hot')}else if(t-n<6*36e5){e.textContent='En '+dur(t-n);e.classList.add('hot')}else if(k===0){e.textContent='Hoy';e.classList.add('hot')}else if(k===1)e.textContent='Mañana'});
document.querySelectorAll('.cd[data-u]').forEach(function(e){var t=+e.dataset.u*1000;e.textContent=t>n?'Empieza en '+dur(t-n):t>n-2*36e5?'Partido en juego':'Partido terminado'})}
tick();setInterval(tick,30000)})();</script>`;
const LIVE_JS = `<script>(function(){var E=[].slice.call(document.querySelectorAll('[data-k][data-t]'));if(!E.length)return;var on=function(){var n=Date.now()/1000;return E.filter(function(e){var t=+e.dataset.t;return n>t-600&&n<t+3*3600})};if(!on().length)return;
function upd(d){var M={};(d.m||[]).forEach(function(x){M[x.k]=x;var r=x.k.split('|');M[r[1]+'|'+r[0]]={s:[x.s[1],x.s[0]],min:x.min,p:x.p,rev:1}});on().forEach(function(e){var x=M[e.dataset.k];var b=e.querySelector('.lvb');if(!x){if(b)b.remove();return}if(!b){b=document.createElement('div');b.className='lvb';e.insertBefore(b,e.classList.contains('lvs')?null:e.children[1]||null)}b.innerHTML='<i></i>EN VIVO <b>'+x.s[0]+'–'+x.s[1]+'</b>'+(x.min!=null?' · '+x.min+"'":'')+(x.p?' · '+x.p:'')})}
function go(){fetch('/api/live',{cache:'no-store'}).then(function(r){return r.json()}).then(upd).catch(function(){})}go();setInterval(go,60000)})();</script>`;
const SEARCH_JS = `<script>(function(){var b=document.getElementById('sbtn'),P=document.getElementById('spanel'),q=document.getElementById('sq'),R=document.getElementById('sres'),I=null,n=function(x){return x.normalize('NFD').replace(/[\\u0300-\\u036f]/g,'').toLowerCase()};
function load(){if(I)return;I=[];fetch('/futbol/search.json').then(function(r){return r.json()}).then(function(d){I=d.map(function(e){return {l:e[0],u:e[1],k:e[2],n:n(e[0]+' '+(e[3]||''))}});show()}).catch(function(){})}
function show(){var v=n(q.value.trim());if(!v){R.innerHTML='';return}var w=v.split(/\\s+/),r=I.filter(function(e){return w.every(function(x){return e.n.indexOf(x)>=0})}).slice(0,8);var h=function(x){return String(x).replace(/[&<>"]/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]})};R.innerHTML=r.length?r.map(function(e){return '<a href="'+h(e.u)+'"><b>'+h(e.l)+'</b><span>'+h(e.k)+'</span></a>'}).join(''):'<p>Sin resultados.</p>'}
b.addEventListener('click',function(){P.hidden=!P.hidden;if(!P.hidden){load();q.focus()}});q.addEventListener('input',show);document.addEventListener('keydown',function(e){if(e.key==='Escape')P.hidden=true})})();</script>`;
const CALC_JS = `<script>(function(){var c=document.querySelector('.mcalc');if(!c)return;var o=c.dataset.o.split(',').map(Number),i=c.querySelector('input'),f=function(){var m=+i.value||0;c.querySelectorAll('b[data-i]').forEach(function(b){b.textContent='${C.cur || ''} '+(m*o[+b.dataset.i]).toLocaleString('${C.loc}',{maximumFractionDigits:2})})};i.addEventListener('input',f);f()})();</script>`;

// ---------- oferta 1xBet (sin cifras: las condiciones de cada país están en la reseña de GoClarivo y en 1xBet) ----------
const codebox = () => `<div class="codebox"><div><span class="small">Código promocional 1xBet</span><br><b>${CODE ? esc(CODE) : 'POR CONFIRMAR'}</b></div>${CODE ? `<button onclick="navigator.clipboard&&navigator.clipboard.writeText('${esc(CODE)}');this.textContent='Copiado'">Copiar</button>` : ''}</div>`;
const REVIEW = IS_ROOT ? null : C.review === false ? null : `~/${C.key}/resenas/1xbet/`;
const offerBox = () => (NOAFF || !X.link ? '' : `<div class="offer"><div class="k">1xBet${IS_ROOT ? '' : ' ' + esc(C.name)} · cuentas nuevas</div><div class="big">Bono de bienvenida con el código ${esc(CODE)}</div><p class="small">El monto, el rollover y el depósito mínimo cambian según el país${REVIEW ? `: los tienes en nuestra <a href="${REVIEW}">reseña de 1xBet ${esc(C.name)}</a>` : ''}. Revisa siempre las condiciones vigentes en 1xBet antes de depositar.</p>${codebox()}${go('Registrarse en 1xBet', 'cta', 'oferta')}<p class="small mt">Solo mayores de 18 años. Enlace de afiliado: si te registras, GoClarivo puede recibir una comisión.</p></div>`);

// ---------- plantilla ----------
const TOPC = C.topc;
// Enlaces internos: «/x/» → /<geo>/futbol/x/ (o /futbol/x/ en las páginas comunes); «~/x/» → /x/ (resto de GoClarivo, sin tocar).
const ROOTP = ['/en-vivo/', '/calculadora-apuestas-combinadas/', '/copa-libertadores/', '/copa-sudamericana/', '/champions-league/', '/laliga/', '/premier-league/', '/real-madrid/', '/barcelona/', '/assets/', '/search.json'];
const isRootP = (h) => ROOTP.some((r) => h === r || h.startsWith(r));
const done = (h) => /^\/(futbol|[a-z]{2}\/futbol)(\/|$)/.test(h) || h.startsWith('/api/');
const P = (h) => (!h.startsWith('/') || h.startsWith('//') || done(h) ? h : (IS_ROOT || isRootP(h) ? '/futbol' : PREFIX) + h);
const fixHref = (html) => html.replace(/(href|data-u|action)="\/(?!\/)([^"]*)"/g, (m, a, rest) => `${a}="${P('/' + rest)}"`).replace(/(href)="~\//g, '$1="/');
const CNAV = CK.map((k) => [`/${k}/futbol/`, COUNTRIES[k].name]);
const NAV = IS_ROOT
  ? [['/', 'Internacional'], ['/en-vivo/', 'En vivo'], ['/copa-libertadores/', 'Libertadores'], ['/copa-sudamericana/', 'Sudamericana'], ['/champions-league/', 'Champions'], ['/laliga/', 'LaLiga'], ['/premier-league/', 'Premier'], ['/real-madrid/', 'Real Madrid'], ['/barcelona/', 'Barcelona']]
  : [['/', C.liga], ['/partidos-de-hoy/', 'Partidos de hoy'], ['/posiciones/', 'Posiciones'], ['/fixture/', 'Fixture'], ['/resultados/', 'Resultados'], ['/equipos/', 'Equipos'], [SELU, 'Selección'], ['/pronostico-de-hoy/', 'Pronóstico'], ['/en-vivo/', 'En vivo']];
const INTLNAV = [['/copa-libertadores/', 'Copa Libertadores'], ['/copa-sudamericana/', 'Copa Sudamericana'], ['/champions-league/', 'Champions League'], ['/laliga/', 'LaLiga'], ['/premier-league/', 'Premier League'], ['/real-madrid/', 'Real Madrid'], ['/barcelona/', 'Barcelona']];
const GCLINKS = IS_ROOT ? [['~/', 'Inicio de GoClarivo']] : [[`~/${C.key}/`, `GoClarivo ${C.name}`], [`~/${C.key}/sports/`, 'Apuestas deportivas'], ...(REVIEW ? [[REVIEW, 'Reseña de 1xBet']] : []), [`~/${C.key}/responsible-gambling/`, 'Juego responsable']];
const MGROUPS = [['Fútbol por país', [['/futbol/', 'Internacional'], ...CNAV]], ...(IS_ROOT ? [] : [[C.ligaLong, [...NAV.slice(0, 8)]], ['Equipos', CLUBS.map((k) => [curl(k.name), k.name])]]), ['Copas y ligas', [['/en-vivo/', 'En vivo'], ...INTLNAV, ['/calculadora-apuestas-combinadas/', 'Calculadora de combinadas']]], ['GoClarivo', GCLINKS]];
const TOK = { LIGA: C.ligaLong, ORG: C.ligaOrg || C.ligaLong, DE: C.de, NICK: C.nationNick || '', ADJ: C.adj, ADJS: (C.adj || '').replace(/o$/, 'os').replace(/e$/, 'es'), PAIS: C.name, NATION: C.nation || C.name, MONEY: C.money || 'tu moneda', CUR: C.cur || '$', UTC: C.utc, SELU: P(SELU), GEO: C.key, DELIGA: C.deLiga || 'de la ' + C.ligaLong, HORA: C.hora || C.de, PAISES: 'Argentina, México, Chile, Perú, Ecuador, Bolivia, Paraguay y España' };
const tok = (x) => String(x).replace(/⟦([A-Z]+)⟧/g, (m, k) => (k in TOK ? TOK[k] : m));
const sitemap = [], SEARCH = [];
const FLAGS_SVG = fs.readFileSync(path.join(__dirname, 'assets', 'flags.svg'), 'utf8');
const SHIELD = '<svg viewBox="0 0 24 24" width="26" height="26" aria-hidden="true"><path d="M12 2.2 L20.5 5.4 V11 C20.5 16.3 17 19.9 12 21.6 C7 19.9 3.5 16.3 3.5 11 V5.4 Z" fill="#5ee7c4"/><path d="M7.8 11.9 L10.6 14.7 L16.3 8.6" fill="none" stroke="#080b12" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
function page(p, { title, desc, body, crumb, parent = null, noindex = false, ld = [], og = null }) {
  p = P(p); if (parent) parent = [P(parent[0]), parent[1]];
  const url = BASE + p, idx = site.indexable && !noindex;
  if (!noindex) sitemap.push(url);
  const graph = [{ '@type': 'WebSite', name: site.name, url: BASE + '/', inLanguage: C.loc }, ...ld];
  const home = PREFIX + '/';
  if (crumb || p !== home) { const it = [['GoClarivo', BASE + '/'], ...(!IS_ROOT ? [[C.name, `${BASE}/${C.key}/`]] : []), ['Fútbol', BASE + home], ...(parent ? [[parent[1], BASE + parent[0]]] : []), ...(crumb ? [[crumb, url]] : [])]; graph.push({ '@type': 'BreadcrumbList', itemListElement: it.map(([n, u], k) => ({ '@type': 'ListItem', position: k + 1, name: n, item: u })) }); }
  const html = `<!doctype html>
<html lang="${C.loc}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="theme-color" content="#080b12">
<link rel="preload" href="/futbol/assets/fonts/sora-latin-800-normal.woff2" as="font" type="font/woff2" crossorigin><link rel="preload" href="/futbol/assets/fonts/manrope-latin-400-normal.woff2" as="font" type="font/woff2" crossorigin>
<title>${esc(title)}</title><meta name="description" content="${esc(desc)}">
<link rel="canonical" href="${url}">${idx ? '\n<meta name="robots" content="index, follow, max-image-preview:large">' : '\n<meta name="robots" content="noindex,nofollow">'}
<link rel="stylesheet" href="/futbol/assets/style.css?v=${CSSV}"><link rel="icon" href="~/favicon.svg" type="image/svg+xml"><link rel="icon" href="~/favicon.ico" sizes="any"><link rel="apple-touch-icon" href="~/apple-touch-icon.png"><link rel="manifest" href="~/site.webmanifest">
<meta property="og:type" content="website"><meta property="og:locale" content="${C.loc.replace('-', '_')}"><meta property="og:site_name" content="${esc(site.name)}">
<meta property="og:title" content="${esc(title)}"><meta property="og:description" content="${esc(desc)}"><meta property="og:url" content="${url}">
<meta property="og:image" content="${BASE}${og || '/assets/og-image.png'}"><meta property="og:image:width" content="1200"><meta property="og:image:height" content="630"><meta name="twitter:card" content="summary_large_image">
<script type="application/ld+json">${JSON.stringify({ '@context': 'https://schema.org', '@graph': graph }).replace(/</g, '\\u003c')}</script>
</head><body>
${FLAGS_SVG}<header class="gch" id="gh"><div class="hw"><div class="r1"><a class="brand" href="~/${IS_ROOT ? '' : C.key + '/'}">${SHIELD}<span>Go<b>Clarivo</b></span></a><span class="sec">Fútbol</span><span class="sp"></span>${IS_ROOT ? '' : `<a class="hl" href="~/${C.key}/sports/">Apuestas deportivas</a>`}<span class="age" title="Solo mayores de 18 años">18+</span>${go('Registrarse', 'hcta', 'cabecera')}
<button class="sbtn" id="sbtn" type="button" aria-label="Buscar un equipo"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><circle cx="10.5" cy="10.5" r="6.5"/><path d="M15.5 15.5 21 21"/></svg></button>
<details class="mnav"><summary aria-label="Menú"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="4" y1="7" x2="20" y2="7"/><line x1="4" y1="12" x2="20" y2="12"/><line x1="4" y1="17" x2="20" y2="17"/></svg></summary><div class="mp">${MGROUPS.map(([g, items]) => `<div class="mg"><b>${esc(g)}</b>${items.map(([h, t]) => `<a href="${h}"${P(h) === p ? ' class="on"' : ''}>${esc(t)}</a>`).join('')}</div>`).join('')}</div></details></div>
<div class="geo"><a href="/futbol/"${IS_ROOT ? ' class="on"' : ''}><svg><use href="#flag-int"/></svg>Internacional</a>${CK.map((k) => `<a href="/${k}/futbol/"${k === RG ? ' class="on"' : ''}><svg><use href="#flag-${k}"/></svg>${esc(COUNTRIES[k].name)}</a>`).join('')}</div>
<nav class="tabs">${NAV.map(([h, t]) => `<a href="${h}"${P(h) === p ? ' class="on"' : ''}>${esc(t)}</a>`).join('')}</nav></div>
<div class="spanel" id="spanel" hidden><div class="hw"><input id="sq" type="search" placeholder="Equipo o partido (ej. ${esc(IS_ROOT ? 'Real Madrid' : (C.topc && C.topc[0]) || 'equipo')})" autocomplete="off" aria-label="Buscar"><div id="sres" class="sres"></div></div></div></header>
<script>document.querySelectorAll('#gh details').forEach(function(d){document.addEventListener('click',function(e){if(d.open&&!d.contains(e.target))d.removeAttribute('open')})})</script>
<main class="wrap">${crumb ? `<p class="crumb"><a href="~/${IS_ROOT ? '' : C.key + '/'}">GoClarivo${IS_ROOT ? '' : ' ' + esc(C.name)}</a> › <a href="/">Fútbol</a> › ${parent ? `<a href="${parent[0]}">${esc(parent[1])}</a> › ` : ''}${esc(crumb)}</p>` : ''}
${body}
</main>${TODAY_JS}${CALC_JS}${SEARCH_JS}${LIVE_JS}
<footer class="gcf"><div class="wrap"><b style="color:var(--ink);font:800 17px 'Sora',sans-serif">Go<span style="color:var(--acc)">Clarivo</span> · Fútbol</b>
<nav>${NAV.map(([h, t]) => `<a href="${h}">${esc(t)}</a>`).join('')}</nav>
<nav><a href="/futbol/">Fútbol internacional</a>${CNAV.map(([h, t]) => `<a href="${h}">Fútbol de ${esc(t)}</a>`).join('')}</nav>
${CLUBS.length ? `<nav>${CLUBS.map((k) => `<a href="${curl(k.name)}">${esc(k.name)}</a>`).join('')}</nav>` : ''}
<nav>${GCLINKS.map(([h, t]) => `<a href="${h}">${esc(t)}</a>`).join('')}</nav>
<p>GoClarivo es un sitio independiente. No somos 1xBet ni una liga o federación: los partidos, las cuotas y los resultados salen de 1xBet y pueden cambiar o diferir de los datos oficiales. ${NOAFF ? '' : 'Algunos enlaces son de afiliado. '}Solo mayores de 18 años. Las apuestas implican riesgo: juega con moderación.</p></div></footer>
</body></html>`;
  const f = path.join(OUT, p, 'index.html');
  fs.mkdirSync(path.dirname(f), { recursive: true });
  fs.writeFileSync(f, fixHref(tok(html)));
}
const faqLd = (faq) => (faq && faq.length ? [{ '@type': 'FAQPage', mainEntity: faq.map(([q, a]) => ({ '@type': 'Question', name: q, acceptedAnswer: { '@type': 'Answer', text: a } })) }] : []);
const faqHtml = (faq) => (faq && faq.length ? `<h2>Preguntas frecuentes</h2>${faq.map(([q, a]) => `<details><summary>${esc(q)}</summary><p>${esc(a)}</p></details>`).join('')}` : '');
const upd = () => `<p class="upd">Revisado el ${updated}</p>`;
const evLd = (m) => ({ '@type': 'SportsEvent', name: `${m.home} vs ${m.away}`, startDate: new Date(m.start * 1000).toISOString(), sport: 'Soccer', location: { '@type': 'Place', name: C.name }, homeTeam: { '@type': 'SportsTeam', name: m.home }, awayTeam: { '@type': 'SportsTeam', name: m.away } });

// ---------- bloques de partido ----------
const fmt = (x) => x.toFixed(2);
function marketsHtml(m) {
  const k = m.markets; if (!k) return '';
  const row = (t, items) => `<div class="mk"><b>${t}</b><div class="odds">${items.map(([l, v]) => `<span><i>${l}</i>${fmt(v)}</span>`).join('')}</div></div>`;
  return `<h2>Otras cuotas de 1xBet</h2>${k.dc ? row('Doble oportunidad', [['1X', k.dc['1X']], ['12', k.dc['12']], ['X2', k.dc.X2]]) : ''}${k.ou25 ? row('Total de goles 2.5', [['Más', k.ou25.o], ['Menos', k.ou25.u]]) : ''}${k.btts ? row('Ambos anotan', [['Sí', k.btts.y], ['No', k.btts.n]]) : ''}<p class="small">Cuotas de 1xBet en el momento de la última actualización. Pueden cambiar antes del partido.</p>`;
}
// Historial: resultados guardados + estadísticas de 1xBet (h2h) sin duplicados.
function history(a, b, m) {
  const gt = !m || !INTL.has(m.group), cn = gt ? canon : strip;
  const out = {}, add = (d, h, aw, s) => { h = cn(h); aw = cn(aw); const k = Object.keys(out).find((q) => { const o = out[q]; return same(o.h, h) && same(o.a, aw) && Math.abs(o.d - d) < 2 * 86400; }); if (!k) out[d + slug(h) + slug(aw)] = { d, h, a: aw, s }; };
  for (const r of RES) if ((same(r.home, a) && same(r.away, b)) || (same(r.home, b) && same(r.away, a))) add(r.start, r.home, r.away, r.score);
  if (m && m.stats && m.stats.h2h) for (const x of m.stats.h2h) add(x.d, x.h, x.a, x.s);
  return Object.values(out).sort((p, q) => q.d - p.d).slice(0, 10);
}
function h2hHtml(a, b, H) {
  if (!H.length) return `<h2>Historial de ${esc(a)} vs ${esc(b)}</h2><div class="disc">Todavía no hay enfrentamientos recientes en nuestros datos.</div>`;
  let wa = 0, wb = 0, e = 0, g = 0, bt = 0;
  for (const x of H) { const [sa, sb] = same(x.h, a) ? x.s : [x.s[1], x.s[0]]; sa > sb ? wa++ : sa < sb ? wb++ : e++; g += sa + sb; if (sa && sb) bt++; }
  const n = H.length;
  return `<h2>Historial de ${esc(a)} vs ${esc(b)}</h2><p>En los últimos ${n} enfrentamientos: ${wa} victoria${wa === 1 ? '' : 's'} de ${esc(a)}, ${e} empate${e === 1 ? '' : 's'} y ${wb} victoria${wb === 1 ? '' : 's'} de ${esc(b)}. Promedio de ${(g / n).toFixed(1)} goles por partido; ambos anotaron en ${bt} de ${n}.</p><div class="rl">${H.map((x) => `<div class="rr"><span class="rd">${dyear(x.d)}</span><span class="rt">${esc(x.h)} <b>${x.s[0]}–${x.s[1]}</b> ${esc(x.a)}</span></div>`).join('')}</div><p class="small">Fuente: resultados y estadísticas de 1xBet.</p>`;
}
function formBlock(teams, m) {
  const A = [m && m.stats && m.stats.f1, m && m.stats && m.stats.f2];
  const F = teams.map((t, i) => { const l = lastOf(t, 5).map((r) => { const h = same(r.home, t), gf = h ? r.score[0] : r.score[1], ga = h ? r.score[1] : r.score[0]; return { v: gf > ga ? 'G' : gf === ga ? 'E' : 'P', gf, ga, o: h ? r.away : r.home }; }); return { t, l: l.length ? l : (A[i] || []).map((x) => ({ v: x.gf > x.ga ? 'G' : x.gf === x.ga ? 'E' : 'P', gf: x.gf, ga: x.ga, o: (m && INTL.has(m.group) ? strip : canon)(x.o) })) }; });
  if (!F.some((x) => x.l.length)) return '';
  return `<h2>Forma: últimos 5 partidos</h2><div class="formc">${F.map((x) => { const c = { G: 0, E: 0, P: 0 }; x.l.forEach((y) => c[y.v]++); return `<div><h3>${teamLink(x.t)}</h3>${x.l.length ? `<ol class="fsq">${x.l.map((y) => `<li class="f${{ G: 'V', E: 'N', P: 'D' }[y.v]}"><b>${y.v}</b><span>${y.gf}–${y.ga}</span><small>${esc(y.o)}</small></li>`).join('')}</ol><p class="small">${c.G} ganado${c.G === 1 ? '' : 's'}, ${c.E} empate${c.E === 1 ? '' : 's'}, ${c.P} perdido${c.P === 1 ? '' : 's'} (del más reciente al más antiguo)</p>` : '<p class="small">Sin resultados recientes.</p>'}</div>`; }).join('')}</div>`;
}
const calcHtml = (m) => `<h2>Calcula tu ganancia</h2><div class="calc mcalc" data-o="${['1', 'X', '2'].map((k) => m.odds[k]).join(',')}"><label for="mise">Tu apuesta${C.money ? ` (${C.money})` : ''}</label><input id="mise" type="number" inputmode="decimal" value="50" min="1" step="1"><div class="r3">${['1', 'X', '2'].map((k, i) => `<div><span class="small">${esc(i === 0 ? m.home : i === 1 ? 'Empate' : m.away)} · ${fmt(m.odds[k])}</span><b data-i="${i}">–</b></div>`).join('')}</div><p class="small mt">Pago total si la apuesta gana (incluye lo apostado), con las cuotas mostradas.</p></div>`;
const verdictOf = (m) => { const r = probs(m); if (!r) return ''; const names = [m.home, 'el empate', m.away]; return r.fav === 1 ? `Las cuotas ven el empate como el resultado más probable (${Math.round(r.p[1] * 100)} %).` : `${names[r.fav]} llega como favorito: ${Math.round(r.p[r.fav] * 100)} % según las cuotas.`; };
const posLine = (t) => { const ps = posOf(t); return ps ? `${esc(t)}: ${ps.pos}.º con ${ps.pts} pts en ${ps.pj} partidos` : ''; };


// Temporada en números (datos propios de cada club → texto único por página)
function seasonTxt(n) {
  const rs = CUR.filter(plays(n)).sort((a, b) => a.start - b.start); if (rs.length < 3) return '';
  const rec = (arr) => { const c = { G: 0, E: 0, P: 0 }; for (const r of arr) { const h = same(r.home, n), gf = h ? r.score[0] : r.score[1], ga = h ? r.score[1] : r.score[0]; c[gf > ga ? 'G' : gf === ga ? 'E' : 'P']++; } return c; };
  const home = rs.filter((r) => same(r.home, n)), away = rs.filter((r) => same(r.away, n)), H = rec(home), A = rec(away);
  let gf = 0, ga = 0, best = null, worst = null, cs = 0;
  for (const r of rs) { const h = same(r.home, n), f = h ? r.score[0] : r.score[1], c = h ? r.score[1] : r.score[0]; gf += f; ga += c; if (!c) cs++; if (!best || f - c > best.d) best = { d: f - c, r }; if (!worst || f - c < worst.d) worst = { d: f - c, r }; }
  const seq = rs.map((r) => { const h = same(r.home, n), f = h ? r.score[0] : r.score[1], c = h ? r.score[1] : r.score[0]; return f > c ? 'G' : f === c ? 'E' : 'P'; }).reverse();
  let k = 0; while (k < seq.length && seq[k] === seq[0]) k++;
  const streak = { G: `${k} victoria${k > 1 ? 's' : ''} seguida${k > 1 ? 's' : ''}`, E: `${k} empate${k > 1 ? 's' : ''} seguido${k > 1 ? 's' : ''}`, P: `${k} derrota${k > 1 ? 's' : ''} seguida${k > 1 ? 's' : ''}` }[seq[0]];
  const sc = (r) => `${r.home} ${r.score[0]}-${r.score[1]} ${r.away}`;
  return `<h2>${esc(n)} en el ${esc(TORNEO.name)}, en números</h2><ul class="prose"><li>En casa: ${H.G} ganados, ${H.E} empates y ${H.P} perdidos (${home.length} partidos).</li><li>De visita: ${A.G} ganados, ${A.E} empates y ${A.P} perdidos (${away.length} partidos).</li><li>${(gf / rs.length).toFixed(2)} goles a favor y ${(ga / rs.length).toFixed(2)} en contra por partido; ${cs} partido${cs === 1 ? '' : 's'} sin recibir gol.</li>${best && best.d > 0 ? `<li>Mejor resultado: ${esc(sc(best.r))} (${day(best.r.start)}).</li>` : ''}${worst && worst.d < 0 ? `<li>Peor resultado: ${esc(sc(worst.r))} (${day(worst.r.start)}).</li>` : ''}<li>Racha actual: ${streak}.</li></ul>`;
}
// Enfrentamiento en números: local/visita y últimos triunfos de cada uno
function pairTxt(a, b, H) {
  if (H.length < 2) return '';
  const lastWin = (t) => H.find((x) => { const [p, q] = same(x.h, t) ? x.s : [x.s[1], x.s[0]]; return p > q; });
  const big = H.reduce((m, x) => (Math.abs(x.s[0] - x.s[1]) > Math.abs(m.s[0] - m.s[1]) ? x : m), H[0]);
  const goals = H.map((x) => x.s[0] + x.s[1]), o25 = goals.filter((g) => g > 2).length;
  const li = [a, b].map((t) => { const w = lastWin(t); return `<li>Última victoria de ${esc(t)}: ${w ? `${esc(w.h)} ${w.s[0]}-${w.s[1]} ${esc(w.a)} (${dyear(w.d)})` : 'ninguna en estos partidos'}.</li>`; }).join('');
  return `<h2>El enfrentamiento en números</h2><ul class="prose">${li}<li>Resultado más amplio: ${esc(big.h)} ${big.s[0]}-${big.s[1]} ${esc(big.a)} (${dyear(big.d)}).</li><li>Más de 2.5 goles en ${o25} de ${H.length} partidos.</li></ul>`;
}


// Previa de cada partido de liga: 3–4 párrafos armados solo con nuestros datos (tabla, forma, casa/visita, historial, goles, cuotas).
const hsh = (x) => { let h = 0; for (const c of String(x)) h = (h * 31 + c.charCodeAt(0)) >>> 0; return h; };
const pickT = (seed, arr) => arr[hsh(seed) % arr.length];
function recOf(n, f) { const rs = CUR.filter(f); const c = { G: 0, E: 0, P: 0, gf: 0, gc: 0, n: rs.length, btts: 0, o25: 0 }; for (const r of rs) { const h = same(r.home, n), a = h ? r.score[0] : r.score[1], b = h ? r.score[1] : r.score[0]; c[a > b ? 'G' : a === b ? 'E' : 'P']++; c.gf += a; c.gc += b; if (a && b) c.btts++; if (a + b > 2) c.o25++; } return c; }
function previaHtml(m, H) {
  if (m.group !== 'liga' || !TABLE.length) return '';
  const h = m.home, a = m.away, ph = posOf(h), pa = posOf(a); if (!ph || !pa) return '';
  const seed = h + a + m.start, P = [];
  // 1) tabla y lo que está en juego
  const diff = Math.abs(ph.pts - pa.pts), up = ph.pts >= pa.pts ? [h, ph] : [a, pa], dn = ph.pts >= pa.pts ? [a, pa] : [h, ph];
  const rankIf = (t, add) => { const me = TABLE.find((x) => same(x.team, t)); return 1 + TABLE.filter((x) => !same(x.team, t) && (x.pts > me.pts + add || (x.pts === me.pts + add && x.dif > me.dif))).length; };
  const left = JORNADAS < 99 ? Math.max(0, JORNADAS - Math.max(ph.pj, pa.pj)) : 0;
  const rh = rankIf(h, 3), ra = rankIf(a, 3);
  P.push(`${pickT(seed + 1, [`Se enfrentan el ${ph.pos}.º y el ${pa.pos}.º del ${esc(TORNEO.name)}.`, `Duelo entre el ${ph.pos}.º (${esc(h)}) y el ${pa.pos}.º (${esc(a)}) de la tabla.`, `${esc(h)} llega ${ph.pos}.º y ${esc(a)} ${pa.pos}.º en la tabla del ${esc(TORNEO.name)}.`])} ${diff ? `${esc(up[0])} saca ${diff} punto${diff > 1 ? 's' : ''} de ventaja (${up[1].pts} contra ${dn[1].pts}).` : `Los dos suman ${ph.pts} puntos.`} ${rh < ph.pos ? `Con una victoria, ${esc(h)} llegaría a ${ph.pts + 3} puntos y podría subir hasta el ${rh}.º lugar.` : ''} ${ra < pa.pos ? `Si gana ${esc(a)}, sumaría ${pa.pts + 3} y podría escalar hasta el ${ra}.º.` : ''}${left ? ` ${left === 1 ? 'Es la última jornada' : `Quedan ${left} jornadas`} de la fase de clasificación antes de la liguilla.` : ''}`);
  // 2) local en casa / visitante fuera + forma
  const hc = recOf(h, (r) => same(r.home, h)), ac = recOf(a, (r) => same(r.away, a));
  const fs = (t) => { const p = posOf(t); return p ? p.form : []; }, fh = fs(h), fa = fs(a), w = (f) => f.filter((x) => x === 'G').length;
  P.push(`${hc.n ? `Como local, ${esc(h)} lleva ${hc.G} ganado${hc.G === 1 ? '' : 's'}, ${hc.E} empate${hc.E === 1 ? '' : 's'} y ${hc.P} perdido${hc.P === 1 ? '' : 's'} (${hc.gf} goles a favor y ${hc.gc} en contra).` : ''} ${ac.n ? `${esc(a)}, de visita, suma ${ac.G}-${ac.E}-${ac.P} (G-E-P) con ${ac.gf} goles anotados.` : ''} ${fh.length && fa.length ? pickT(seed + 2, [`En los últimos cinco partidos, ${esc(h)} ganó ${w(fh)} y ${esc(a)} ${w(fa)}.`, `Forma reciente: ${w(fh)} victorias de ${esc(h)} y ${w(fa)} de ${esc(a)} en sus últimos cinco juegos.`]) : ''}`);
  // 3) goles
  const gh = recOf(h, plays(h)), ga = recOf(a, plays(a)), avg = (c) => (c.n ? (c.gf + c.gc) / c.n : 0);
  if (gh.n && ga.n) P.push(`Los partidos de ${esc(h)} promedian ${avg(gh).toFixed(1)} goles y los de ${esc(a)} ${avg(ga).toFixed(1)}. Más de 2.5 goles hubo en ${gh.o25} de ${gh.n} juegos de ${esc(h)} y en ${ga.o25} de ${ga.n} de ${esc(a)}; ambos anotaron en ${gh.btts} y ${ga.btts} respectivamente.${m.markets && m.markets.ou25 ? ` En 1xBet, «más de 2.5» paga ${fmt(m.markets.ou25.o)} y «menos de 2.5», ${fmt(m.markets.ou25.u)}.` : ''}`);
  // 4) historial + cuotas
  const last = H[0];
  P.push(`${last ? `El último enfrentamiento terminó ${esc(last.h)} ${last.s[0]}-${last.s[1]} ${esc(last.a)} (${dyear(last.d)}).` : ''} ${pickT(seed + 3, ['Para saber qué dicen las cuotas, mira el pronóstico abajo.', 'Abajo, la lectura de las cuotas y la calculadora.', 'Más abajo: cuotas, historial completo y forma.'])} ${pickT(seed + 4, ['Es lo que dicen las cuotas, no un pronóstico seguro.', 'Las cuotas reflejan probabilidades, no certezas.', 'Ningún resultado está asegurado.'])}`);
  return `<h2>Previa: ${esc(h)} vs ${esc(a)}</h2>${P.map((x) => x.replace(/\s+/g, ' ').trim()).filter(Boolean).map((x) => `<p>${x}</p>`).join('')}`;
}

// Imagen del partido (scripts/match_images.py, generada en GitHub Actions): /assets/m/<start>-<local>--<visita>.jpg
const IMGDIR = path.join(__dirname, 'assets', 'm'), TLDIR = path.join(ROOT, 'assets', 't');
const mimg = (m) => { if (!m || !m.rk) return null; const f = `${m.start}-${m.rk.replace('|', '--')}.jpg`; return fs.existsSync(path.join(IMGDIR, f)) ? `/assets/m/${f}` : null; };

// ---------- build ----------
if (IS_ROOT) {
  const A = path.join(OUT, 'futbol', 'assets');
  fs.mkdirSync(A, { recursive: true });
  fs.copyFileSync(path.join(__dirname, 'assets', 'style.css'), path.join(A, 'style.css'));
  fs.cpSync(path.join(__dirname, 'assets', 'fonts'), path.join(A, 'fonts'), { recursive: true });
  if (fs.existsSync(TLDIR)) fs.cpSync(TLDIR, path.join(A, 't'), { recursive: true });
}

if (IS_ROOT) {
  // Portada /futbol/: cada país (líder y próximo partido de su liga) + copas y ligas europeas con la hora de cada país.
  const XALL = PIN.flatMap((x) => x.matches).sort((a, b) => a.start - b.start);
  const soonI = ALL.filter((m) => m.start * 1000 < NOW + 36 * 36e5);
  const soonC = XALL.filter((m) => m.group === 'liga' && m.start * 1000 < NOW + 36 * 36e5);
  const faq = [
    ['¿De qué países son los partidos?', 'Argentina (Liga Profesional), México (Liga MX), Chile, Perú (Liga 1), Ecuador (LigaPro), Bolivia, Paraguay y España (LaLiga), con sus selecciones, más la Copa Libertadores, la Copa Sudamericana, la Champions League y la Premier League.'],
    ['¿En qué hora están los partidos?', 'En la sección de cada país, en la hora de ese país. En las copas y ligas internacionales mostramos la hora de Argentina, Chile, Paraguay, Bolivia, Perú, Ecuador, México y España.'],
    ['¿Cada cuánto se actualiza?', 'Los partidos, las cuotas y los resultados, cada 3 horas. El marcador en vivo, cada minuto.'],
  ];
  page('/', {
    title: 'Fútbol hoy: partidos, en vivo, posiciones y hora en tu país (Libertadores, Champions y más)',
    desc: 'Partidos de hoy con la hora de Argentina, México, Chile, Perú, Ecuador, Bolivia, Paraguay y España: ligas locales, selecciones, Libertadores, Sudamericana, Champions, LaLiga y Premier. Marcador en vivo y tablas.',
    body: `<section class="hero"><div class="hero-t"><h1>Fútbol hoy: partidos, en vivo y posiciones</h1>
<p class="lead">Elige tu país para ver su liga con la hora local, la tabla de posiciones, los resultados y los equipos. Abajo, la Copa Libertadores, la Sudamericana y las ligas europeas con la hora de cada país.</p>
<ul class="chips"><li>Se actualiza cada 3 horas</li><li>Marcador en vivo</li><li>Hora de tu país</li></ul></div></section>
<div class="paises">${CK.map((k) => { const c = COUNTRIES[k], x = PIN.find((y) => y.k === k) || {}, nx = (x.matches || []).find((m) => m.group === 'liga'), ld = (x.lead || [])[0]; return `<a class="pais" href="/${k}/futbol/"><span class="pfl"><svg><use href="#flag-${k}"/></svg></span><b class="pn">${esc(c.name)}</b><span class="pl">${esc(c.ligaLong)}</span>${ld ? `<span class="pd">Líder: <b>${esc(ld.team)}</b>, ${ld.pts} pts</span>` : ''}${nx ? `<span class="pd">Próximo: ${esc(nx.home)} vs ${esc(nx.away)} · ${esc(day(nx.start))}</span>` : ''}<span class="go">Partidos, tabla y equipos →</span></a>`; }).join('')}</div>
<h2>Copas y ligas internacionales: hoy y mañana</h2>${list(soonI.slice(0, 12))}
<div class="chipl">${INTLNAV.map(([h, t]) => `<a href="${h}">${esc(t)}</a>`).join('')}</div>
${soonC.length ? `<h2>Ligas de cada país: hoy y mañana</h2>${list(soonC.slice(0, 12))}` : ''}
<a class="cta alt" href="/en-vivo/">Fútbol en vivo: marcador al minuto</a>
${offerBox()}
${faqHtml(faq)}${upd()}`,
    ld: faqLd(faq),
  });
}

if (!IS_ROOT) {
// Inicio = ⟦LIGA⟧ («⟦LIGA⟧» BO 64K/mes KD 0; «tabla de posiciones ⟦LIGA⟧» 4.6K KD 1)
{
  const lead = TABLE[0], nxt = LIGA[0];
  const faq = [
    ['¿Cuándo juega la ⟦LIGA⟧?', nxt ? `El próximo partido con cuotas publicadas es ${nxt.home} vs ${nxt.away}, ${when(nxt.start)}.` : 'Todavía no hay partidos con fecha y cuotas publicadas. La página se actualiza cada 3 horas.'],
    ...(lead ? [['¿Quién va primero en la tabla?', `${lead.team} lidera el ${TORNEO.name} con ${lead.pts} puntos en ${lead.pj} partidos, según los resultados publicados.`]] : []),
    ['¿A qué hora son los partidos?', 'Todas las horas de este sitio están en hora de ⟦PAIS⟧ (⟦UTC⟧).'],
  ];
  page('/', {
    title: `⟦LIGA⟧ ${TORNEO.y}: partidos de hoy, tabla de posiciones y resultados`,
    desc: `⟦LIGA⟧ ${TORNEO.y}: próximos partidos con hora de ⟦PAIS⟧ y cuotas, tabla de posiciones${lead ? ` (${lead.team} líder con ${lead.pts} pts)` : ''} y últimos resultados. Se actualiza cada 3 horas.`,
    body: `<section class="hero"><div class="hero-t"><h1>⟦LIGA⟧: partidos de hoy, tabla de posiciones y resultados</h1>
<p class="lead">${esc(TORNEO.name)} de la ⟦LIGA⟧: los próximos partidos con la hora de ⟦PAIS⟧ y las cuotas de 1xBet, la tabla de posiciones y los últimos resultados. Todo se actualiza cada 3 horas.</p>
<ul class="chips"><li>Se actualiza cada 3 horas</li><li>Hora de ⟦PAIS⟧</li><li>Sitio independiente</li></ul></div>
${offerBox()}</section>
<h2>Próximos partidos</h2>${list(LIGA.slice(0, 8))}<a class="cta alt" href="/partidos-de-hoy/">Ver todos los partidos y cuotas</a>
${TABLE.length ? `<h2>Tabla de posiciones ${esc(TORNEO.name)}</h2>${tableHtml(TABLE)}${tableNote()}` : ''}
${RLIGA.length ? `<h2>Últimos resultados</h2>${resList(RLIGA.slice(0, 10))}<p class="small"><a href="/resultados/">Todos los resultados →</a></p>` : ''}
${CLUBS.length ? `<h2>Equipos</h2><div class="chipl">${CLUBS.map((k) => `<a href="${curl(k.name)}">${esc(k.name)}</a>`).join('')}</div>` : ''}
<p class="small mt">Más de ⟦PAIS⟧ en GoClarivo: <a href="~/⟦GEO⟧/sports/">apuestas deportivas en ⟦PAIS⟧</a>${REVIEW ? ` · <a href="${REVIEW}">reseña de 1xBet</a>` : ''}. Torneos internacionales: <a href="/copa-libertadores/">Copa Libertadores</a> · <a href="/champions-league/">Champions League</a> · <a href="/en-vivo/">en vivo</a>.</p>
${faqHtml(faq)}${upd()}`,
    ld: [{ '@type': 'SportsOrganization', name: '⟦ORG⟧', alternateName: '⟦LIGA⟧', sport: 'Soccer' }, ...faqLd(faq)],
  });
}

// Partidos de hoy (todas las competiciones)
page('/partidos-de-hoy/', {
  title: 'Partidos de hoy en ⟦PAIS⟧: ⟦LIGA⟧, Selección y copas, hora y cuotas',
  desc: `Partidos de hoy y de los próximos días: ⟦LIGA⟧${ALL.some((m) => m.group === 'seleccion') ? ', Selección ⟦DE⟧' : ''} y copas internacionales, con hora de ⟦PAIS⟧ y cuotas de 1xBet.`,
  crumb: 'Partidos de hoy',
  body: `<h1>Partidos de hoy y próximos días</h1><p class="lead">Horas en hora de ⟦PAIS⟧. Toca un partido para ver el historial, la forma de los equipos y más cuotas.</p>
${Object.keys(GNAME).map((g) => { const ms = ALL.filter((m) => m.group === g); return ms.length ? `<h2>${GNAME[g]}</h2>${list(ms)}` : ''; }).join('') || noMatches}${upd()}`,
});

// Posiciones («tabla de posiciones ⟦LIGA⟧» 4.6K; «tabla acumulada ⟦LIGA⟧» 350 + 200, KD 0)
const POSFAQ = [
  ...(TABLE.length ? [['¿Quién va primero en la ⟦LIGA⟧?', `${TABLE[0].team}, con ${TABLE[0].pts} puntos en ${TABLE[0].pj} partidos.`]] : []),
  ['¿Cómo se calcula esta tabla?', `Nuestra tabla suma los partidos de liga del ${TORNEO.name} publicados por 1xBet (3 puntos por victoria, 1 por empate). Si ⟦ORG⟧ publica una tabla oficial con otro formato (grupos, bonificaciones o sanciones), puede haber diferencias.`],
];
page('/posiciones/', {
  title: `Posiciones ⟦DELIGA⟧ ${TORNEO.ys || TORNEO.y}: tabla general del ${TORNEO.name}`,
  desc: TABLE.length ? `Posiciones de la ⟦LIGA⟧, ${TORNEO.name}: ${TABLE[0].team} líder con ${TABLE[0].pts} pts. Puntos, goles y forma de todos los equipos.` : `Posiciones de la ⟦LIGA⟧, ${TORNEO.name}.`,
  crumb: 'Posiciones',
  body: `<h1>Tabla de posiciones de la ⟦LIGA⟧ ${esc(TORNEO.name)}</h1>
${TABLE.length ? `<p class="lead">${esc(TABLE[0].team)} va primero con ${TABLE[0].pts} puntos. Abajo, la tabla completa con los goles y los últimos 5 partidos de cada equipo.</p>${tableHtml(TABLE)}${tableNote()}` : '<div class="disc">Todavía no hay suficientes resultados del torneo para calcular la tabla.</div>'}
<h2>Próximos partidos</h2>${list(LIGA.slice(0, 6))}${faqHtml(POSFAQ)}${upd()}`,
  ld: faqLd(POSFAQ),
});

// Resultados
page('/resultados/', {
  title: `Resultados fútbol ⟦ADJ⟧ ${TORNEO.y}: cómo quedaron los partidos de la liga`,
  desc: `Resultados de la ⟦LIGA⟧, ${TORNEO.name}${RLIGA[0] ? `: último, ${RLIGA[0].home} ${RLIGA[0].score[0]}-${RLIGA[0].score[1]} ${RLIGA[0].away}` : ''}. Marcadores de todas las jornadas.`,
  crumb: 'Resultados',
  body: `<h1>Resultados de la ⟦LIGA⟧</h1><p class="lead">Cómo quedaron los partidos del ${esc(TORNEO.name)}, del más reciente al más antiguo.</p>
${CUR.length ? resList(CUR) : '<div class="disc">Todavía no hay resultados del torneo en nuestros datos.</div>'}
${RLIGA.filter((r) => r.start < TORNEO.from).length ? `<h2>Temporada anterior</h2>${resList(RLIGA.filter((r) => r.start < TORNEO.from).slice(0, 30))}` : ''}${upd()}`,
});

// Fixture («fixture ⟦LIGA⟧ 2026» 5.5K, «fixture ⟦LIGA⟧» 1.5K, «fixture de la ⟦LIGA⟧ 2026» 1.0K… Ahrefs BO 19.11.2026, KD 0–3): partidos por semana; jornada solo si los dos equipos coinciden
const pjBefore = (t, at) => CUR.filter((r) => r.start < at && plays(t)(r)).length;
const jornadaOf = (m) => { if (m.start < TORNEO.from) return null; const a = pjBefore(m.home, m.start) + 1, b = pjBefore(m.away, m.start) + 1; return a === b && a <= JORNADAS ? a : null; };
const weekKey = (t) => { const d = new Date((t - 6 * 3600) * 1000); const k = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate() - ((d.getUTCDay() + 6) % 7))); return k.getTime() / 1000 + 6 * 3600; };
{
  const nxtY = `temporada ${TORNEO.y + 1}`;
  const CALFAQ = [...(LIGA[0] ? [[`¿Cuándo es la próxima fecha de la ⟦LIGA⟧?`, `Los próximos partidos empiezan ${when(LIGA[0].start)} con ${LIGA[0].home} vs ${LIGA[0].away}.`]] : []), [`¿Cuándo empieza la ${nxtY}?`, `La fecha de inicio de la ${nxtY} está por confirmar. En cuanto se publiquen los primeros partidos con cuotas, aparecerán en este calendario.`], ...(LIGA[0] ? [['¿Cuál es el próximo partido?', `${LIGA[0].home} vs ${LIGA[0].away}, ${when(LIGA[0].start)}.`]] : [])];
  const items = [...CUR.map((r) => ({ t: r.start, r })), ...LIGA.map((m) => ({ t: m.start, m }))].sort((a, b) => b.t - a.t);
  const weeks = []; for (const it of items) { const k = weekKey(it.t); let w = weeks.find((x) => x.k === k); if (!w) weeks.push((w = { k, it: [] })); w.it.push(it); }
  const row = (it) => { const j = jornadaOf(it.r ? { home: it.r.home, away: it.r.away, start: it.r.start } : it.m); const x = it.r || it.m; const u = isPair(x.home, x.away) ? purl(x.home, x.away) : null; return `<div class="rr"><span class="rd">${day(it.t)}${it.m ? ` · ${hour(it.t)}` : ''}</span><span class="rt">${u ? `<a href="${u}">` : ''}${esc(x.home)} ${it.r ? `<b>${it.r.score[0]}–${it.r.score[1]}</b>` : '<em>vs</em>'} ${esc(x.away)}${u ? '</a>' : ''}${j ? ` <small class="small">J${j}</small>` : ''}</span></div>`; };
  page('/fixture/', {
    title: `Fixture ⟦LIGA⟧ ${TORNEO.y}: fechas, horarios y resultados`,
    desc: `Fixture de la ⟦LIGA⟧ ${TORNEO.y}: próximos partidos con fecha y hora de ⟦PAIS⟧${LIGA[0] ? ` (${LIGA[0].home} vs ${LIGA[0].away}, ${day(LIGA[0].start)})` : ''} y resultados de cada semana.`,
    crumb: 'Fixture',
    body: `<h1>Fixture de la ⟦LIGA⟧ ${TORNEO.y}</h1><p class="lead">El fixture (calendario) de la ⟦LIGA⟧: partidos semana por semana, del más reciente al más antiguo, con la hora de ⟦PAIS⟧. «J» es el número de fecha cuando ambos equipos llegan con la misma cantidad de partidos jugados (los partidos reprogramados pueden cambiarlo).</p>
${weeks.length ? weeks.map((w) => `<h2>Semana del ${esc(dshort(w.k))}</h2><div class="rl">${w.it.sort((a, b) => a.t - b.t).map(row).join('')}</div>`).join('') : noMatches}
<p class="small mt">Las fechas de partidos futuros aparecen en cuanto 1xBet publica las cuotas (normalmente con una semana de anticipación). <a href="/posiciones/">Tabla de posiciones</a> · <a href="/resultados/">Resultados</a></p>${faqHtml(CALFAQ)}${upd()}`,
    ld: faqLd(CALFAQ),
  });
  SEARCH.push(['Fixture de la ⟦LIGA⟧', '/fixture/', 'Fixture', 'calendario fechas jornada fecha']);
}

// Pronóstico de hoy: lo que dicen las cuotas (favorito + probabilidad). Nunca «pronóstico seguro».
{
  const win = ALL.filter((m) => m.start * 1000 < NOW + 36 * 36e5 && probs(m));
  const pool = (win.length >= 4 ? win : ALL.filter((m) => probs(m)).slice(0, 16));
  const pick = (m) => { const r = probs(m), k = ['1', 'X', '2'][r.fav]; return { m, r, lbl: { 1: `Gana ${m.home}`, X: 'Empate', 2: `Gana ${m.away}` }[k], dc: r.fav === 0 ? `${m.home} o empate (1X)` : r.fav === 2 ? `${m.away} o empate (X2)` : null, dcp: r.fav === 0 ? r.p[0] + r.p[1] : r.fav === 2 ? r.p[2] + r.p[1] : null }; };
  const P = pool.map(pick).sort((a, b) => (a.m.group === 'liga' ? 0 : 1) - (b.m.group === 'liga' ? 0 : 1) || a.m.start - b.m.start);
  const best = P.filter((x) => x.r.fav !== 1).sort((a, b) => b.r.p[b.r.fav] - a.r.p[a.r.fav]).slice(0, 5);
  const row = (x) => `<div class="m"><div class="t"><span class="tb tbs" data-t="${x.m.start}"></span>${esc(x.m.tournament || x.m.gname)} · ${when(x.m.start)}</div><div class="n"><a href="${murl(x.m)}">${esc(x.m.home)} <em>vs</em> ${esc(x.m.away)}</a></div>${oddsRow(x.m)}<p class="small mt">Según las cuotas: <b>${esc(x.lbl)}</b> (${Math.round(x.r.p[x.r.fav] * 100)} %)${x.dc ? ` · más prudente: <b>${esc(x.dc)}</b> (${Math.round(x.dcp * 100)} %)` : ''}</p></div>`;
  const byG = {}; for (const x of P) (byG[GNAME[x.m.group] || x.m.gname] = byG[GNAME[x.m.group] || x.m.gname] || []).push(x);
  const faq = [
    ['¿Cómo se hace este pronóstico?', 'Con las cuotas de 1xBet: cada cuota se convierte en probabilidad (1 ÷ cuota, sin el margen de la casa) y se indica el resultado más probable. No es la opinión de un experto ni una garantía.'],
    ['¿Cuál es el mejor pronóstico de hoy?', best[0] ? `Según las cuotas, el favorito más claro ahora: ${best[0].lbl} (${best[0].m.home} vs ${best[0].m.away}), ${Math.round(best[0].r.p[best[0].r.fav] * 100)} %. Incluso un favorito al 80 % pierde aproximadamente uno de cada cinco partidos.` : 'La lista se actualiza cada 3 horas con las cuotas.'],
    ['¿Existen pronósticos seguros?', 'No. Los grupos o sitios que venden «pronósticos seguros», «marcadores exactos» o «combinadas garantizadas» son estafas.'],
  ];
  page('/pronostico-de-hoy/', {
    title: 'Pronóstico de hoy: favoritos de los partidos según las cuotas (⟦LIGA⟧ y más)',
    desc: 'Pronóstico de los partidos de hoy y mañana: el favorito de cada partido de la ⟦LIGA⟧, la Selección y las copas con su probabilidad según las cuotas. Sin «pronósticos seguros».',
    crumb: 'Pronóstico de hoy',
    body: `<h1>Pronóstico de hoy</h1><p class="lead">Para cada partido de hoy y mañana: el resultado más probable según las cuotas, su probabilidad y una opción más prudente (doble oportunidad). Hora de ⟦PAIS⟧.</p>
${best.length ? `<h2>Los favoritos más claros</h2><div class="ms">${best.map(row).join('')}</div>` : ''}
${Object.entries(byG).map(([g, xs]) => `<h2>${esc(g)}</h2><div class="ms">${xs.map(row).join('')}</div>`).join('') || noMatches}
<h2>Cómo leer estos pronósticos</h2><ul class="prose"><li>Una probabilidad del 60 % significa que ese resultado pasa unas 6 de cada 10 veces, no siempre.</li><li>La opción «más prudente» (1X o X2) gana más seguido pero paga menos.</li><li>Las cuotas cambian hasta el inicio del partido: la página se actualiza cada 3 horas.</li></ul>
<div class="disc">Ningún pronóstico es seguro. Apuesta solo lo que puedes perder. Solo mayores de 18 años.</div>
<p class="small"><a href="/partidos-de-hoy/">Partidos de hoy</a> · <a href="/calculadora-apuestas-combinadas/">Calculadora de combinadas</a></p>${faqHtml(faq)}${upd()}`,
    ld: faqLd(faq),
  });
  SEARCH.push(['Pronóstico de hoy', '/pronostico-de-hoy/', 'Pronósticos', 'pronosticos favoritos']);
}
}
if (IS_ROOT) {
// Calculadora de apuestas combinadas (herramienta, sin datos)
{
  const faq = [['¿Cómo se calcula la ganancia de una combinada?', 'Se multiplican las cuotas de todas las selecciones y el resultado se multiplica por lo apostado. Ejemplo: 1.50 × 2.00 × 1.80 = 5.40; con ⟦CUR⟧ 50 el pago total es ⟦CUR⟧ 270.'], ['¿Por qué las combinadas se pierden tanto?', 'Basta con que falle una sola selección para perder todo el boleto. Con 5 selecciones al 70 % cada una, la probabilidad de acertar todas es solo de un 17 %.']];
  page('/calculadora-apuestas-combinadas/', {
    title: 'Calculadora de apuestas combinadas: cuota total, ganancia y probabilidad (⟦MONEY⟧)',
    desc: 'Calcula la cuota total y la ganancia de una apuesta combinada en ⟦MONEY⟧, con la probabilidad real de acertar todo el boleto. Gratis, sin registro.',
    crumb: 'Calculadora de combinadas',
    body: `<h1>Calculadora de apuestas combinadas</h1><p class="lead">Escribe la cuota de cada selección y lo que apuestas: verás la cuota total, el pago posible y la probabilidad de que salga todo el boleto.</p>
<div class="calc ccalc"><div id="legs"></div><button type="button" id="add" class="btn2">+ Agregar selección</button>
<label for="cmise">Apuesta</label><input id="cmise" type="number" inputmode="decimal" value="50" min="1" step="1">
<div class="r3"><div><span class="small">Cuota total</span><b id="ct">–</b></div><div><span class="small">Pago total</span><b id="cg">–</b></div><div><span class="small">Probabilidad de acertar todo*</span><b id="cp">–</b></div></div>
<p class="small mt">* Estimación a partir de las cuotas (1 ÷ cuota, sin el margen de la casa): la probabilidad real es un poco menor.</p></div>
<h2>Cómo funciona</h2><p>La cuota total es el producto de las cuotas. Cada partido que agregas sube el pago posible, pero baja rápido la probabilidad de acertar todo.</p>
<div class="disc">Apuesta solo lo que puedes perder. Solo mayores de 18 años.</div>
<p class="small"><a href="/">Fútbol hoy</a> · <a href="/en-vivo/">En vivo</a></p>${faqHtml(faq)}
<script>(function(){var L=document.getElementById('legs'),n=0,fmt=function(x){return '⟦CUR⟧ '+x.toLocaleString('es-419',{maximumFractionDigits:2})};function add(v){if(n>=12)return;n++;var d=document.createElement('div');d.className='leg';d.innerHTML='<span>Selección '+n+'</span><input type="number" inputmode="decimal" step="0.01" min="1.01" value="'+(v||'')+'" placeholder="Cuota, ej. 1.85"><button type="button" aria-label="Quitar">×</button>';d.querySelector('button').onclick=function(){d.remove();calc()};d.querySelector('input').oninput=calc;L.appendChild(d)}
function calc(){var o=[].map.call(L.querySelectorAll('input'),function(i){return parseFloat(String(i.value).replace(',','.'))}).filter(function(x){return x>1});var m=+document.getElementById('cmise').value||0;if(!o.length){['ct','cg','cp'].forEach(function(k){document.getElementById(k).textContent='–'});return}var c=o.reduce(function(a,b){return a*b},1),p=o.reduce(function(a,b){return a/b},1);document.getElementById('ct').textContent=c.toFixed(2);document.getElementById('cg').textContent=fmt(c*m);document.getElementById('cp').textContent=(p*100).toFixed(p<0.1?1:0)+' %'}
document.getElementById('add').onclick=function(){add()};document.getElementById('cmise').oninput=calc;add(1.5);add(2);add(1.8);calc()})();</script>`,
    ld: faqLd(faq),
  });
  SEARCH.push(['Calculadora de combinadas', '/calculadora-apuestas-combinadas/', 'Herramienta', 'parlay calculadora']);
}

// En vivo («en vivo» ~7K en las colas de los clubes): partidos que se juegan ahora, marcador cada minuto (/api/live)
{
  const XALL = [...PIN.flatMap((x) => x.matches), ...ALL].sort((a, b) => a.start - b.start);
  const today = XALL.filter((m) => m.start * 1000 > NOW - 3 * 36e5 && m.start * 1000 < NOW + 30 * 36e5);
  const MAP = Object.fromEntries(XALL.map((m) => [m.rk, P(murl(m))]));
  page('/en-vivo/', {
    title: 'Fútbol en vivo hoy: marcador al minuto de Argentina, México, Libertadores, Champions y más',
    desc: 'Partidos en vivo de las ligas de Argentina, México, Chile, Perú, Ecuador, Bolivia, Paraguay y España, la Libertadores, la Sudamericana, la Champions y la Premier: marcador y minuto, actualizado cada minuto.',
    crumb: 'En vivo',
    body: `<h1>Fútbol en vivo hoy</h1><p class="lead">Marcador y minuto de los partidos que se juegan ahora en las ligas de ⟦PAISES⟧, las selecciones, la Copa Libertadores, la Sudamericana y las ligas europeas. Se actualiza cada minuto.</p>
<div id="lvall" class="ms"><div class="disc">Buscando partidos en vivo…</div></div>
<h2>Partidos de hoy y mañana</h2>${list(today)}
<p class="small mt">Marcador según 1xBet. No transmitimos partidos: para ver el partido, consulta el canal oficial. <a href="/">Fútbol hoy por país</a></p>
<script>(function(){var M=${JSON.stringify(MAP)},B=document.getElementById('lvall'),h=function(x){return String(x||'').replace(/[&<>"]/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]})};
function go(){fetch('/api/live',{cache:'no-store'}).then(function(r){return r.json()}).then(function(d){var m=d.m||[];B.innerHTML=m.length?m.map(function(x){var u=M[x.k]||M[x.k.split('|').reverse().join('|')];return '<div class="m"><div class="t">'+h(x.tn)+'</div><div class="lvb"><i></i>EN VIVO <b>'+x.s[0]+'–'+x.s[1]+'</b>'+(x.min!=null?' · '+x.min+"'":'')+(x.p?' · '+h(x.p):'')+'</div><div class="n">'+(u?'<a href="'+h(u)+'">':'')+h(x.h)+' <em>vs</em> '+h(x.a)+(u?'</a>':'')+'</div></div>'}).join(''):'<div class="disc">Ahora mismo no hay partidos en vivo de estas ligas. Mira abajo los próximos.</div>'}).catch(function(){B.innerHTML='<div class="disc">No se pudo cargar el marcador. Intenta de nuevo en un minuto.</div>'})}go();setInterval(go,60000)})();</script>${upd()}`,
  });
  SEARCH.push(['En vivo', '/en-vivo/', 'Marcador', 'vivo live marcador']);
}
}
if (!IS_ROOT) {
// Equipos
page('/equipos/', {
  title: 'Equipos de la ⟦LIGA⟧: próximos partidos y posiciones',
  desc: `Los ${CLUBS.length} equipos de la ⟦LIGA⟧: próximo partido, posición en la tabla y últimos resultados de cada uno.`,
  crumb: 'Equipos',
  body: `<h1>Equipos de la ⟦LIGA⟧</h1><div class="ms">${CLUBS.map((k) => { const n = nextOf(k.name)[0], ps = posOf(k.name); return `<div class="m"><div class="n"><a href="${curl(k.name)}">${crest(k.name, 28)}${esc(k.name)}</a></div><div class="p">${ps ? `${ps.pos}.º · ${ps.pts} pts · ` : ''}${n ? `Próximo: ${esc(n.home)} vs ${esc(n.away)}, ${day(n.start)}` : 'Próximo partido sin fecha publicada'}</div></div>`; }).join('')}</div>`,
});

// Páginas de equipo («municipal hoy» 10K, «cuándo juega municipal» 8.1K, «posiciones de … municipal» 33K)
for (const k of CLUBS) {
  const n = k.name, nx = nextOf(n), last = lastOf(n, 1)[0], ps = posOf(n);
  const faq = [
    [`¿Cuándo juega ${n}?`, nx[0] ? `El próximo partido de ${n} es ${nx[0].home} vs ${nx[0].away} (${nx[0].tournament || nx[0].gname}), ${when(nx[0].start)}.` : `Todavía no hay fecha publicada con cuotas para el próximo partido de ${n}. La página se actualiza cada 3 horas.`],
    ...(last ? [[`¿Cómo quedó el último partido de ${n}?`, `${last.home} ${last.score[0]}-${last.score[1]} ${last.away}, el ${day(last.start)}.`]] : []),
    ...(nx.length > 1 ? [[`¿Cuáles son los próximos partidos de ${n}?`, nx.slice(0, 4).map((x) => `${x.home} vs ${x.away} (${day(x.start)})`).join('; ') + '.']] : []),
    ...(ps ? [[`¿En qué posición va ${n}?`, `${n} va ${ps.pos}.º en el ${TORNEO.name} con ${ps.pts} puntos (${ps.g} ganados, ${ps.e} empates, ${ps.p} perdidos).`]] : []),
  ];
  const rivals = CLUBS.filter((o) => o.slug !== k.slug);
  page(curl(n), {
    title: nx[0] ? `${n} hoy: ${nx[0].home} vs ${nx[0].away} en vivo, hora y posiciones` : `Posiciones de ${n}: cuándo juega, resultados y en vivo`,
    desc: `${n}: ${nx[0] ? `próximo partido ${nx[0].home} vs ${nx[0].away}, ${when(nx[0].start)}. ` : ''}${ps ? `${ps.pos}.º en la tabla con ${ps.pts} pts. ` : ''}Últimos resultados y cuotas.`,
    crumb: n, parent: ['/equipos/', 'Equipos'],
    body: `<div class="crh">${crest(n, 72, true)}</div><h1>${esc(n)} hoy: partidos, posiciones y en vivo</h1>
${INFO[n] ? `<p class="lead">${esc(INFO[n].full)} — ${esc(INFO[n].nick)}${INFO[n].alias.length > 1 ? ` (también ${INFO[n].alias.filter((x) => x !== INFO[n].nick).map(esc).join(', ')})` : ''}: próximo partido, posiciones y resultados del ${esc(TORNEO.name)}.</p>` : ''}
${todayBox(n, nx[0], last)}
<h2>Próximos partidos de ${esc(n)}</h2>${list(nx)}
${ps ? `<h2>Posiciones de ${esc(INFO[n] ? INFO[n].full : n)}</h2><p>${esc(n)} va <b>${ps.pos}.º</b> en el ${esc(TORNEO.name)} con <b>${ps.pts} puntos</b> en ${ps.pj} partidos: ${ps.g} ganados, ${ps.e} empates y ${ps.p} perdidos, ${ps.gf} goles a favor y ${ps.gc} en contra. Últimos 5: ${formHtml(ps.form)}</p>${tableHtml(TABLE, { around: [n] })}<p class="small"><a href="/posiciones/">Tabla de posiciones completa</a></p>` : ''}
${seasonTxt(n)}
${lastOf(n, 8).length ? `<h2>Últimos resultados de ${esc(n)}</h2>${resList(lastOf(n, 8))}` : ''}
<h2>${esc(n)} contra cada rival</h2><div class="chipl">${rivals.map((o) => `<a href="${purl(n, o.name)}">${esc(n)} vs ${esc(o.name)}</a>`).join('')}</div>
${faqHtml(faq)}${upd()}`,
    ld: [{ '@type': 'SportsTeam', name: n, ...(INFO[n] ? { alternateName: [INFO[n].full, ...INFO[n].alias] } : {}), sport: 'Soccer', memberOf: { '@type': 'SportsOrganization', name: '⟦LIGA⟧' } }, ...faqLd(faq)],
  });
  SEARCH.push([n, curl(n), 'Equipo', INFO[n] ? [INFO[n].full, ...INFO[n].alias].join(' ') : '']);
}

// Páginas de cada par de equipos: una URL estable por enfrentamiento («antigua gfc - municipal» 19K, «municipal vs antigua gfc» 11K…)
const pairsDone = new Set();
// Clásicos («oriente vs blooming» ~30K/mes en sus variantes; «bolívar vs the strongest» ~9K)
const CLASICO = C.clasicos || {};
const clasicoOf = (a, b) => CLASICO[pairKey(a, b).join('|')] || null;
for (let i = 0; i < CLUBS.length; i++) for (let j = i + 1; j < CLUBS.length; j++) {
  const A = CLUBS[i].name, B = CLUBS[j].name, u = purl(A, B);
  if (pairsDone.has(u)) continue; pairsDone.add(u);
  const m = ALL.find((x) => (same(x.home, A) && same(x.away, B)) || (same(x.home, B) && same(x.away, A)));
  const H = history(A, B, m), last = H[0];
  const [h, a] = m ? [m.home, m.away] : last ? [last.h, last.a] : [A, B];
  const r = m && probs(m), v = m ? verdictOf(m) : '';
  const lastTxt = last ? `${last.h} ${last.s[0]}-${last.s[1]} ${last.a} (${dyear(last.d)})` : '';
  const CL = clasicoOf(A, B);
  const faq = [
    ...(CL ? [[`¿Cuándo es el ${CL[0].toLowerCase()}?`, m ? `El próximo ${CL[0].toLowerCase()} es ${m.home} vs ${m.away}, ${when(m.start)} (${m.tournament || m.gname}).` : `Todavía no hay fecha publicada con cuotas para el próximo ${CL[0].toLowerCase()}. La página se actualiza cada 3 horas.`]] : []),
    [`¿Cuándo juegan ${h} vs ${a}?`, m ? `${m.home} vs ${m.away} se juega ${when(m.start)} (${m.tournament || m.gname}).` : `Todavía no hay fecha publicada con cuotas para el próximo ${A} vs ${B}. La página se actualiza cada 3 horas.`],
    ...(last ? [[`¿Cómo quedó el último ${A} vs ${B}?`, `El último enfrentamiento terminó ${lastTxt}.`]] : []),
    ...(r ? [[`¿Quién es favorito?`, `${v} No es un pronóstico seguro: ninguno lo es.`]] : []),
  ];
  page(u, {
    title: (CL ? `${CL[0]}: ` : '') + (m ? `${h} vs ${a} en vivo hoy: hora, posiciones y pronóstico` : last ? `${h} vs ${a}: cómo quedó ${last.s[0]}-${last.s[1]}, resultado y posiciones` : `${A} vs ${B}: historial y próximo partido`),
    desc: (CL ? `${CL[0]} · ` : '') + (m ? `${h} vs ${a}, ${m.tournament || m.gname}: ${when(m.start)}. Cuotas de 1xBet, historial${last ? ` (último: ${lastTxt})` : ''} y forma de los dos equipos.` : `${A} vs ${B}: ${last ? `el último partido terminó ${lastTxt}. ` : ''}Historial de enfrentamientos, posiciones y próximo partido en cuanto se publique.`),
    crumb: `${h} vs ${a}`, parent: ['/partidos-de-hoy/', 'Partidos'],
    body: `${vsBox(h, a)}<h1>${CL ? `${esc(CL[0])}: ` : ''}${esc(h)} vs ${esc(a)}${m ? ' en vivo hoy: hora, posiciones y pronóstico' : ': resultado, historial y posiciones'}</h1>
${CL ? `<p class="ans">El <b>${esc(CL[0].toLowerCase())}</b> es el partido entre ${esc(A)} y ${esc(B)}, ${esc(CL[1])}.${H.length ? ` En nuestros datos hay ${H.length} ${H.length === 1 ? 'enfrentamiento reciente' : 'enfrentamientos recientes'}: ${(() => { const w = { [slug(A)]: 0, [slug(B)]: 0 }; let e = 0; for (const x of H) { if (x.s[0] === x.s[1]) e++; else w[slug(x.s[0] > x.s[1] ? x.h : x.a)]++; } return `${esc(A)} ganó ${w[slug(A)]}, ${esc(B)} ganó ${w[slug(B)]} y ${e} ${e === 1 ? 'terminó' : 'terminaron'} en empate`; })()}.` : ''}</p>` : ''}
${nickOf(h) || nickOf(a) ? `<p class="small">${esc(nickOf(h) || h)} vs ${esc(nickOf(a) || a)}${INFO[h] || INFO[a] ? ` · ${[h, a].filter((t) => INFO[t]).map((t) => esc(INFO[t].full)).join(' · ')}` : ''}</p>` : ''}
${m ? `<p class="lead"><b>¿A qué hora?</b> ${esc(m.tournament || m.gname)}, ${tm(m.start)}. <span class="cd" data-u="${m.start}"></span></p><div class="lvs" data-k="${esc(m.rk || '')}" data-t="${m.start}"></div>${card(m, false).replace(/ data-k="[^"]*" data-t="\d+"/, '')}
${mimg(m) ? `<img class="mimg" src="${mimg(m)}" width="1200" height="630" alt="${esc(m.home)} vs ${esc(m.away)}, ${esc(day(m.start))}" loading="lazy">` : ''}
${previaHtml(m, H)}
${r ? `<h2>Pronóstico según las cuotas</h2><p>${esc(v)} El margen de la casa en este mercado es de ${r.margin.toFixed(1)} %. Es una lectura de las cuotas, no un pronóstico seguro.</p>${calcHtml(m)}` : ''}${marketsHtml(m)}` : `<div class="today"><div class="tn"><span class="tb">Próximo partido</span><b>Todavía sin fecha publicada</b></div>${last ? `<div class="tl"><span class="tb tb2">Último resultado</span><div class="rr"><span class="rd">${day(last.d)}</span><span class="rt">${esc(last.h)} <b>${last.s[0]}–${last.s[1]}</b> ${esc(last.a)}</span></div></div>` : ''}</div>`}
${last ? `<h2>¿Cómo quedó el último ${esc(A)} vs ${esc(B)}?</h2><div class="score"><span>${teamLink(last.h)}</span><b>${last.s[0]} – ${last.s[1]}</b><span>${teamLink(last.a)}</span></div><p class="small">${day(last.d)}.</p>` : ''}
${h2hHtml(h, a, H)}
${pairTxt(h, a, H)}
${formBlock([h, a], m)}
${TABLE.length && (posOf(h) || posOf(a)) ? `<h2>Posiciones</h2><p>${[posLine(h), posLine(a)].filter(Boolean).join(' · ')}.</p>${tableHtml(TABLE, { around: [h, a] })}<p class="small">Los dos equipos del partido y sus vecinos en la tabla. <a href="/posiciones/">Tabla completa</a></p>` : ''}
<p class="small mt">Más: <a href="${curl(A)}">${esc(A)} hoy</a> · <a href="${curl(B)}">${esc(B)} hoy</a> · <a href="/partidos-de-hoy/">Partidos de hoy</a>${m ? ' · Toca una cuota para abrir 1xBet con esa apuesta en tu cupón.' : ''}</p>
${faqHtml(faq)}`,
    og: mimg(m),
    ld: [...(m ? [{ ...evLd(m), ...(mimg(m) ? { image: BASE + mimg(m) } : {}) }] : []), ...faqLd(faq)],
  });
  SEARCH.push([CL ? `${CL[0]}: ${A} vs ${B}` : `${A} vs ${B}`, u, 'Partido', `${B} vs ${A} ${nickOf(A) || ''} ${nickOf(B) || ''} ${CL ? CL[0] + ' clasico' : ''}`]);
}

// Otros partidos (Selección, Concacaf): una página por partido próximo
for (const m of ALL.filter((x) => !isPair(x.home, x.away) && !ownUrl(x))) {
  const r = probs(m), v = verdictOf(m), H = history(m.home, m.away, m);
  page(murl(m), {
    title: `${m.home} vs ${m.away} en vivo hoy: hora, pronóstico y cuotas (${dshort(m.start)})`,
    desc: `${m.home} vs ${m.away}, ${m.tournament || m.gname}: ${when(m.start)}. Cuotas de 1xBet, historial y forma. ${v}`,
    crumb: `${m.home} vs ${m.away}`, parent: ['/partidos-de-hoy/', 'Partidos'],
    body: `${vsBox(m.home, m.away)}<h1>${esc(m.home)} vs ${esc(m.away)}: hora, pronóstico y cuotas</h1><p class="lead"><b>¿A qué hora?</b> ${esc(m.tournament || m.gname)}, ${tm(m.start)}. <span class="cd" data-u="${m.start}"></span></p><div class="lvs" data-k="${esc(m.rk || '')}" data-t="${m.start}"></div>${card(m, false).replace(/ data-k="[^"]*" data-t="\d+"/, '')}
${r ? `<h2>Pronóstico según las cuotas</h2><p>${esc(v)} No es un pronóstico seguro.</p>${calcHtml(m)}` : ''}${marketsHtml(m)}${H.length ? h2hHtml(m.home, m.away, H) : ''}${formBlock([m.home, m.away], m)}`,
    og: mimg(m), ld: [{ ...evLd(m), ...(mimg(m) ? { image: BASE + mimg(m) } : {}) }],
  });
}

const BVS = (() => {
  const o = {};
  const add = (n) => { if (!n || same(n, C.nation)) return; const k = slug(n); if (!o[k]) o[k] = n; };
  for (const r of RES.filter(plays(C.nation))) add(same(r.home, C.nation) ? r.away : r.home);
  for (const m of ALL.filter(plays(C.nation))) add(same(m.home, C.nation) ? m.away : m.home);
  return Object.values(o);
})();
// Selección ⟦DE⟧ («guatemala vs» 93K, «selección de guatemala» 12K)
{
  const nx = ALL.filter(plays(C.nation)), lr = RES.filter(plays(C.nation));
  const opp = nx[0] ? (same(nx[0].home, C.nation) ? nx[0].away : nx[0].home) : null;
  const faq = [['¿Cuándo juega ⟦NATION⟧?', nx[0] ? `El próximo partido de la Selección es ${nx[0].home} vs ${nx[0].away} (${nx[0].tournament}), ${when(nx[0].start)}.` : 'Todavía no hay fecha publicada con cuotas para el próximo partido de la Selección. La página se actualiza cada 3 horas.'], ...(lr[0] ? [['¿Cómo quedó el último partido ⟦DE⟧?', `${lr[0].home} ${lr[0].score[0]}-${lr[0].score[1]} ${lr[0].away}, el ${day(lr[0].start)}.`]] : [])];
  page(SELU, {
    title: opp ? `⟦NATION⟧ vs ${opp}: próximo partido de la Selección, hora y cuotas` : 'Selección ⟦DE⟧: cuándo juega, próximos partidos y resultados',
    desc: `${nx[0] ? `⟦NATION⟧ vs ${opp}, ${when(nx[0].start)}. ` : ''}Próximos partidos de la Selección ⟦DE⟧ con hora y cuotas, y los últimos resultados.`,
    crumb: 'Selección ⟦DE⟧',
    body: `<h1>Selección ⟦DE⟧: cuándo juega ⟦NICK⟧</h1>${todayBox('la Selección', nx[0], lr[0])}<h2>Próximos partidos</h2>${list(nx)}${lr.length ? `<h2>Últimos resultados</h2>${resList(lr.slice(0, 10))}` : ''}${BVS.length ? `<h2>⟦NATION⟧ contra cada rival</h2><div class="chipl">${BVS.map((x) => `<a href="${bvsUrl(x)}">⟦NATION⟧ vs ${esc(x)}</a>`).join('')}</div>` : ''}${faqHtml(faq)}${upd()}`,
    ld: [{ '@type': 'SportsTeam', name: 'Selección ⟦DE⟧', sport: 'Soccer' }, ...faqLd(faq)],
  });
  SEARCH.push(['Selección ⟦DE⟧', SELU, 'Selección', '⟦NATION⟧ vs ⟦NICK⟧']);
}

// «honduras vs» 30K, «el salvador vs» 21K, «panama vs» 67K, «nicaragua vs» 3.5K (KD 0–2): una página por rival de la Selección con datos reales (resultados guardados + h2h de 1xBet).
for (const R of BVS) {
  const m = ALL.find((x) => plays(C.nation)(x) && plays(R)(x));
  const H = history(C.nation, R, m), last = H[0];
  const rec = { g: 0, e: 0, p: 0, gf: 0, gc: 0 };
  for (const x of H) { const bh = same(x.h, C.nation), f = bh ? x.s[0] : x.s[1], c = bh ? x.s[1] : x.s[0]; rec.gf += f; rec.gc += c; rec[f > c ? 'g' : f === c ? 'e' : 'p']++; }
  const lastTxt = last ? `${last.h} ${last.s[0]}-${last.s[1]} ${last.a} (${dyear(last.d)})` : '';
  const comp = (d) => { const r = RES.find((x) => Math.abs(x.start - d) < 86400 && plays(C.nation)(x) && plays(R)(x)); return r && r.tname ? r.tname.replace(/\. Selecciones$/, '') : ''; };
  const faq = [
    [`¿Cuándo juega ⟦NATION⟧ vs ${R}?`, m ? `${m.home} vs ${m.away} se juega ${when(m.start)} (${m.tournament || m.gname}).` : `Todavía no hay fecha publicada con cuotas para el próximo ⟦NATION⟧ vs ${R}. La página se actualiza cada 3 horas.`],
    ...(last ? [[`¿Cómo quedó el último ⟦NATION⟧ vs ${R}?`, `El último partido terminó ${lastTxt}${comp(last.d) ? `, ${comp(last.d)}` : ''}.`]] : []),
    ...(H.length > 1 ? [[`¿Cuál es el historial ⟦DE⟧ contra ${R}?`, `En los ${H.length} partidos que tenemos registrados, ⟦NATION⟧ ganó ${rec.g}, empató ${rec.e} y perdió ${rec.p} (goles: ${rec.gf} a favor, ${rec.gc} en contra).`]] : []),
  ];
  page(bvsUrl(R), {
    title: m ? `⟦NATION⟧ vs ${R} en vivo hoy: hora, cuotas y pronóstico (${dshort(m.start)})` : last ? `⟦NATION⟧ vs ${R}: cómo quedó ${same(last.h, C.nation) ? last.s[0] + '-' + last.s[1] : last.s[1] + '-' + last.s[0]}, historial y próximo partido` : `⟦NATION⟧ vs ${R}: historial y próximo partido`,
    desc: m ? `⟦NATION⟧ vs ${R}: ${when(m.start)}, ${m.tournament || m.gname}. Cuotas de 1xBet${last ? ` y el último partido (${lastTxt})` : ''}.` : `⟦NATION⟧ vs ${R}: ${last ? `el último partido terminó ${lastTxt}. ` : ''}Historial de la Selección contra ${R} y próximo partido en cuanto se publique.`,
    crumb: `⟦NATION⟧ vs ${R}`, parent: [SELU, 'Selección ⟦DE⟧'],
    body: `${vsBox(C.nation, R)}<h1>⟦NATION⟧ vs ${esc(R)}${m ? ': hora, cuotas y historial' : ': historial y próximo partido'}</h1>
<p class="ans">${m ? `<b>Próximo partido:</b> ${esc(m.home)} vs ${esc(m.away)}, ${tm(m.start)} (${esc(m.tournament || m.gname)}).` : `<b>Próximo partido:</b> todavía sin fecha publicada con cuotas.`}${last ? ` <b>Último:</b> ${esc(last.h)} ${last.s[0]}-${last.s[1]} ${esc(last.a)}${comp(last.d) ? `, ${esc(comp(last.d))}` : ''} (${dyear(last.d)}).` : ''}</p>
${m ? `<div class="lvs" data-k="${esc(m.rk || '')}" data-t="${m.start}"></div>${card(m, false).replace(/ data-k="[^"]*" data-t="\d+"/, '')}${marketsHtml(m)}` : ''}
${H.length ? `<h2>Historial ⟦NATION⟧ vs ${esc(R)}</h2><p>${H.length > 1 ? `En los ${H.length} partidos registrados: ⟦NATION⟧ <b>${rec.g}</b> victorias, <b>${rec.e}</b> empates y <b>${rec.p}</b> derrotas, ${rec.gf} goles a favor y ${rec.gc} en contra.` : 'Último enfrentamiento registrado:'}</p><div class="rl">${H.map((x) => `<div class="rr"><span class="rd">${dyear(x.d)}</span><span class="rt">${crest(x.h, 18)}${esc(x.h)} <b>${x.s[0]}–${x.s[1]}</b> ${esc(x.a)}${crest(x.a, 18)}</span></div>`).join('')}</div>` : ''}
${formBlock([C.nation, R], m)}
<p class="small mt">Más: <a href="⟦SELU⟧">Selección ⟦DE⟧: cuándo juega</a>${BVS.length > 1 ? ` · ${BVS.filter((x) => x !== R).slice(0, 8).map((x) => `<a href="${bvsUrl(x)}">⟦NATION⟧ vs ${esc(x)}</a>`).join(' · ')}` : ''}</p>
${faqHtml(faq)}${upd()}`,
    og: mimg(m),
    ld: [...(m ? [evLd(m)] : []), ...faqLd(faq)],
  });
  SEARCH.push([`⟦NATION⟧ vs ${R}`, bvsUrl(R), 'Selección', `${R} vs ⟦NATION⟧ ⟦NICK⟧`]);
}

// Clubes del país en la Concacaf / Copa Centroamericana: una URL estable por enfrentamiento con un club extranjero
// («bolívar vs são paulo» 8.4K, «blooming vs river» ~5K, «ldu quito - always ready» 2.5K)
const IPAIRS = (() => {
  const o = {};
  const add = (h, a, t, g) => { const bh = clubOf(h), ba = clubOf(a); if (!!bh === !!ba) return; const B = bh ? bh.name : ba.name, FR = strip(bh ? a : h), F = fname(FR), k = slug(B) + '|' + slug(F); (o[k] = o[k] || { B, F, FR, t: new Set() }).t.add(GNAME[g] || t); };
  for (const r of RES.filter((r) => CUPS.has(r.group))) add(r.home, r.away, r.tname, r.group);
  for (const m of ALL.filter((m) => CUPS.has(m.group))) add(m.home, m.away, m.tournament, m.group);
  return Object.values(o);
})();
for (const { B, F, FR, t } of IPAIRS) {
  const m = ALL.find((x) => CUPS.has(x.group) && plays(B)(x) && plays(FR)(x));
  const H = history(B, FR, m).map((x) => ({ ...x, h: same(x.h, B) ? B : F, a: same(x.a, B) ? B : F })), last = H[0];
  const [h, a] = m ? (plays(B)({ home: m.home, away: '' }) ? [B, F] : [F, B]) : [B, F];
  const comps = [...t].join(' y ');
  const lastTxt = last ? `${last.h} ${last.s[0]}-${last.s[1]} ${last.a} (${dyear(last.d)})` : '';
  const r = m && probs(m), v = m ? verdictOf(m) : '';
  const faq = [
    [`¿Cuándo juegan ${h} vs ${a}?`, m ? `${m.home} vs ${m.away} se juega ${when(m.start)} (${m.tournament || m.gname}).` : `Todavía no hay fecha publicada con cuotas para el próximo ${B} vs ${F}. La página se actualiza cada 3 horas.`],
    ...(last ? [[`¿Cómo quedó ${B} vs ${F}?`, `El último partido terminó ${lastTxt}.`]] : []),
  ];
  page(iurl(B, F), {
    title: m ? `${h} vs ${a} en vivo hoy: hora ⟦HORA⟧, cuotas y pronóstico` : last ? `${B} vs ${F}: cómo quedó ${last.h === B ? last.s[0] + '-' + last.s[1] : last.s[1] + '-' + last.s[0]} (${comps})` : `${B} vs ${F}: historial y próximo partido`,
    desc: m ? `${h} vs ${a}, ${m.tournament || m.gname}: ${when(m.start)}. Cuotas de 1xBet e historial${last ? ` (último: ${lastTxt})` : ''}.` : `${B} vs ${F} (${comps}): ${last ? `el último partido terminó ${lastTxt}. ` : ''}Historial y próximo partido en cuanto se publique.`,
    crumb: `${h} vs ${a}`, parent: ['/partidos-de-hoy/', 'Partidos'],
    body: `${vsBox(h, a)}<h1>${esc(h)} vs ${esc(a)}${m ? ': en vivo hoy, hora ⟦HORA⟧ y pronóstico' : ': resultado e historial'}</h1>
<p class="ans">${esc(B)} contra ${esc(F)} en ${esc(comps)}.${m ? ` <b>Próximo partido:</b> ${tm(m.start)}.` : ''}${m ? '</p>' + zonesHtml(m.start) + '<p>' : ''}${last ? ` <b>Último resultado:</b> ${esc(lastTxt)}.` : ''}</p>
${m ? `<div class="lvs" data-k="${esc(m.rk || '')}" data-t="${m.start}"></div>${card(m, false).replace(/ data-k="[^"]*" data-t="\d+"/, '')}${mimg(m) ? `<img class="mimg" src="${mimg(m)}" width="1200" height="630" alt="${esc(m.home)} vs ${esc(m.away)}" loading="lazy">` : ''}${r ? `<h2>Pronóstico según las cuotas</h2><p>${esc(v)} No es un pronóstico seguro.</p>${calcHtml(m)}` : ''}${marketsHtml(m)}` : ''}
${H.length ? h2hHtml(h, a, H) : ''}
${formBlock([B], m)}
${posOf(B) ? `<p>${esc(posLine(B))} en la ⟦LIGA⟧. <a href="/posiciones/">Tabla de posiciones</a></p>` : ''}
<p class="small mt">Más: <a href="${curl(B)}">${esc(B)} hoy</a> · <a href="/">⟦LIGA⟧</a> · <a href="/partidos-de-hoy/">Partidos de hoy</a></p>
${faqHtml(faq)}`,
    og: mimg(m),
    ld: [...(m ? [{ ...evLd(m), ...(mimg(m) ? { image: BASE + mimg(m) } : {}) }] : []), ...faqLd(faq)],
  });
  SEARCH.push([`${B} vs ${F}`, iurl(B, F), 'Partido', `${F} vs ${B} ${comps}`]);
}


}
if (IS_ROOT) {
// Copas y ligas internacionales, con la hora de cada país («boca vs atlético mineiro hora boliviana», «real madrid vs … hora argentina»)
const LEAGUES = [
  ['copa-libertadores', '/copa-libertadores/', 'Copa Libertadores', 'la Copa Libertadores'],
  ['copa-sudamericana', '/copa-sudamericana/', 'Copa Sudamericana', 'la Copa Sudamericana'],
  ['champions-league', '/champions-league/', 'Champions League', 'la Champions League'],
  ['laliga', '/laliga/', 'LaLiga', 'LaLiga de España'],
  ['premier-league', '/premier-league/', 'Premier League', 'la Premier League'],
];
const resG = (g) => RES.filter((r) => r.group === g);
for (const [g, u, n, de] of LEAGUES) {
  const ms = ALL.filter((m) => m.group === g), rs = resG(g), m0 = ms[0];
  const faq = [
    [`¿Cuándo es el próximo partido de ${de}?`, m0 ? `${m0.home} vs ${m0.away}, ${day(m0.start)}: ${zonesTxt(m0.start)}.` : `Todavía no hay partidos de ${de} con fecha y cuotas publicadas. La página se actualiza cada 3 horas.`],
    ...(rs[0] ? [[`¿Cómo quedó el último partido de ${de}?`, `${rs[0].home} ${rs[0].score[0]}-${rs[0].score[1]} ${rs[0].away} (${dyear(rs[0].start)}).`]] : []),
    ['¿A qué hora son los partidos en mi país?', 'Debajo de cada partido está la hora de Argentina, Chile, Paraguay, Bolivia, Perú, Ecuador, México y España.'],
  ];
  page(u, {
    title: `${n} hoy: partidos en vivo, hora en tu país y resultados`,
    desc: `${m0 ? `${m0.home} vs ${m0.away}, ${day(m0.start)}. ` : ''}Próximos partidos de ${de} con la hora de Argentina, México, Perú, Chile y más, marcador en vivo, cuotas y últimos resultados.`,
    crumb: n,
    body: `<h1>${esc(n)} hoy: partidos, hora y resultados</h1><p class="lead">Los próximos partidos de ${esc(de)} con la hora de cada país y las cuotas de 1xBet. Durante el partido, el marcador se actualiza cada minuto.</p>
<h2>Próximos partidos</h2>${list(ms)}
${rs.length ? `<h2>Últimos resultados</h2>${resList(rs.slice(0, 16))}` : ''}
${g === 'laliga' ? '<p class="small mt">Tabla de posiciones, equipos y clásicos de LaLiga con la hora de España: <a href="/es/futbol/">fútbol de España</a>.</p>' : ''}
${faqHtml(faq)}${upd()}`,
    ld: faqLd(faq),
  });
  SEARCH.push([n, u, 'Copa / liga', '']);
}
// «real madrid vs», «barcelona vs»: cuándo juega + próximos partidos con la hora de cada país
for (const [u, n, re] of [['/real-madrid/', 'Real Madrid', /^real-madrid$/], ['/barcelona/', 'Barcelona', /^(fc-)?barcelona$/]]) {
  const nx = ALL.filter((m) => re.test(slug(m.home)) || re.test(slug(m.away)));
  const rs = RES.filter((r) => re.test(slug(r.home)) || re.test(slug(r.away)));
  const m0 = nx[0], opp = m0 ? (re.test(slug(m0.home)) ? m0.away : m0.home) : null;
  const f = m0 && m0.stats && (re.test(slug(m0.home)) ? m0.stats.f1 : m0.stats.f2);
  const faq = [[`¿Cuándo juega el ${n}?`, m0 ? `El próximo partido es ${m0.home} vs ${m0.away} (${m0.tournament || m0.gname}), ${day(m0.start)}: ${zonesTxt(m0.start)}.` : `Todavía no hay fecha publicada con cuotas para el próximo partido del ${n}. La página se actualiza cada 3 horas.`], ...(rs[0] ? [[`¿Cómo quedó el último partido del ${n}?`, `${rs[0].home} ${rs[0].score[0]}-${rs[0].score[1]} ${rs[0].away} (${dyear(rs[0].start)}).`]] : [])];
  page(u, {
    title: opp ? `${n} hoy: ${m0.home} vs ${m0.away} en vivo, hora en tu país` : `¿Cuándo juega el ${n}? Próximo partido y hora en tu país`,
    desc: `${m0 ? `${m0.home} vs ${m0.away}, ${day(m0.start)}: ${zonesTxt(m0.start)}. ` : ''}Próximos partidos del ${n} con la hora de cada país, marcador en vivo y resultados.`,
    crumb: n,
    body: `<h1>${esc(n)} hoy: cuándo juega y a qué hora</h1>${todayBox(`el ${n}`, m0, null)}${m0 ? zonesHtml(m0.start) : ''}<h2>Próximos partidos del ${esc(n)}</h2>${list(nx)}${rs.length ? `<h2>Últimos resultados</h2>${resList(rs.slice(0, 8))}` : f && f.length ? `<h2>Últimos 5 partidos</h2><ol class="fsq">${f.map((x) => { const v = x.gf > x.ga ? 'G' : x.gf === x.ga ? 'E' : 'P'; return `<li class="f${{ G: 'V', E: 'N', P: 'D' }[v]}"><b>${v}</b><span>${x.gf}–${x.ga}</span><small>${esc(strip(x.o))}</small></li>`; }).join('')}</ol>` : ''}
${fs.existsSync(path.join(OUT, 'es', 'futbol', 'equipos', slug(n), 'index.html')) ? `<p class="small mt">Posiciones de LaLiga y la página del club con la hora de España: <a href="/es/futbol/posiciones/">tabla de LaLiga</a> · <a href="/es/futbol/equipos/${slug(n)}/">${esc(n)} (España)</a></p>` : ''}${faqHtml(faq)}${upd()}`,
    ld: [{ '@type': 'SportsTeam', name: n, sport: 'Soccer' }, ...faqLd(faq)],
  });
  SEARCH.push([n, u, 'Equipo', '']);
}
// Una página por partido internacional próximo (/futbol/partido/<local>-vs-<visita>/); cuando el partido sale de los datos, la función de Pages redirige a la copa.
for (const m of ALL) {
  const r = probs(m), v = verdictOf(m), H = history(m.home, m.away, m);
  const lg = LEAGUES.find((x) => x[0] === m.group);
  page(murl(m), {
    title: `${m.home} vs ${m.away} en vivo hoy: hora en tu país, cuotas y pronóstico (${dshort(m.start)})`,
    desc: `${m.home} vs ${m.away}, ${m.tournament || m.gname}: ${day(m.start)}, ${zonesTxt(m.start)}. Cuotas de 1xBet, historial y forma.`,
    crumb: `${m.home} vs ${m.away}`, parent: lg ? [lg[1], lg[2]] : ['/', 'Fútbol'],
    body: `${vsBox(m.home, m.away)}<h1>${esc(m.home)} vs ${esc(m.away)} en vivo hoy: hora y pronóstico</h1><p class="lead"><b>${esc(m.tournament || m.gname)}</b>, ${esc(day(m.start))}. <span class="cd" data-u="${m.start}"></span></p>
<h2>¿A qué hora juegan ${esc(m.home)} vs ${esc(m.away)}?</h2><div class="tw"><table class="tab tzt"><tr><th>Hora</th><th>País</th></tr>${zoneRows(m.start).map((x) => `<tr><td><b>${esc(x.h)}</b></td><td>${esc(ylist(x.n))}</td></tr>`).join('')}</table></div>
<div class="lvs" data-k="${esc(m.rk || '')}" data-t="${m.start}"></div>${card(m, false).replace(/ data-k="[^"]*" data-t="\d+"/, '')}
${r ? `<h2>Pronóstico según las cuotas</h2><p>${esc(v)} No es un pronóstico seguro.</p>${calcHtml(m)}` : ''}${marketsHtml(m)}${H.length ? h2hHtml(m.home, m.away, H) : ''}${formBlock([m.home, m.away], m)}
<p class="small mt">Más: ${lg ? `<a href="${lg[1]}">${esc(lg[2])}</a> · ` : ''}<a href="/en-vivo/">Fútbol en vivo</a></p>`,
    ld: [evLd(m)],
  });
}
}

// Sitemap y búsqueda. Cada país deja su parte en dist/.parts/<país>.json; la corrida root (la última) las junta.
const PARTS = path.join(OUT, '.parts');
fs.mkdirSync(PARTS, { recursive: true });
const SEARCHP = SEARCH.map(([l, u, k, x]) => [tok(l), P(u), IS_ROOT ? k : `${k} · ${C.name}`, tok(x || '')]);
if (!IS_ROOT) {
  const XM = ALL.filter((m) => m.start * 1000 < NOW + 8 * 864e5).map((m) => ({ ...m, url: P(murl(m)), country: RG }));
  const LEAD = TABLE.slice(0, 3).map((x) => ({ team: x.team, pts: x.pts, pj: x.pj }));
  fs.writeFileSync(path.join(PARTS, `${RG}.json`), JSON.stringify({ sitemap, search: SEARCHP, matches: XM, lead: LEAD, torneo: TORNEO.name, clubs: CLUBS.length }));
  console.log(`${C.name}: ${sitemap.length} pages · ${ALL.length} matches (${LIGA.length} liga) · ${RES.length} results · ${CLUBS.length} clubs · table ${TABLE.length}`);
} else {
  const SM = [...sitemap, ...PIN.flatMap((x) => x.sitemap)];
  fs.writeFileSync(path.join(OUT, 'futbol', 'search.json'), JSON.stringify([...PIN.flatMap((x) => x.search), ...SEARCHP]));
  fs.writeFileSync(path.join(OUT, 'sitemap-futbol.xml'), `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${SM.map((u) => `<url><loc>${u}</loc></url>`).join('\n')}\n</urlset>\n`);
  fs.rmSync(PARTS, { recursive: true, force: true });
  console.log(`root: ${sitemap.length} pages · total ${SM.length}`);
}
