import { useAppKitAccount, useAppKitNetwork } from '@reown/appkit/react'

const PORTFOLIO = [
  { token: 'KITE', amount: '50,000', value: '$2,500', pct: 65, color: '#00C2D4' },
  { token: 'ETH', amount: '0.42', value: '$1,260', pct: 22, color: '#627EEA' },
  { token: 'USDC', amount: '500', value: '$500', pct: 10, color: '#2775CA' },
  { token: 'Other', amount: '—', value: '$115', pct: 3, color: '#6B7280' },
]

const ACTIVITY = [
  { label: 'KITE sent to GDo', time: '2d ago', icon: '↑' },
  { label: 'Staking reward claimed', time: '5d ago', icon: '✨' },
  { label: 'Swapped ETH → KITE', time: '1w ago', icon: '⇅' },
  { label: 'Wallet created', time: '3w ago', icon: '🔑' },
]

export const TriellaPage = () => {
  const { address, isConnected } = useAppKitAccount()
  const { chainId } = useAppKitNetwork()
  const onKite = [2368, 2366].includes(Number(chainId))

  return (
    <div className="page">
      <div className="page__header">
        <h2 className="page__title">◇ Triella</h2>
        <p className="page__sub">Portfolio overview and analytics</p>
      </div>

      {/* Net worth */}
      <div className="widget" style={{ background: 'linear-gradient(135deg, #1A2A50, #0D1B35)', border: '1px solid rgba(0,194,212,0.2)' }}>
        <p style={{ color: '#9CA3AF', fontSize: 13, marginBottom: 6 }}>Total Portfolio Value</p>
        <h2 style={{ fontSize: 36, fontWeight: 800, letterSpacing: -1 }}>$4,375.00</h2>
        <span style={{ color: '#22C55E', fontSize: 14, fontWeight: 600 }}>▲ +4.62% today</span>
      </div>

      <div className="degens-grid">
        {/* Allocation */}
        <div className="widget">
          <div className="widget__header">
            <h3 className="widget__title">Allocation</h3>
          </div>
          {/* Stacked bar */}
          <div className="alloc-bar">
            {PORTFOLIO.map(p => (
              <div key={p.token} className="alloc-bar__segment" style={{ width: `${p.pct}%`, background: p.color }} title={`${p.token} ${p.pct}%`} />
            ))}
          </div>
          <ul className="alloc-list">
            {PORTFOLIO.map(p => (
              <li key={p.token} className="alloc-item">
                <span className="alloc-item__dot" style={{ background: p.color }} />
                <span className="alloc-item__token">{p.token}</span>
                <span className="alloc-item__amount">{p.amount}</span>
                <span className="alloc-item__value">{p.value}</span>
                <span className="alloc-item__pct">{p.pct}%</span>
              </li>
            ))}
          </ul>
        </div>

        {/* Recent activity */}
        <div className="widget">
          <div className="widget__header">
            <h3 className="widget__title">Activity</h3>
          </div>
          <ul className="activity-list">
            {ACTIVITY.map((a, i) => (
              <li key={i} className="activity-item">
                <span className="activity-item__icon">{a.icon}</span>
                <div className="activity-item__info">
                  <p className="activity-item__label">{a.label}</p>
                  <p className="activity-item__time">{a.time}</p>
                </div>
              </li>
            ))}
          </ul>

          {/* Network info */}
          <div style={{ marginTop: 20, paddingTop: 16, borderTop: '1px solid rgba(255,255,255,0.06)' }}>
            <p style={{ fontSize: 12, color: '#4B5563', marginBottom: 8 }}>NETWORK</p>
            <p style={{ fontSize: 13, color: '#9CA3AF' }}>
              Chain ID: <strong style={{ color: '#fff' }}>{chainId ?? '—'}</strong>
              {onKite && <span style={{ marginLeft: 8, color: '#22C55E', fontSize: 11 }}>● Kite Chain</span>}
            </p>
            {address && <p style={{ fontSize: 11, fontFamily: 'monospace', color: '#4B5563', marginTop: 4 }}>{address}</p>}
          </div>
        </div>
      </div>
    </div>
  )
}
