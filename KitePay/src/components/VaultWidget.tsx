import { useState } from 'react'
import { useAppKitAccount } from '@reown/appkit/react'

const VAULT_ITEMS = [
  { label: 'KITE Staked', value: '50,000 KITE', icon: '🔒', color: '#8B5CF6' },
  { label: 'Rewards Earned', value: '1,250 KITE', icon: '✨', color: '#F0B429' },
  { label: 'APY', value: '12.5%', icon: '📈', color: '#22C55E' },
]

interface VaultWidgetProps { onClose: () => void }

export const VaultWidget = ({ onClose }: VaultWidgetProps) => {
  const { isConnected } = useAppKitAccount()
  const [stakeAmt, setStakeAmt] = useState('')

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal modal--wide" onClick={e => e.stopPropagation()}>
        <div className="modal__header">
          <h2 className="modal__title">🔒 Vault</h2>
          <button className="modal__close" onClick={onClose}>✕</button>
        </div>

        <div className="vault-stats">
          {VAULT_ITEMS.map(v => (
            <div className="vault-stat" key={v.label}>
              <span className="vault-stat__icon" style={{ color: v.color }}>{v.icon}</span>
              <span className="vault-stat__label">{v.label}</span>
              <span className="vault-stat__value" style={{ color: v.color }}>{v.value}</span>
            </div>
          ))}
        </div>

        {isConnected ? (
          <>
            <div className="modal__field">
              <label>Stake Amount (KITE)</label>
              <input className="input" type="number" placeholder="0.00" value={stakeAmt} onChange={e => setStakeAmt(e.target.value)} />
            </div>
            <div className="btn-row">
              <button className="btn btn--primary" disabled={!stakeAmt}>Stake KITE</button>
              <button className="btn btn--secondary">Unstake</button>
            </div>
            <p className="modal__hint">Staking locks KITE for 30 days. Early withdrawal incurs a 2% fee.</p>
          </>
        ) : (
          <p className="modal__hint">Connect wallet to access Vault</p>
        )}
      </div>
    </div>
  )
}
