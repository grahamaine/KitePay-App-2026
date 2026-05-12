import { useAppKitAccount, useAppKitNetwork } from '@reown/appkit/react'

interface BalanceCardProps {
  nativeBalance: string
  kiteBalance: string
  onGetBalance: () => void
}

const sparkPoints = [40, 55, 45, 60, 50, 70, 58, 75, 62, 80, 68, 85, 72, 78, 82]
const toSvgPath = (pts: number[]) => {
  const w = 300, h = 60
  const min = Math.min(...pts), max = Math.max(...pts)
  const xs = pts.map((_, i) => (i / (pts.length - 1)) * w)
  const ys = pts.map(p => h - ((p - min) / (max - min)) * h)
  return xs.map((x, i) => `${i === 0 ? 'M' : 'L'}${x.toFixed(1)},${ys[i].toFixed(1)}`).join(' ')
}

export const BalanceCard = ({ nativeBalance, kiteBalance, onGetBalance }: BalanceCardProps) => {
  const { isConnected, address } = useAppKitAccount()
  const { chainId } = useAppKitNetwork()

  const onKite = [2368, 2366].includes(Number(chainId))
  const displayBalance = kiteBalance || nativeBalance || (isConnected ? '—' : '0.00')
  const displayLabel = kiteBalance ? 'KITE' : onKite ? 'KITE' : 'ETH'
  const short = address ? `${address.slice(0, 6)}...${address.slice(-4)}` : ''

  return (
    <div className="balance-card">
      <div className="balance-card__top">
        <div>
          <p className="balance-card__label">Total Balance</p>
          <h2 className="balance-card__amount">{displayBalance}</h2>
          <span className="balance-card__unit">{displayLabel}</span>
        </div>
        <div className="balance-card__badge">
          <span className={`network-dot ${onKite ? 'network-dot--live' : ''}`} />
          {onKite ? 'Kite Chain' : chainId ? `Chain ${chainId}` : 'Not connected'}
        </div>
      </div>

      {/* Sparkline */}
      <div className="balance-card__chart">
        <svg viewBox="0 0 300 60" preserveAspectRatio="none" className="sparkline">
          <defs>
            <linearGradient id="sparkGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#00C2D4" stopOpacity="0.3" />
              <stop offset="100%" stopColor="#00C2D4" stopOpacity="0" />
            </linearGradient>
          </defs>
          <path d={`${toSvgPath(sparkPoints)} L300,60 L0,60 Z`} fill="url(#sparkGrad)" />
          <path d={toSvgPath(sparkPoints)} fill="none" stroke="#00C2D4" strokeWidth="2" strokeLinecap="round" />
        </svg>
      </div>

      {isConnected && (
        <div className="balance-card__footer">
          <span className="balance-card__address">{short}</span>
          <button className="btn-ghost" onClick={onGetBalance}>Refresh ↺</button>
        </div>
      )}
    </div>
  )
}
