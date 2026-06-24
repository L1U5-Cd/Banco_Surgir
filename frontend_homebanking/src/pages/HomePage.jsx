import { useNavigate } from 'react-router-dom'
import {
  Wallet, CreditCard, Send, Receipt, FileText, FilePlus2,
  PiggyBank, ChevronRight, TrendingDown, TrendingUp,
} from 'lucide-react'
import { useHBAuth } from '../hooks/useHBAuth.js'
import { useCuentas } from '../hooks/useCuentas.js'
import { useCreditos, useSolicitudesCredito } from '../hooks/useCreditos.js'
import { simboloMoneda, toNumber } from '../utils/format.js'
import PageLayout from '../components/layout/PageLayout.jsx'
import ActionPanel from '../components/ui/ActionPanel.jsx'
import Card from '../components/ui/Card.jsx'
import Money from '../components/ui/Money.jsx'
import Badge from '../components/ui/Badge.jsx'
import Loader from '../components/ui/Loader.jsx'

export default function HomePage() {
  const { user } = useHBAuth()
  const navigate = useNavigate()
  const { cuentas, loading: lc } = useCuentas('ahorro')
  const { creditos, loading: lk } = useCreditos()
  const { solicitudes, loading: ls } = useSolicitudesCredito()

  const totalAhorro = cuentas.reduce((s, c) => s + toNumber(c.saldo), 0)
  const totalDeuda = creditos.reduce((s, c) => s + toNumber(c.pago_pendiente), 0)
  const solicitudesCliente = solicitudes.filter((s) =>
    s.pkcliente == null || Number(s.pkcliente) === Number(user?.pkcliente)
  )

  const acciones = [
    { icon: Send, label: 'Transferencias propias', to: '/operaciones/transferencia' },
    { icon: Receipt, label: 'Pago de crédito', to: '/operaciones/pago-credito' },
    { icon: FileText, label: 'Pago de servicios', to: '/operaciones/pago-servicios' },
    { icon: FilePlus2, label: 'Solicitar préstamo', to: '/creditos/solicitar' },
  ]

  return (
    <PageLayout aside={<ActionPanel title="Operaciones frecuentes" items={acciones} />}>
      {/* Saludo */}
      <div className="bbva-hello">
        <h1>Hola {primerNombre(user?.nombre)}, bienvenido a Financiera Surgir</h1>
        <p>Tu posición global de productos y movimientos está lista para gestionar.</p>
      </div>

      {/* KPIs */}
      <div className="bbva-kpis">
        <div className="bbva-kpi">
          <span className="bbva-kpi-ico" style={{ background: '#e2132b1a', color: 'var(--hb-red)' }}>
            <PiggyBank size={22} />
          </span>
          <div>
            <span className="bbva-kpi-label"><TrendingUp size={13} /> Total en ahorros</span>
            <Money className="bbva-kpi-val" value={totalAhorro} />
            <small>{cuentas.length} cuenta(s)</small>
          </div>
        </div>
        <div className="bbva-kpi">
          <span className="bbva-kpi-ico" style={{ background: '#00a9a51a', color: 'var(--hb-turquesa)' }}>
            <CreditCard size={22} />
          </span>
          <div>
            <span className="bbva-kpi-label"><TrendingDown size={13} /> Deuda total de créditos</span>
            <Money className="bbva-kpi-val" value={totalDeuda} />
            <small>{creditos.length} crédito(s)</small>
          </div>
        </div>
      </div>

      {/* Cuentas resumidas */}
      <Card title="Cuentas de Ahorro" icon={<Wallet size={18} />}
        actions={<button className="bbva-link" onClick={() => navigate('/cuentas/ahorro')}>Ver todas <ChevronRight size={14} /></button>}>
        {lc ? <Loader text="Cargando cuentas…" /> : cuentas.length === 0 ? (
          <p className="bbva-empty">No registra cuentas de ahorro.</p>
        ) : (
          <ul className="bbva-prodlist">
            {cuentas.map((c) => (
              <li key={c.codcuentaahorro} onClick={() => navigate(`/cuentas/ahorro/${c.codcuentaahorro}/movimientos`)}>
                <div className="bbva-prod-info">
                  <strong>{c.codcuentaahorro}</strong>
                  <small>{c.tipo} · <Badge estado={c.estado} /></small>
                </div>
                <div className="bbva-prod-amt">
                  <Money value={c.saldo} simbolo={simboloMoneda(c.moneda)} />
                  <ChevronRight size={16} />
                </div>
              </li>
            ))}
            <li className="bbva-prodlist-total">
              <span>Saldo disponible total</span>
              <Money value={totalAhorro} className="bbva-money-strong" />
            </li>
          </ul>
        )}
      </Card>

      {/* Créditos resumidos */}
      <Card title="Préstamos" icon={<CreditCard size={18} />}
        actions={<button className="bbva-link" onClick={() => navigate('/cuentas/credito')}>Ver todos <ChevronRight size={14} /></button>}>
        {lk ? <Loader text="Cargando créditos…" /> : creditos.length === 0 ? (
          <p className="bbva-empty">No registra créditos vigentes.</p>
        ) : (
          <ul className="bbva-prodlist">
            {creditos.map((c) => (
              <li key={c.codcuentacredito} onClick={() => navigate(`/cuentas/credito/${c.codcuentacredito}/cuotas`)}>
                <div className="bbva-prod-info">
                  <strong>{c.codcuentacredito}</strong>
                  <small>Consumo · <Badge estado={c.calificacion || 'Normal'} tone={c.dias_atraso > 0 ? 'red' : undefined} /></small>
                </div>
                <div className="bbva-prod-amt">
                  <Money value={c.pago_pendiente} />
                  <ChevronRight size={16} />
                </div>
              </li>
            ))}
            <li className="bbva-prodlist-total">
              <span>Saldo pendiente total</span>
              <Money value={totalDeuda} className="bbva-money-strong" />
            </li>
          </ul>
        )}
      </Card>
      <Card title={`Historial de prestamos de ${primerNombre(user?.nombre)}`} icon={<FileText size={18} />}
        actions={<button className="bbva-link" onClick={() => navigate('/creditos/solicitar')}>Nueva solicitud <ChevronRight size={14} /></button>}>
        {ls ? <Loader text="Cargando solicitudes..." /> : solicitudesCliente.length === 0 ? (
          <p className="bbva-empty">Aun no registra solicitudes de prestamo.</p>
        ) : (
          <ul className="bbva-prodlist">
            {solicitudesCliente.slice(0, 5).map((s) => {
              const montoAceptado = s.montoaprobado ?? s.monto_aprobado
              const montoBase = montoAceptado || s.montosolicitud
              return (
                <li key={s.codsolicitud}>
                  <div className="bbva-prod-info">
                    <strong>{s.codsolicitud}</strong>
                    <small>
                      {fechaCorta(s.fecha_solicitud)} - <Badge estado={s.estado || 'En evaluacion'} />
                    </small>
                  </div>
                  <div className="bbva-prod-amt">
                    <Money value={montoBase} />
                  </div>
                </li>
              )
            })}
          </ul>
        )}
      </Card>
    </PageLayout>
  )
}

function primerNombre(nombre) {
  if (!nombre) return 'Cliente'
  // El backend usa "Apellido, Nombre"; tomamos el nombre de pila si está.
  const parts = nombre.split(',')
  const np = (parts[1] || parts[0]).trim().split(/\s+/)[0]
  return np || 'Cliente'
}

function fechaCorta(fecha) {
  if (!fecha) return 'Sin fecha'
  return new Date(fecha).toLocaleDateString('es-PE', { day: '2-digit', month: '2-digit', year: 'numeric' })
}
