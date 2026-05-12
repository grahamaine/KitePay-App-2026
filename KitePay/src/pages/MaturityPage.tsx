import { useState } from 'react'
import { useAppKitAccount } from '@reown/appkit/react'

const PLANS = [
  { id: 'flex', name: 'Flexible', apy: '8%', lock: 'No lock', min: '100 KITE', color: '#00C2D4' },
  { id: '30d', name: '30 Days', apy: '12.5%', lock: '30 days', min: '500 KITE', color: '#F0B429' },
  { id: '90d', name: '90 Days', apy: '18%', lock: '90 days', min: '1,000 KITE', color: '#8B5CF6' },
  { id: '1y', name: '1 Year', apy: '28%', lock: '365 days', min: '5,000 KITE', color: '#22C55E' },
]

export const MaturityPage = () => {
  const { isConnected } = useAppKitAccount()
  const [selectedPlan, setSelectedPlan] = useState('30d')
  const [stakeAmt, setStakeAmt] = useState('')

  const plan = PLANS.find(p => p.id === selectedPlan)!
  const estReward = stakeAmt && plan
    ? (parseFloat(stakeAmt) * parseFloat(plan.apy) / 100).toFixed(2)
    : ''

  return (
    <div className="page">
      <div className="page__header">
        <h2 className="page__title">◎ Maturity</h2>
        <p className="page__sub">Stake KITE and earn passive rewards</p>
      </div>

      {/* Stats row */}
      <div className="summary-row">
        <div className="summary-card">
          <span className="summary-card__label">Total Staked</span>
          <span className="summary-card__value">50,000 KITE</span>
        </div>
        <div className="summary-card summary-card--green">
          <span className="summary-card__label">Rewards Earned</span>
          <span className="summary-card__value">1,250 KITE</span>
        </div>
        <div className="summary-card">
          <span className="summary-card__label">Next Unlock</span>
          <span className="summary-card__value">14 days</span>
        </div>
      </div>

      {/* Plans */}
      <div className="widget">
        <div className="widget__header">
          <h3 className="widget__title">Staking Plans</h3>
        </div>
        <div className="plan-grid">
          {PLANS.map(p => (
            <button
              key={p.id}
              className={`plan-card ${selectedPlan === p.id ? 'plan-card--selected' : ''}`}
              style={{ '--plan-color': p.color } as React.CSSProperties}
              onClick={() => setSelectedPlan(p.id)}
            >
              <span className="plan-card__name">{p.name}</span>
              <span className="plan-card__apy" style={{ color: p.color }}>{p.apy}</span>
              <span className="plan-card__apy-label">APY</span>
              <span className="plan-card__lock">{p.lock}</span>
              <span className="plan-card__min">Min: {p.min}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Stake form */}
      <div className="widget">
        <div className="widget__header">
          <h3 className="widget__title">Stake KITE — {plan.name} ({plan.apy} APY)</h3>
        </div>
        <div className="modal__field">
          <label>Amount to Stake</label>
          <input className="input" type="number" placeholder={`Min ${plan.min}`} value={stakeAmt} onChange={e => setStakeAmt(e.target.value)} />
        </div>
        {estReward && (
          <div className="swap-info" style={{ marginTop: 12 }}>
            <span>Estimated Reward</span>
            <span style={{ color: '#22C55E' }}>+{estReward} KITE</span>
          </div>
        )}
        <div className="btn-row" style={{ marginTop: 16 }}>
          <button className="btn btn--primary" disabled={!isConnected || !stakeAmt}>
            {isConnected ? 'Stake Now' : 'Connect Wallet'}
          </button>
          <button className="btn btn--secondary" disabled={!isConnected}>Unstake</button>
          <button className="btn btn--secondary" disabled={!isConnected}>Claim Rewards</button>
        </div>
      </div>
    </div>
  )
}
