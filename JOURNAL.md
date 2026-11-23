# GoClarivo — журнал изменений

Формат: дата — что изменили, почему. Сверять с графиками Search Console.

## 23.11.2026 — футбольный раздел на движке Liga Chapina / Liga Tica / Marcador Central (решение Олега: делать сейчас, без ожидания заморозки — у сайта почти ноль показов)

- Данные: `engine/scripts/odds.py` (1xBet Marketing API) для каждого гео + `int` (Libertadores, Sudamericana, Champions, LaLiga, Premier) → `engine/data/<geo>/`; эмблемы → `engine/assets/t`. Workflow `.github/workflows/engine.yml` каждые 3 часа (секреты ONEXBET_* в GitHub уже были).
- Страницы (первая фаза — испаноязычные гео ar, mx, cl, pe, ec, bo, py, es): `/<geo>/futbol/` — лига, partidos de hoy, posiciones (считаем из результатов 3/1/0, с пометкой «puede diferir de la oficial»), fixture, resultados, pronóstico (по коэффициентам, без «pronóstico seguro»), equipos, страницы клубов, пары клубов, сборная и «<страна> vs <соперник>», клубы страны в Libertadores/Sudamericana. Время — местное.
- `/futbol/` — международный раздел: en vivo, Libertadores, Sudamericana, Champions, LaLiga, Premier, Real Madrid, Barcelona, страницы матчей; время сразу по 8 странам (Argentina/Chile/Paraguay, Bolivia, Perú/Ecuador, México, España).
- Шаблоны title: клуб «{клуб} hoy: {A} vs {B} en vivo, hora y posiciones» / «Posiciones de {клуб}: cuándo juega, resultados y en vivo»; пара «{A} vs {B} en vivo hoy: hora, posiciones y pronóstico» / «{A} vs {B}: cómo quedó X-Y, resultado y posiciones»; классико — с названием («Superclásico: …»).
- 1xBet: ссылка сайта 6266915 (ad 97), SubID `gc_<geo>_<место>`, код GOCLARIVO; условия бонуса не пишем — ссылка на нашу reseña 1xBet страны. **Без партнёрских ссылок в Испании (DGOJ) и Чили (Subtel блокирует 1xBet с 01.09.2026)** — там только футбол.
- Живой счёт: Cloudflare Pages Function `functions/api/live.js` — **нужны переменные ONEXBET_CLIENT_ID, ONEXBET_CLIENT_SECRET, ONEXBET_REF в настройках проекта Cloudflare Pages (ставит Олег)**; без них страницы работают, просто без счёта. Устаревшие `/…/futbol/partido/…` → 302 на «partidos de hoy» (functions/…/partido/[[path]].js).
- Старые страницы GoClarivo (бонусы, бренды, гайды) не тронуты, URL те же. Добавлена одна строка-ссылка на раздел на `/<geo>/sports/`, `/<geo>/sports/futbol/` и страницах лиг (22 страницы).
- `sitemap-futbol.xml` + строка в robots.txt. После деплоя — отправить sitemap-futbol.xml в Search Console.
- Ключи Ahrefs по странам — ждём от Олега; названия клубов, пары и title подстроить под реальный спрос.
- Вторая фаза: en, gh, ke, zm (английский), bf (французский). India — не делать (Online Gaming Act 2025).
