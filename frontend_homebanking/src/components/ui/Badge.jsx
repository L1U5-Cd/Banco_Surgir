// Badge de estado. Colorea automaticamente segun el texto del estado.
export default function Badge({ estado, tone }) {
  const text = estado ?? '-'
  const variant = tone || toneFor(text)
  return <span className={`hb-badge hb-badge-${variant}`}>{text}</span>
}

function toneFor(estado) {
  const e = String(estado).toLowerCase()
  if (/(activa|activo|normal|vigente|aprob|desembols|al d.a|pagad)/.test(e)) return 'green'
  if (/(rechaz|deneg|bloque|cancelad|inactiv|cerrad|castig|mora|vencid|atras)/.test(e)) return 'red'
  if (/(evaluaci|pendiente|proceso|revisi|comit)/.test(e)) return 'amber'
  return 'gray'
}
