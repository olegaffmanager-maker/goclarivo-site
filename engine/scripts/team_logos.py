"""Escudos de los clubes: descarga una sola vez cada logo que da la API de 1xBet (img1/img2 en matches.json),
lo recorta, lo centra en 64x64 PNG transparente y lo guarda en src/assets/t/. Mantiene data/logos.json
{nombre del equipo tal como viene de 1xBet: archivo}. Así el sitio sirve los escudos desde su propio dominio
(no depende del CDN de 1xBet) y un equipo sin partidos próximos conserva su escudo.
Env: DATA (carpeta con matches.json y logos.json, por defecto data), TDIR (carpeta de escudos, por defecto src/assets/t)."""
import hashlib, io, json, os, sys
import requests
from concurrent.futures import ThreadPoolExecutor
from PIL import Image

DATA = os.environ.get("DATA", "data")
TDIR = os.environ.get("TDIR", "src/assets/t")
SIZE = 64
os.makedirs(TDIR, exist_ok=True)
lp = os.path.join(DATA, "logos.json")
logos = json.load(open(lp)) if os.path.exists(lp) else {}
d = json.load(open(os.path.join(DATA, "matches.json")))
pairs = []
for g in d.get("groups", []):
    for m in g.get("matches", []):
        pairs += [(m.get("home"), m.get("img1")), (m.get("away"), m.get("img2"))]

# logo_seed.json: {nombre: url} recuperados del historial (equipos que ya no tienen partidos próximos)
sp = os.path.join(DATA, "logo_seed.json")
if os.path.exists(sp):
    pairs += list(json.load(open(sp)).items())

def fetch(item):
    name, url = item
    f = hashlib.md5(url.encode()).hexdigest()[:12] + ".png"
    p = os.path.join(TDIR, f)
    if os.path.exists(p):
        return name, f, False
    for attempt in range(2):
        try:
            r = requests.get(url, timeout=(5, 8))
            r.raise_for_status()
            im = Image.open(io.BytesIO(r.content)).convert("RGBA")
            bb = im.getchannel("A").getbbox()
            if bb:
                im = im.crop(bb)
            if im.width < 8 or im.height < 8:
                raise ValueError("too small")
            im.thumbnail((SIZE, SIZE), Image.LANCZOS)
            c = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
            c.paste(im, ((SIZE - im.width) // 2, (SIZE - im.height) // 2), im)
            c.quantize(colors=128, method=Image.FASTOCTREE).save(p, optimize=True)
            return name, f, True
        except Exception as e:
            err = e
    print("logo failed", name, err, file=sys.stderr)
    return name, None, False

todo = {}
for name, url in pairs:
    if name and url and url.startswith("https://") and name not in todo:
        todo[name] = url
new = fail = 0
with ThreadPoolExecutor(8) as ex:
    for name, f, fresh in ex.map(fetch, todo.items()):
        if f:
            logos[name] = f
            new += fresh
        else:
            fail += 1

json.dump(dict(sorted(logos.items())), open(lp, "w"), ensure_ascii=False, indent=0)
print(f"logos: {len(logos)} teams, {new} new, {fail} failed")
