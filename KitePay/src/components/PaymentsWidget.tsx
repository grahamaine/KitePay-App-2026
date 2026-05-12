import { useAppKitAccount } from '@reown/appkit/react'

const MOCK_PAYMENTS = [
  { id: 1, name: 'CryptoFlow#010', time: '14 hours ago', amount: '+$320.00', type: 'in' },
  { id: 2, name: 'GDo', time: '2 days ago', amount: '-$100.00', type: 'out' },
  { id: 3, name: 'GDo', time: '4 days ago', amount: '-$76.50', type: 'out' },
  { id: 4, name: 'Secretary Freelance', time: '1 week ago', amount: '+$450.00', type: 'in' },
  { id: 5, name: 'KITE Transfer', time: '2 weeks ago', amount: '-$200.00', type: 'out' },
]

const initials = (name: string) => name.slice(0, 2).toUpperCase()
const avatarColor = (name: string) => {
  const colors = ['#00C2D4', '#F0B429', '#8B5CF6', '#22C55E', '#EF4444', '#3B82F6']
  return colors[name.charCodeAt(0) % colors.length]
}

export const PaymentsWidget = () => {
  const { isConnected } = useAppKitAccount()

  return (
    <div className="widget">
      <div className="widget__header">
        <h3 className="widget__title">Recent Payments</h3>
        <button className="btn-ghost">See all →</button>
      </div>
      <ul className="payments-list">
        {MOCK_PAYMENTS.map(p => (
          <li key={p.id} className="payment-item">
            <div
              className="payment-item__avatar"
              style={{ background: avatarColor(p.name) }}
            >
              {initials(p.name)}
            </div>
            <div className="payment-item__info">
              <span className="payment-item__name">{p.name}</span>
              <span className="payment-item__time">{p.time}</span>
            </div>
            <span className={`payment-item__amount payment-item__amount--${p.type}`}>
              {p.amount}
            </span>
          </li>
        ))}
      </ul>
      {!isConnected && (
        <p className="widget__hint">Connect wallet to see live transactions</p>
      )}
    </div>
  )
}
