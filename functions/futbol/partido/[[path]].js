// Partidos internacionales que ya salieron de los datos: en vez de 404, 302 a la portada de /futbol/.
export async function onRequest({ request, next }) {
  const res = await next();
  if (res.status !== 404) return res;
  return Response.redirect(new URL('/futbol/', request.url).toString(), 302);
}
