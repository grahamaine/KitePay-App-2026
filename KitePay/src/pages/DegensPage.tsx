import { useState } from 'react'
import { useAppKitAccount, useAppKit } from '@reown/appkit/react'

const TOKENS = ['KITE', 'ETH', 'USDC', 'WBTC']

const POOLS = [
  { pair: 'KITE / ETH', tvl: '$2.4M', apr: '24.5%', vol: '$180K' },
  { pair: 'KITE / USDC', tvl: '$1.8M', apr: '18.2%', vol: '$240K' },
  { pair: 'ETH / USDC', tvl: '$5.2M', apr: '12.1%', vol: '$620K' },
]

export const DegensPage = () => {
  const { isConnected } = useAppKitAccount()
  const { open } = useAppKit()
  const [fromToken, setFromToken] = useState('ETH')
  const [toToken, setToToken] = useState('KITE')
  const [amount, setAmount] = useState('')
  const [poolNotice, setPoolNotice] = useState('')

  const estimated = amount ? (parseFloat(amount) * 1840.5).toFixed(2) : ''

  const flipTokens = () => {
    setFromToken(toToken)
    setToToken(fromToken)
  }

  const handleSwap = () => {
    open({ view: 'Swap' })
  }

  const showPoolNotice = (msg: string) => {
    setPoolNotice(msg)
    setTimeout(() => setPoolNotice(''), 3000)
  }

  return (
    <div className="page">
      <div className="page__header">
        <h2 className="page__title">⚡ Degens</h2>
        <p className="page__sub">Swap tokens and provide liquidity</p>
      </div>

      <div className="degens-grid">
        {/* Swap widget */}
        <div className="widget">
          <div className="widget__header">
            <h3 className="widget__title">Token Swap</h3>
            <span className="badge-info">Kite DEX</span>
          </div>

          <div className="swap-box">
            <label className="swap-box__label">From</label>
            <div className="swap-row">
              <select className="select" value={fromToken} onChange={e => setFromToken(e.target.value)}>
                {TOKENS.map(t => <option key={t} value={t}>{t}</option>)}
              </select>
              <input className="input" type="number" placeholder="0.00" value={amount} onChange={e => setAmount(e.target.value)} />
            </div>
          </div>

          <button className="swap-flip-btn" onClick={flipTokens} title="Flip tokens">⇅</button>

          <div className="swap-box">
            <label className="swap-box__label">To</label>
            <div className="swap-row">
              <select className="select" value={toToken} onChange={e => setToToken(e.target.value)}>
                {TOKENS.map(t => <option key={t} value={t}>{t}</option>)}
              </select>
              <input className="input" placeholder={estimated || '0.00'} readOnly />
            </div>
          </div>

          {amount && (
            <div className="swap-info">
              <span>Rate</span>
              <span>1 {fromToken} ≈ 1,840.5 {toToken}</span>
            </div>
          )}

          <button
            className="btn btn--primary btn--full"
            disabled={!isConnected}
            onClick={handleSwap}
          >
            {isConnected ? 'Swap Tokens' : 'Connect Wallet to Swap'}
          </button>
        </div>

        {/* Liquidity pools */}
        <div className="widget">
          <div className="widget__header">
            <h3 className="widget__title">Liquidity Pools</h3>
            <button
              className="btn btn--secondary"
              style={{ fontSize: '12px', padding: '6px 14px' }}
              onClick={() => showPoolNotice('Liquidity pools coming soon')}
            >
              + Add Liquidity
            </button>
          </div>
          {poolNotice && (
            <p className="status-msg status-msg--loading" style={{ marginBottom: 8 }}>{poolNotice}</p>
          )}
          <div className="pool-list">
            {POOLS.map(p => (
              <div key={p.pair} className="pool-item">
                <div>
                  <p className="pool-item__pair">{p.pair}</p>
                  <p className="pool-item__tvl">TVL {p.tvl}</p>
                </div>
                <div className="pool-item__stats">
                  <span className="pool-item__apr">{p.apr} APR</span>
                  <span className="pool-item__vol">Vol {p.vol}</span>
                </div>
                <button
                  className="btn btn--secondary"
                  style={{ fontSize: '12px', padding: '6px 12px' }}
                  onClick={() => showPoolNotice(`${p.pair} pool — coming soon`)}
                >
                  Join
                </button>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
