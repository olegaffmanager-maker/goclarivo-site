# GoClarivo — журнал изменений

Формат: дата — что изменили, почему. Сверять с графиками Search Console.

## 23.11.2026 — футбольный раздел на движке Liga Chapina / Liga Tica / Marcador Central (решение Олега: делать сейчас, без ожидания заморозки — у сайта почти ноль показов)

- Данные: `engine/scripts/odds.py` (1xBet Marketing API) для каждого гео + `int` (Libertadores, Sudamericana, Champions, LaLiga, Premier) → `engine/data/<geo>/`; эмблемы → `engine/assets/t`. Workflow `.github/workflows/engine.yml` каждые 3 часа (секреты ONEXBET_* в GitHub уже были).
- Страницы (первая фаза — испаноязычные гео ar, mx, cl, pe, ec, bo, py, es): `/<geo>/futbol/` — лига, partidos de hoy, posiciones (считаем из результатов 3/1/0, с пометкой «puede diferir de la oficial»), fixture, resultados, pronóstico (по коэффициентам, без «pronóstico seguro»), equipos, страницы клубов, пары клубов, сборная и «<страна> vs <соперник>», клубы страны в Libertadores/Sudamericana. Время — местное.
- `/futbol/` — международный раздел: en vivo, Libertadores, Sudamericana, Champions, LaLiga, Premier, Real Madrid, Barcelona, страницы матчей; время сразу по 8 странам (Argentina/Chile/Paraguay, Bolivia, Perú/Ecuador, México, España).
- Шаблоны title: клуб «{клуб} hoy: {A} vs {B} en vivo, hora y posiciones» / «Posiciones de {клуб}: cuándo juega, resultados y en vivo»; пара «{A} vs {B} en vivo hoy: hora, posiciones y pronóstico» / «{A} vs {B}: cómo quedó X-Y, resultado y posiciones»; классико — с названием («Superclásico: …»).
- 1xBet: ссылка сайта 6266915 (ad 97), SubID `gc_<geo>_<место>`, код GOCLARIVO; условия бонуса не пишем — ссылка на нашу reseña 1xBet страны. **Без партнёрских ссылок только в Испании (DGOJ)** — там только футбол. Чили — с 1xBet (решение Олега 23.11, несмотря на блокировку Subtel с 01.09.2026).
- Живой счёт: Cloudflare Pages Function `functions/api/live.js` — **нужны переменные ONEXBET_CLIENT_ID, ONEXBET_CLIENT_SECRET, ONEXBET_REF в настройках проекта Cloudflare Pages (ставит Олег)**; без них страницы работают, просто без счёта. Устаревшие `/…/futbol/partido/…` → 302 на «partidos de hoy» (functions/…/partido/[[path]].js).
- Старые страницы GoClarivo (бонусы, бренды, гайды) не тронуты, URL те же. Добавлена одна строка-ссылка на раздел на `/<geo>/sports/`, `/<geo>/sports/futbol/` и страницах лиг (22 страницы).
- `sitemap-futbol.xml` + строка в robots.txt. После деплоя — отправить sitemap-futbol.xml в Search Console.
- Ключи Ahrefs по странам — ждём от Олега; названия клубов, пары и title подстроить под реальный спрос.
- Вторая фаза: en, gh, ke, zm (английский), bf (французский). India — не делать (Online Gaming Act 2025).

### 23.11.2026, вечер — ключи Ahrefs и первая сборка на реальных данных
- Ahrefs (Matching terms по 13 странам, файлы в `engine/research/`): главный спрос — «posiciones de {клуб}» (boca 688K, real madrid 1.03M, liga mx 2.76M), «partidos de {клуб}» (boca 397K, colo-colo 157K), «partidos de hoy» (AR 555K, PE 350K), «{страна} vs» (MX 730K, EC 321K, AR 260K, PY 123K), «copa libertadores» / «posiciones de copa libertadores» (AR 254K/163K, CL 190K/79K), «tabla liga mx», «tabla liga 1».
- По ключам: названия клубов как ищут — Colo Colo, U de Chile, Chivas, Tigres, Pumas, Estudiantes, Betis; H1 клуба «{клуб} hoy: partidos, posiciones y en vivo»; страница таблицы «Posiciones de la {лига} {год}: tabla general del {турнир}».
- India: спрос — крикет, футбол мизерный + запрет (Online Gaming Act) → не делаем. Gh/Ke/Zm/Bf — объёмы малые (тысячи), вторая фаза.
- Сборка: 1558 страниц (AR 500, ES 224, MX 186, EC 161, CL 157, BO 154, PY 96, PE 15, /futbol/ 67), битых внутренних ссылок 0. Перу пока пустое: Liga 1 нет в линии 1xBet (межсезонье) → добавлен фиксированный tournamentId 2892390 для результатов, заполнится при следующем прогоне.
- Чили — с 1xBet (решение Олега).
- 23.11 19:14: Олег поставил ONEXBET_CLIENT_ID / ONEXBET_CLIENT_SECRET / ONEXBET_REF (Secret, Production) в Cloudflare Pages → деплой этим коммитом, чтобы /api/live их подхватил.
- 23.11 19:17: sitemap-futbol.xml отправлен в Search Console — «Успешно», 1758 URL. Живой счёт /api/live работает (estado ok); из лайва убраны виртуальные/киберфутбол.
- 23.11 19:25 (решение Олега «делай как нужно»): пункт «Fútbol hoy: partidos y posiciones» в меню «Apuestas deportivas» на всех страницах 8 испанских гео (369 страниц, только одна ссылка в шапке) + блок-ссылка на раздел на главной каждой страны (/<geo>/, после топ-листа). Виджет 1xBet на /<geo>/sports/: из фильтра убраны virtual / eComp / 5x5 / 4x4 / 2x2 / Short Football / LFL.
- 23.11 19:30 (решение Олега): старые футбольные страницы удалены — /<geo>/sports/futbol/ (8 исп. гео) и страницы лиг (/ar/sports/liga-profesional/, /mx/sports/liga-mx/, /cl/sports/primera-division/, /pe/sports/liga-1/, /ec/sports/ligapro/, /bo/sports/division-profesional/) → 301 на /<geo>/futbol/ (_redirects). Убраны из sitemap.xml (522→508), ссылки на них на всём сайте переведены на новый раздел (721 ссылка, 355 файлов), пункт меню «Fútbol» теперь ведёт в /<geo>/futbol/ (дубль «Fútbol hoy» убран). Виджет больше не пишет в удалённые страницы; /en/sports/football/ остаётся до английской фазы.

## 25.11.2026 — снятие дублей гайдов с индексации (после обрыва показов 12.11)
- Search Console: с 12.11 показы ~0 (до этого 200–250/день), страницы в индексе (site:), технически всё ок. Совпало с November 2026 core update (10–24.11). Ручные меры — проверяет Олег.
- Причина-кандидат: одинаковые гайды на 8 испанских и 5 английских гео (совпадение текста 90–98%) — «scaled content».
- Сделано: 24 кластера гайдов → по одной версии на язык в индексе (выбрана версия с наибольшими показами в GSC за 27.10–23.11; Индия не выбирается). Остальные 126 копий: `noindex, follow`, без hreflang, убраны из sitemap.xml (508 → 383). У оставленных hreflang только на оставленные версии (es / en / fr-BF + x-default). Страницы и ссылки на них не удалены — посетители из стран попадают на свои версии как раньше.
- Не трогали: гайды, которые реально отличаются по странам (Champions/LaLiga/Europa League, теннис, rollover x35, оплата, законы), обзоры брендов, футбольный раздел.
- Дальше: никаких массовых правок шаблонов/дат; смотреть Search Console 2–4 недели. Список: scratchpad dedupe.json → сохранён ниже в репозитории как `seo/dedupe-2026-11-25.json`.

## 28.11.2026 — убраны ссылки на Kavira (правило: без перекрёстных ссылок между нашими сайтами)
- 23 файла (ar, bo, cl, ec, mx, pe, py + es в гайдах): /about/ — абзац «Nuestro otro proyecto: Kavira…» удалён целиком; гайд rollover-en-apuestas-deportivas — предложение переписано без Kavira («Calcula cuánto vale realmente tu bono con tus propios números de rollover, cuota mínima y RTP antes de reclamarlo.»); гайд rollover-x35-que-significa — последнее предложение со ссылкой на калькулятор Kavira убрано. URL, структура и остальной текст без изменений. Поиск «kavira» по всему репо — пусто.
