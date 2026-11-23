// Construye la sección de fútbol de GoClarivo: un proceso por país (RG=ar|mx|…) y al final RG=root (/futbol/, sitemap, búsqueda).
// Escribe en engine/dist y después copia a la raíz del repo solo lo suyo: /futbol/, /<geo>/futbol/ y /sitemap-futbol.xml.
// engine/out.txt lista esas rutas (el workflow las agrega al commit). El resto de GoClarivo no se toca.
const { execFileSync } = require('child_process');
const fs = require('fs'), path = require('path');
const ENG = path.join(__dirname, '..'), REPO = path.join(ENG, '..'), OUT = path.join(ENG, 'dist');
const CK = Object.keys(require('./countries.js'));
fs.rmSync(OUT, { recursive: true, force: true });
for (const rg of [...CK, 'root']) execFileSync(process.execPath, [path.join(__dirname, 'build.js')], { stdio: 'inherit', env: { ...process.env, RG: rg } });
const mine = ['futbol', ...CK.map((k) => `${k}/futbol`), 'sitemap-futbol.xml'];
for (const m of mine) {
  const dst = path.join(REPO, m), src = path.join(OUT, m);
  fs.rmSync(dst, { recursive: true, force: true });
  if (fs.existsSync(src)) fs.cpSync(src, dst, { recursive: true });
}
fs.writeFileSync(path.join(ENG, 'out.txt'), mine.join('\n') + '\n');
fs.rmSync(OUT, { recursive: true, force: true });
console.log('copied:', mine.join(' '));
