import { useState } from 'react'
import { useAppKitNetwork, useAppKitAccount, useAppKitProvider } from '@reown/appkit/react'
import { Contract, BrowserProvider, formatUnits } from 'ethers'
import type { Provider } from '@reown/appkit/react'

const KITE_TOKEN_ADDRESS = import.meta.env.VITE_KITE_TOKEN_ADDRESS || ''
const KITE_ABI = [
  { inputs: [{ internalType: 'address', name: 'account', type: 'address' }], name: 'balanceOf', outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }], stateMutability: 'view', type: 'function' },
  { inputs: [], name: 'totalSupply', outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }], stateMutability: 'view', type: 'function' },
]

const KITE_CURRENCIES = [
  { symbol: 'KITE', name: 'KitePay', change: '+4.62%', positive: true },
  { symbol: 'ETH', name: 'Ethereum', change: '+1.05%', positive: true },
  { symbol: 'USDC', name: 'USD Coin', change: '+0.01%', positive: true },
  { symbol: 'UQT', name: 'UQ Token', change: '-1.20%', positive: false },
]

interface TokenWidgetProps {
  onKiteBalance?: (b: string) => void
}

export const TokenWidget = ({ onKiteBalance }: TokenWidgetProps) => {
  const { address, isConnected } = useAppKitAccount()
  const { chainId } = useAppKitNetwork()
  const { walletProvider } = useAppKitProvider<Provider>('eip155')
  const [kiteBalance, setKiteBalance] = useState('')
  const [totalSupply, setTotalSupply] = useState('')
  const [loading, setLoading] = useState(false)

  const onKite = [2368, 2366].includes(Number(chainId))

  const fetchBalance = async () => {
    if (!address || !walletProvider || !KITE_TOKEN_ADDRESS) return
    setLoading(true)
    try {
      const provider = new BrowserProvider(walletProvider)
      const contract = new Contract(KITE_TOKEN_ADDRESS, KITE_ABI, provider)
      const [bal, supply] = await Promise.all([contract.balanceOf(address), contract.totalSupply()])
      const fmt = parseFloat(formatUnits(bal, 18)).toFixed(2)
      const supplyFmt = parseFloat(formatUnits(supply, 18)).toLocaleString()
      setKiteBalance(fmt)
      setTotalSupply(supplyFmt)
      onKiteBalance?.(`${fmt} KITE`)
    } catch {
      setKiteBalance('—')
      setTotalSupply('')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="widget">
      <div className="widget__header">
        <h3 className="widget__title">Kite Currencies</h3>
        {isConnected && onKite && (
          <button className="btn-ghost" onClick={fetchBalance} disabled={loading}>
            {loading ? '…' : 'Refresh'}
          </button>
        )}
      </div>

      {/* KITE token balance row */}
      {isConnected && onKite && KITE_TOKEN_ADDRESS && (
        <div className="kite-balance-row">
          <div className="kite-balance-row__info">
            <span className="token-symbol-badge">KITE</span>
            <div>
              <p className="kite-balance-row__label">Your Balance</p>
              <p className="kite-balance-row__value">{kiteBalance ? `${kiteBalance} KITE` : '—'}</p>
            </div>
          </div>
          {totalSupply && <span className="kite-balance-row__supply">Supply: {totalSupply}</span>}
        </div>
      )}

      {/* Currency list */}
      <ul className="currency-list">
        {KITE_CURRENCIES.map(c => (
          <li key={c.symbol} className="currency-item">
            <div className="currency-item__icon" style={{ background: c.symbol === 'KITE' ? 'linear-gradient(135deg,#00C2D4,#0077FF)' : c.symbol === 'ETH' ? '#627EEA' : c.symbol === 'USDC' ? '#2775CA' : '#6B7280' }}>
              {c.symbol.slice(0, 1)}
            </div>
            <div className="currency-item__info">
              <span className="currency-item__symbol">{c.symbol}</span>
              <span className="currency-item__name">{c.name}</span>
            </div>
            <span className={`currency-item__change ${c.positive ? 'currency-item__change--up' : 'currency-item__change--down'}`}>
              {c.change}
            </span>
          </li>
        ))}
      </ul>

      {!isConnected && <p className="widget__hint">Connect wallet to see live balances</p>}
    </div>
  )
}
