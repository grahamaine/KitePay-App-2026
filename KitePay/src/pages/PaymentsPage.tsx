import { useState } from 'react'
import { useAppKitAccount } from '@reown/appkit/react'

const ALL_PAYMENTS = [
  { id: 1, name: 'CryptoFlow#010', time: '14 hours ago', amount: '+320.00', type: 'in', token: 'KITE', status: 'completed' },
  { id: 2, name: 'GDo', time: '2 days ago', amount: '-100.00', type: 'out', token: 'KITE', status: 'completed' },
  { id: 3, name: 'GDo', time: '4 days ago', amount: '-76.50', type: 'out', token: 'ETH', status: 'completed' },
  { id: 4, name: 'Secretary Freelance', time: '1 week ago', amount: '+450.00', type: 'in', token: 'KITE', status: 'completed' },
  { id: 5, name: 'KITE Transfer', time: '2 weeks ago', amount: '-200.00', type: 'out', token: 'KITE', status: 'completed' },
  { id: 6, name: 'Market Reward', time: '2 weeks ago', amount: '+50.00', type: 'in', token: 'KITE', status: 'completed' },
  { id: 7, name: 'Vault Unstake', time: '3 weeks ago', amount: '+1250.00', type: 'in', token: 'KITE', status: 'completed' },
  { id: 8, name: 'Gas Fee', time: '3 weeks ago', amount: '-0.003', type: 'out', token: 'ETH', status: 'pending' },
]

const avatarColor = (name: string) => {
  const colors = ['#00C2D4', '#F0B429', '#8B5CF6', '#22C55E', '#EF4444', '#3B82F6']
  return colors[name.charCodeAt(0) % colors.length]
}

type Filter = 'all' | 'in' | 'out'

export const PaymentsPage = () => {
  const { isConnected } = useAppKitAccount()
  const [filter, setFilter] = useState<Filter>('all')
  const [search, setSearch] = useState('')

  const filtered = ALL_PAYMENTS.filter(p => {
    const matchFilter = filter === 'all' || p.type === filter
    const matchSearch = p.name.toLowerCase().includes(search.toLowerCase())
    return matchFilter && matchSearch
  })

  const totalIn = ALL_PAYMENTS.filter(p => p.type === 'in').reduce((s, p) => s + parseFloat(p.amount), 0)
  const totalOut = ALL_PAYMENTS.filter(p => p.type === 'out').reduce((s, p) => s + parseFloat(p.amount), 0)

  return (
    <div className="page">
      <div className="page__header">
        <h2 className="page__title">Payments</h2>
        <p className="page__sub">Your full transaction history</p>
      </div>

      {/* Summary cards */}
      <div className="summary-row">
        <div className="summary-card summary-card--green">
          <span className="summary-card__label">Total Received</span>
          <span className="summary-card__value">+{totalIn.toFixed(2)} KITE</span>
        </div>
        <div className="summary-card summary-card--red">
          <span className="summary-card__label">Total Sent</span>
          <span className="summary-card__value">{totalOut.toFixed(2)} KITE</span>
        </div>
        <div className="summary-card">
          <span className="summary-card__label">Transactions</span>
          <span className="summary-card__value">{ALL_PAYMENTS.length}</span>
        </div>
      </div>

      {/* Filters */}
      <div className="filter-bar">
        <input
          className="input input--sm"
          placeholder="Search payments..."
          value={search}
          onChange={e => setSearch(e.target.value)}
        />
        <div className="filter-tabs">
          {(['all', 'in', 'out'] as Filter[]).map(f => (
            <button
              key={f}
              className={`filter-tab ${filter === f ? 'filter-tab--active' : ''}`}
              onClick={() => setFilter(f)}
            >
              {f === 'all' ? 'All' : f === 'in' ? '↓ Received' : '↑ Sent'}
            </button>
          ))}
        </div>
      </div>

      {/* Payments table */}
      <div className="widget">
        <ul className="payments-list">
          {filtered.map(p => (
            <li key={p.id} className="payment-item">
              <div className="payment-item__avatar" style={{ background: avatarColor(p.name) }}>
                {p.name.slice(0, 2).toUpperCase()}
              </div>
              <div className="payment-item__info">
                <span className="payment-item__name">{p.name}</span>
                <span className="payment-item__time">{p.time}</span>
              </div>
              <span className="payment-item__token">{p.token}</span>
              <span className={`status-badge status-badge--${p.status}`}>{p.status}</span>
              <span className={`payment-item__amount payment-item__amount--${p.type}`}>
                {p.type === 'in' ? '+' : ''}{p.amount}
              </span>
            </li>
          ))}
          {filtered.length === 0 && (
            <li className="empty-state">No payments found</li>
          )}
        </ul>
      </div>

      {!isConnected && (
        <div className="connect-prompt">
          <p>Connect your wallet to see live payment history</p>
        </div>
      )}
    </div>
  )
}
