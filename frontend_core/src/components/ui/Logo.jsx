/**
 * Logo oficial de Surgir, servido localmente desde public/.
 */
export default function Logo({
  size = 44,
  wordmark = true,
  variant = 'dark',
  subtitle = 'CORE FINANCIERO',
}) {
  const height = Math.max(22, Math.round(size * 0.58))
  const width = Math.round(height * 5.05)
  const subColor = variant === 'light' ? 'rgba(255,255,255,.82)' : '#5f626b'

  return (
    <span className="brand-logo" style={{ display: 'inline-flex', alignItems: 'center', gap: 10 }}>
      <span className={variant === 'light' ? 'brand-logo__plate' : undefined}>
        <img
          src="/logo_surgir_red.svg"
          alt="Surgir Santander Microfinanzas"
          style={{ width, height, display: 'block' }}
        />
      </span>
      {wordmark && subtitle && (
        <span
          style={{
            fontSize: Math.max(9, Math.round(size * 0.21)),
            fontWeight: 700,
            color: subColor,
            letterSpacing: 0,
            lineHeight: 1.05,
          }}
        >
          {subtitle}
        </span>
      )}
    </span>
  )
}
