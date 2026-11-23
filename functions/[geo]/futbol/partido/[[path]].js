// Partidos de un país que ya salieron de los datos: en vez de 404, 302 a «Partidos de hoy» de ese país.
export async function onRequest({ request, params, next }) {
  const res = await next();
  if (res.status !== 404 || !/^[a-z]{2}$/.test(params.geo)) return res;
  return Response.redirect(new URL(`/${params.geo}/futbol/partidos-de-hoy/`, request.url).toString(), 302);
}
