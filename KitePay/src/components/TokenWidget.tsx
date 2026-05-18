import { useState } from 'react'
import { useAppKitNetwork, useAppKitAccount, useAppKitProvider } from '@reown/appkit/react'
import { Contract, BrowserProvider, formatUnits } from 'ethers'
import type { Provider } from '@reown/appkit/react'
import { KITE_TOKEN_ADDRESS, USDC_TOKEN_ADDRESS, USDT_TOKEN_ADDRESS } from '../abi/KitePayToken'

const ERC20_ABI = [
  { inputs: [{ internalType: 'address', name: 'account', type: 'address' }], name: 'balanceOf', outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }], stateMutability: 'view', type: 'function' },
  { inputs: [], name: 'totalSupply', outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }], stateMutability: 'view', type: 'function' },
  { inputs: [], name: 'decimals', outputs: [{ internalType: 'uint8', name: '', type: 'uint8' }], stateMutability: 'view', type: 'function' },
]

const KITE_CURRENCIES = [
  { symbol: 'KITE', name: 'KitePay', change: '+4.62%', positive: true },
  { symbol: 'ETH', name: 'Ethereum', change: '+1.05%', positive: true },
  { symbol: 'USDC', name: 'USD Coin', change: '+0.01%', positive: true },
  { symbol: 'USDT', name: 'Tether USD', change: '+0.00%', positive: true },
]

interface TokenWidgetProps {
  onKiteBalance?: (b: string) => void
  onUsdcBalance?: (b: string) => void
  onUsdtBalance?: (b: string) => void
}

interface StablecoinBalances {
  usdc: string
  usdt: string
}

export const TokenWidget = ({ onKiteBalance, onUsdcBalance, onUsdtBalance }: TokenWidgetProps) => {
  const { address, isConnected } = useAppKitAccount()
  const { chainId } = useAppKitNetwork()
  const { walletProvider } = useAppKitProvider<Provider>('eip155')
  const [kiteBalance, setKiteBalance] = useState('')
  const [totalSupply, setTotalSupply] = useState('')
  const [stableBalances, setStableBalances] = useState<StablecoinBalances>({ usdc: '', usdt: '' })
  const [loading, setLoading] = useState(false)

  const onKite = [2368, 2366].includes(Number(chainId))

  const fetchBalance = async () => {
    if (!address || !walletProvider) return
    setLoading(true)
    try {
      const provider = new BrowserProvider(walletProvider)

      const fetchToken = async (tokenAddress: string) => {
        const contract = new Contract(tokenAddress, ERC20_ABI, provider)
        const [bal, decimals] = await Promise.all([contract.balanceOf(address), contract.decimals()])
        return parseFloat(formatUnits(bal, decimals)).toFixed(2)
      }

      const [kiteBal, kiteSupply, usdcBal, usdtBal] = await Promise.all([
        new Contract(KITE_TOKEN_ADDRESS, ERC20_ABI, provider).balanceOf(address),
        new Contract(KITE_TOKEN_ADDRESS, ERC20_ABI, provider).totalSupply(),
        fetchToken(USDC_TOKEN_ADDRESS),
        fetchToken(USDT_TOKEN_ADDRESS),
      ])

      const fmt = parseFloat(formatUnits(kiteBal, 18)).toFixed(2)
      const supplyFmt = parseFloat(formatUnits(kiteSupply, 18)).toLocaleString()
      setKiteBalance(fmt)
      setTotalSupply(supplyFmt)
      setStableBalances({ usdc: usdcBal, usdt: usdtBal })
      onKiteBalance?.(`${fmt} KITE`)
      onUsdcBalance?.(usdcBal)
      onUsdtBalance?.(usdtBal)
    } catch {
      setKiteBalance('—')
      setTotalSupply('')
      setStableBalances({ usdc: '—', usdt: '—' })
    } finally {
      setLoading(false)
    }
  }

  const getTokenColor = (symbol: string) => {
    if (symbol === 'KITE') return 'linear-gradient(135deg,#00C2D4,#0077FF)'
    if (symbol === 'ETH') return '#627EEA'
    if (symbol === 'USDC') return '#2775CA'
    if (symbol === 'USDT') return '#26A17B'
    return '#6B7280'
  }

  const getTokenBalance = (symbol: string) => {
    if (!isConnected || !onKite) return null
    if (symbol === 'KITE') return kiteBalance ? `${kiteBalance} KITE` : null
    if (symbol === 'USDC') return stableBalances.usdc ? `${stableBalances.usdc} USDC` : null
    if (symbol === 'USDT') return stableBalances.usdt ? `${stableBalances.usdt} USDT` : null
    return null
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
      {isConnected && onKite && (
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
        {KITE_CURRENCIES.map(c => {
          const liveBalance = getTokenBalance(c.symbol)
          return (
            <li key={c.symbol} className="currency-item">
              <div className="currency-item__icon" style={{ background: getTokenColor(c.symbol) }}>
                {c.symbol.slice(0, 1)}
              </div>
              <div className="currency-item__info">
                <span className="currency-item__symbol">{c.symbol}</span>
                <span className="currency-item__name">{liveBalance ?? c.name}</span>
              </div>
              <span className={`currency-item__change ${c.positive ? 'currency-item__change--up' : 'currency-item__change--down'}`}>
                {c.change}
              </span>
            </li>
          )
        })}
      </ul>

      {!isConnected && <p className="widget__hint">Connect wallet to see live balances</p>}
    </div>
  )
}
