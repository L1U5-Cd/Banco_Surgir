import { useState } from 'react'
import { ShieldCheck, User, Lock, LogIn } from 'lucide-react'
import Logo from '../components/ui/Logo.jsx'
import Carrusel from '../components/ui/Carrusel.jsx'
import { useAuth } from '../hooks/useAuth.js'
import '../styles/home.css'

/* ───────── Fondos SVG de las diapositivas ───────── */

const chips = (arr) => (
  <div className="carrusel__chips">
    {arr.map((v) => (
      <span className="carrusel__chip" key={v}>
        {v}
      </span>
    ))}
  </div>
)

// Ilustración de elementos financieros usada como decoración del login.
const Flor = ({ className }) => (
  <svg className={className} viewBox="0 0 220 220" aria-hidden="true">
    <defs>
      <linearGradient id="g-deco" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stopColor="#e2132b" />
        <stop offset="1" stopColor="#00a9a5" />
      </linearGradient>
    </defs>
    <rect x="12" y="30" width="92" height="56" rx="18" fill="#ffffff" opacity="0.18" />
    <rect x="26" y="44" width="52" height="24" rx="12" fill="#e2132b" />
    <circle cx="60" cy="60" r="10" fill="#fbc02d" />
    <path d="M18 112 h86 a12 12 0 0 1 12 12 v46 a12 12 0 0 1 -12 12 h-86 a12 12 0 0 1 -12 -12 v-46 a12 12 0 0 1 12 -12 z" fill="#ffffff" opacity="0.12" />
    <rect x="36" y="140" width="16" height="24" rx="6" fill="#00a9a5" />
    <rect x="62" y="128" width="16" height="36" rx="6" fill="#8e24aa" />
    <rect x="88" y="118" width="16" height="46" rx="6" fill="#f7941e" />
    <path d="M34 132 l24 -24 l24 18 l18 -18" fill="none" stroke="#ffffff" strokeWidth="10" strokeLinecap="round" strokeLinejoin="round" opacity="0.9" />
    <circle cx="165" cy="65" r="30" fill="url(#g-deco)" opacity="0.16" />
    <circle cx="165" cy="65" r="16" fill="#ffffff" />
    <path d="M157 58 h16 v14" fill="none" stroke="#ffffff" strokeWidth="6" strokeLinecap="round" />
    <path d="M159 68 h12" fill="none" stroke="#ffffff" strokeWidth="6" strokeLinecap="round" opacity="0.7" />
  </svg>
)

// Mensaje del día — destellos
const SvgMensaje = (
  <svg className="carrusel__svg" viewBox="0 0 1000 640" preserveAspectRatio="xMidYMid slice">
    <defs>
      <linearGradient id="g-msg" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stopColor="#e6398b" />
        <stop offset="1" stopColor="#e2132b" />
      </linearGradient>
    </defs>
    <rect width="1000" height="640" fill="url(#g-msg)" />
    <circle cx="840" cy="150" r="175" fill="#ffffff" opacity="0.07" />
    <circle cx="900" cy="560" r="120" fill="#ffffff" opacity="0.06" />
    <g transform="translate(660,250)" fill="#ffffff" opacity="0.95">
      <path d="M120 0 C134 70 170 106 240 120 C170 134 134 170 120 240 C106 170 70 134 0 120 C70 106 106 70 120 0 Z" />
      <path d="M250 160 c6 28 22 44 50 50 c-28 6 -44 22 -50 50 c-6 -28 -22 -44 -50 -50 c28 -6 44 -22 50 -50 Z" opacity="0.8" />
    </g>
  </svg>
)

// Misión — diana
const SvgMision = (
  <svg className="carrusel__svg" viewBox="0 0 1000 640" preserveAspectRatio="xMidYMid slice">
    <defs>
      <linearGradient id="g-mis" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stopColor="#e2132b" />
        <stop offset="1" stopColor="#f7941e" />
      </linearGradient>
    </defs>
    <rect width="1000" height="640" fill="url(#g-mis)" />
    <circle cx="840" cy="150" r="170" fill="#ffffff" opacity="0.07" />
    <g transform="translate(650,200)">
      <circle cx="130" cy="130" r="125" fill="none" stroke="#ffffff" strokeWidth="16" opacity="0.92" />
      <circle cx="130" cy="130" r="80" fill="none" stroke="#ffffff" strokeWidth="16" opacity="0.85" />
      <circle cx="130" cy="130" r="34" fill="#ffffff" />
      <path d="M-10 290 L150 130" stroke="#ffe08a" strokeWidth="14" strokeLinecap="round" />
      <path d="M120 130 h34 v34" fill="none" stroke="#ffe08a" strokeWidth="14" strokeLinecap="round" strokeLinejoin="round" />
    </g>
  </svg>
)

// Visión — ojo
const SvgVision = (
  <svg className="carrusel__svg" viewBox="0 0 1000 640" preserveAspectRatio="xMidYMid slice">
    <defs>
      <linearGradient id="g-vis" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stopColor="#00a9a5" />
        <stop offset="1" stopColor="#0d3b66" />
      </linearGradient>
    </defs>
    <rect width="1000" height="640" fill="url(#g-vis)" />
    <circle cx="850" cy="540" r="150" fill="#ffffff" opacity="0.06" />
    <g transform="translate(620,230)">
      <path d="M0 90 C90 -12 270 -12 360 90 C270 192 90 192 0 90 Z" fill="#ffffff" opacity="0.96" />
      <circle cx="180" cy="90" r="54" fill="#0d3b66" />
      <circle cx="180" cy="90" r="26" fill="#00a9a5" />
      <circle cx="198" cy="74" r="9" fill="#ffffff" />
    </g>
  </svg>
)

// Valores — gema
const SvgValores = (
  <svg className="carrusel__svg" viewBox="0 0 1000 640" preserveAspectRatio="xMidYMid slice">
    <defs>
      <linearGradient id="g-val" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stopColor="#8e24aa" />
        <stop offset="1" stopColor="#e6398b" />
      </linearGradient>
    </defs>
    <rect width="1000" height="640" fill="url(#g-val)" />
    <circle cx="840" cy="150" r="170" fill="#ffffff" opacity="0.07" />
    <g transform="translate(660,210)" fill="#ffffff">
      <path d="M40 60 H200 L230 120 L120 250 L10 120 Z" opacity="0.96" />
      <path d="M40 60 L70 120 H10 Z" opacity="0.6" />
      <path d="M200 60 L170 120 H230 Z" opacity="0.6" />
      <path d="M70 120 H170 L120 250 Z" opacity="0.75" />
    </g>
  </svg>
)

const SvgLavado = (
  <svg className="carrusel__svg" viewBox="0 0 1000 640" preserveAspectRatio="xMidYMid slice">
    <defs>
      <linearGradient id="g-lav" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stopColor="#0d3b66" />
        <stop offset="1" stopColor="#00a9a5" />
      </linearGradient>
    </defs>
    <rect width="1000" height="640" fill="url(#g-lav)" />
    <circle cx="800" cy="120" r="150" fill="#ffffff" opacity="0.07" />
    <g transform="translate(700,360)">
      <path d="M85 0 L160 30 V96 C160 150 128 176 85 192 C42 176 10 150 10 96 V30 Z" fill="#ffffff" opacity="0.96" />
      <path d="M52 98 l24 24 l44 -56" fill="none" stroke="#00a9a5" strokeWidth="13" strokeLinecap="round" strokeLinejoin="round" />
    </g>
  </svg>
)

const SvgPadre = (
  <svg className="carrusel__svg" viewBox="0 0 1000 640" preserveAspectRatio="xMidYMid slice">
    <defs>
      <linearGradient id="g-pad" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stopColor="#8e24aa" />
        <stop offset="0.55" stopColor="#e2132b" />
        <stop offset="1" stopColor="#f7941e" />
      </linearGradient>
    </defs>
    <rect width="1000" height="640" fill="url(#g-pad)" />
    <circle cx="820" cy="130" r="150" fill="#ffffff" opacity="0.08" />
    <g transform="translate(700,360)">
      <rect x="10" y="70" width="170" height="120" rx="10" fill="#ffffff" opacity="0.96" />
      <rect x="80" y="70" width="30" height="120" fill="#f7941e" />
      <rect x="-4" y="48" width="198" height="34" rx="8" fill="#ffffff" />
      <rect x="80" y="48" width="30" height="34" fill="#f7941e" />
      <circle cx="78" cy="40" r="20" fill="none" stroke="#ffffff" strokeWidth="12" />
      <circle cx="112" cy="40" r="20" fill="none" stroke="#ffffff" strokeWidth="12" />
    </g>
  </svg>
)

const SvgBandera = (
  <svg className="carrusel__svg" viewBox="0 0 1000 640" preserveAspectRatio="xMidYMid slice">
    <defs>
      <linearGradient id="g-ban" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stopColor="#7a0d18" />
        <stop offset="1" stopColor="#b50f22" />
      </linearGradient>
    </defs>
    <rect width="1000" height="640" fill="url(#g-ban)" />
    <circle cx="850" cy="520" r="140" fill="#ffffff" opacity="0.06" />
    <g transform="translate(700,250)">
      <rect x="0" y="0" width="10" height="230" rx="5" fill="#ffe08a" />
      <circle cx="5" cy="0" r="9" fill="#ffe08a" />
      <path d="M10 14 h70 v120 h-70 Z" fill="#e2132b" />
      <path d="M80 14 h70 v120 h-70 Z" fill="#ffffff" />
      <path d="M150 14 h70 v120 h-70 Z" fill="#e2132b" />
    </g>
  </svg>
)

const SvgMetas = (
  <svg className="carrusel__svg" viewBox="0 0 1000 640" preserveAspectRatio="xMidYMid slice">
    <defs>
      <linearGradient id="g-met" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stopColor="#1d7874" />
        <stop offset="1" stopColor="#4caf50" />
      </linearGradient>
    </defs>
    <rect width="1000" height="640" fill="url(#g-met)" />
    <circle cx="800" cy="130" r="150" fill="#ffffff" opacity="0.07" />
    <g transform="translate(700,360)">
      <rect x="0" y="80" width="40" height="80" rx="6" fill="#ffffff" opacity="0.85" />
      <rect x="60" y="50" width="40" height="110" rx="6" fill="#ffffff" opacity="0.9" />
      <rect x="120" y="20" width="40" height="140" rx="6" fill="#ffffff" opacity="0.96" />
      <path d="M10 70 L80 40 L140 12" fill="none" stroke="#ffe08a" strokeWidth="8" strokeLinecap="round" />
      <path d="M120 12 h26 v26" fill="none" stroke="#ffe08a" strokeWidth="8" strokeLinecap="round" strokeLinejoin="round" />
    </g>
  </svg>
)

const FRASES_DIA = [
  'El mejor servicio empieza con una sonrisa. ¡Hagamos crecer al Perú emprendedor!',
  'Cada crédito bien evaluado es un sueño que despega. ¡Excelente semana!',
  'Tu cercanía con el cliente es nuestra mayor fortaleza. ¡A por las metas!',
  'Disciplina y constancia: así se construye una cartera sana.',
  'Hoy es un gran día para superar tus objetivos. ¡Vamos con todo!',
  'Trabajo en equipo: juntos llegamos más lejos. ¡Gracias por tu compromiso!',
  'Cierra la semana con orgullo: tu esfuerzo transforma vidas.',
]
const fraseDelDia = FRASES_DIA[new Date().getDay()]

const VALORES = ['Integridad', 'Compromiso', 'Trabajo en equipo', 'Innovación', 'Cercanía', 'Responsabilidad']

const SLIDES = [
  {
    badge: 'Mensaje del día',
    titulo: 'Hoy es un buen día para crecer',
    subtitulo: fraseDelDia,
    svg: SvgMensaje,
  },
  {
    badge: 'Nuestra oferta',
    titulo: 'Microfinanzas digitales para emprendedores',
    subtitulo:
      'Cuentas y créditos diseñados para apoyar tu negocio con condiciones responsables y servicio digital.',
    svg: SvgPadre,
    extra: chips(['Cuenta de ahorro', 'Crédito consumo', 'Crédito microempresa', 'Tarjeta débito']),
  },
  {
    badge: 'Seguridad',
    titulo: 'Operaciones protegidas 24/7',
    subtitulo:
      'Tus transacciones y datos están protegidos con cifrado, cumplimiento SBS y monitoreo permanente.',
    svg: SvgLavado,
  },
  {
    badge: 'Crecimiento',
    titulo: 'Asesoría cercana para tu negocio',
    subtitulo:
      'Canales digitales y expertos que acompañan el crecimiento de las micro y pequeñas empresas.',
    svg: SvgVision,
    extra: chips(['Soporte 24/7', 'Asesoría Pyme', 'Gestión en línea', 'Evaluación ágil']),
  },
  {
    badge: 'Valores',
    titulo: 'Principios de Financiera Surgir',
    subtitulo: 'Integridad, compromiso, innovación y cercanía en cada decisión.',
    svg: SvgValores,
    extra: chips(VALORES),
  },
]

export default function HomePage() {
  const { loading, error, iniciarSesion } = useAuth()

  const [dni, setDni] = useState('')
  const [password, setPassword] = useState('')
  const [recordar, setRecordar] = useState(true)
  const [olvido, setOlvido] = useState(false)

  function submit(e) {
    e.preventDefault()
    iniciarSesion(dni.trim(), password)
  }

  return (
    <div className="home">
      <header className="home-header">
        <div className="home-header__brand">
          <Logo size={56} subtitle="CORE FINANCIERO" />
        </div>
        <span className="home-header__chip">Sistema interno · Uso exclusivo del personal</span>
      </header>

      <div className="home-split">
        {/* ───────── Izquierda: carrusel a pantalla completa ───────── */}
        <div className="split-info">
          <Carrusel slides={SLIDES} intervalo={6000} fill />
        </div>

        {/* ───────── Derecha: login ───────── */}
        <aside className="split-login">
          <Flor className="split-login__flor split-login__flor--1" />
          <Flor className="split-login__flor split-login__flor--2" />
          <div className="split-login__inner">
            <span className="split-login__secure">
              <ShieldCheck size={14} strokeWidth={2.6} /> Conexión segura
            </span>
            <h2>Inicia sesión</h2>
            <p className="split-login__sub">Acceso del personal · ingresa con tu DNI.</p>

            <form onSubmit={submit}>
              <div className="lp-field">
                <label htmlFor="dni">Número de DNI</label>
                <div className="lp-input">
                  <User className="lp-input__icon" size={18} />
                  <input
                    id="dni"
                    type="text"
                    value={dni}
                    onChange={(e) => setDni(e.target.value)}
                    placeholder="Ej. 12345678"
                    autoComplete="username"
                    required
                  />
                </div>
              </div>
              <div className="lp-field">
                <label htmlFor="pwd">Contraseña</label>
                <div className="lp-input">
                  <Lock className="lp-input__icon" size={18} />
                  <input
                    id="pwd"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="(en desarrollo: tu DNI)"
                    autoComplete="current-password"
                    required
                  />
                </div>
              </div>

              <div className="lp-row">
                <label>
                  <input type="checkbox" checked={recordar} onChange={(e) => setRecordar(e.target.checked)} />
                  Recordarme
                </label>
                <button type="button" className="lp-link" onClick={() => setOlvido((v) => !v)}>
                  ¿Olvidó su contraseña?
                </button>
              </div>

              {olvido && (
                <div className="lp-hint">
                  Contacta al administrador de tu agencia para restablecer tu contraseña.
                </div>
              )}
              {error && <div className="lp-error">{error}</div>}

              <button className="btn-login" type="submit" disabled={loading}>
                <LogIn size={18} strokeWidth={2.4} />
                {loading ? 'Ingresando…' : 'Iniciar sesión'}
              </button>
            </form>
          </div>
        </aside>
      </div>

      <div className="home-footer-line" />
      <footer className="home-footer-bar">
        <span>© 2026 Financiera Surgir · Core Financiero — Sistema interno</span>
        <span>
          <a href="#terminos">Términos</a> · <a href="#privacidad">Privacidad</a> ·{' '}
          <a href="#soporte">Soporte</a>
        </span>
      </footer>
    </div>
  )
}
