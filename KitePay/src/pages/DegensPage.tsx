import { useState, useEffect, useCallback } from 'react'
import { useAppKitAccount, useAppKitProvider, useAppKitNetwork, useAppKit } from '@reown/appkit/react'
import { BrowserProvider, Contract, parseUnits, formatUnits } from 'ethers'
import type { Provider } from '@reown/appkit/react'
import { LP_ADDRESS, LP_ABI } from '../abi/KiteLiquidityPool'
import { KITE_TOKEN_ADDRESS, USDC_TOKEN_ADDRESS, KITE_TOKEN_ABI } from '../abi/KitePayToken'

const APPROVE_ABI = [
  { inputs: [{ internalType: 'address', name: 'spender', type: 'address' }, { internalType: 'uint256', name: 'value', type: 'uint256' }], name: 'approve', outputs: [{ internalType: 'bool', name: '', type: 'bool' }], stateMutability: 'nonpayable', type: 'function' },
] as const

const TOKENS = ['KITE', 'ETH', 'USDC', 'WBTC']

type TxStatus = 'idle' | 'approving' | 'adding' | 'removing' | 'done' | 'error'

export const DegensPage = () => {
  const { isConnected, address } = useAppKitAccount()
  const { chainId } = useAppKitNetwork()
  const { walletProvider } = useAppKitProvider<Provider>('eip155')
  const { open } = useAppKit()

  const [fromToken, setFromToken] = useState('ETH')
  const [toToken, setToToken] = useState('KITE')
  const [amount, setAmount] = useState('')

  // Pool state
  const [kiteAmt, setKiteAmt] = useState('')
  const [usdcAmt, setUsdcAmt] = useState('')
  const [poolReserveA, setPoolReserveA] = useState('0')
  const [poolReserveB, setPoolReserveB] = useState('0')
  const [userLp, setUserLp] = useState('0')
  const [userShareA, setUserShareA] = useState('0')
  const [userShareB, setUserShareB] = useState('0')
  const [status, setStatus] = useState<TxStatus>('idle')
  const [msg, setMsg] = useState('')
  const [showLpForm, setShowLpForm] = useState(false)

  const onKite = [2368, 2366].includes(Number(chainId))
  const estimated = amount ? (parseFloat(amount) * 1840.5).toFixed(2) : ''
  const busy = ['approving', 'adding', 'removing'].includes(status)

  const fetchPoolInfo = useCallback(async () => {
    if (!walletProvider || !onKite) return
    try {
      const provider = new BrowserProvider(walletProvider)
      const lp = new Contract(LP_ADDRESS, LP_ABI, provider)
      const [rA, rB] = await lp.getPoolInfo()
      setPoolReserveA(parseFloat(formatUnits(rA, 18)).toFixed(2))
      setPoolReserveB(parseFloat(formatUnits(rB, 6)).toFixed(2))
      if (address) {
        const [lpBal, sA, sB] = await lp.getUserPosition(address)
        setUserLp(parseFloat(formatUnits(lpBal, 18)).toFixed(6))
        setUserShareA(parseFloat(formatUnits(sA, 18)).toFixed(4))
        setUserShareB(parseFloat(formatUnits(sB, 6)).toFixed(4))
      }
    } catch { /* silent */ }
  }, [walletProvider, onKite, address])

  useEffect(() => { fetchPoolInfo() }, [fetchPoolInfo])

  const handleAddLiquidity = async () => {
    if (!kiteAmt || !usdcAmt || !walletProvider) return
    try {
      const provider = new BrowserProvider(walletProvider)
      const signer = await provider.getSigner()
      const amtKite = parseUnits(kiteAmt, 18)
      const amtUsdc = parseUnits(usdcAmt, 6)

      setStatus('approving'); setMsg('Approving KITE…')
      const kite = new Contract(KITE_TOKEN_ADDRESS, APPROVE_ABI, signer)
      await (await kite.approve(LP_ADDRESS, amtKite)).wait()

      setMsg('Approving USDC…')
      const usdc = new Contract(USDC_TOKEN_ADDRESS, APPROVE_ABI, signer)
      await (await usdc.approve(LP_ADDRESS, amtUsdc)).wait()

      setStatus('adding'); setMsg('Adding liquidity…')
      const lp = new Contract(LP_ADDRESS, LP_ABI, signer)
      const tx = await lp.addLiquidity(amtKite, amtUsdc)
      await tx.wait()

      setStatus('done'); setMsg(`✓ Added ${kiteAmt} KITE + ${usdcAmt} USDC to the pool`)
      setKiteAmt(''); setUsdcAmt('')
      fetchPoolInfo()
    } catch (e: any) {
      setStatus('error'); setMsg(e?.reason || e?.message || 'Add liquidity failed')
    }
  }

  const handleRemoveLiquidity = async () => {
    if (!walletProvider || parseFloat(userLp) === 0) return
    try {
      const provider = new BrowserProvider(walletProvider)
      const signer = await provider.getSigner()
      const lpAmt = parseUnits(userLp, 18)

      setStatus('approving'); setMsg('Approving LP tokens…')
      const lp = new Contract(LP_ADDRESS, LP_ABI, signer)
      await (await lp.approve(LP_ADDRESS, lpAmt)).wait()

      setStatus('removing'); setMsg('Removing liquidity…')
      const tx = await lp.removeLiquidity(lpAmt)
      await tx.wait()

      setStatus('done'); setMsg('✓ Liquidity removed')
      fetchPoolInfo()
    } catch (e: any) {
      setStatus('error'); setMsg(e?.reason || e?.message || 'Remove liquidity failed')
    }
  }

  const POOLS = [
    { pair: 'KITE / USDC', tvl: `${poolReserveA} KITE / ${poolReserveB} USDC`, apr: '18.2%', live: true },
    { pair: 'KITE / ETH',  tvl: '$2.4M',  apr: '24.5%', live: false },
    { pair: 'ETH / USDC',  tvl: '$5.2M',  apr: '12.1%', live: false },
  ]

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
            <span className="badge-info">AppKit DEX</span>
          </div>

          <div className="swap-box">
            <label className="swap-box__label">From</label>
            <div className="swap-row">
              <select className="select" value={fromToken} onChange={e => setFromToken(e.target.value)}>
                {TOKENS.map(t => <option key={t}>{t}</option>)}
              </select>
              <input className="input" type="number" placeholder="0.00" value={amount} onChange={e => setAmount(e.target.value)} />
            </div>
          </div>

          <button className="swap-flip-btn" onClick={() => { setFromToken(toToken); setToToken(fromToken) }} title="Flip tokens">⇅</button>

          <div className="swap-box">
            <label className="swap-box__label">To</label>
            <div className="swap-row">
              <select className="select" value={toToken} onChange={e => setToToken(e.target.value)}>
                {TOKENS.map(t => <option key={t}>{t}</option>)}
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

          <button className="btn btn--primary btn--full" disabled={!isConnected} onClick={() => open({ view: 'Swap' })}>
            {isConnected ? 'Swap Tokens' : 'Connect Wallet to Swap'}
          </button>
        </div>

        {/* Liquidity pools */}
        <div className="widget">
          <div className="widget__header">
            <h3 className="widget__title">Liquidity Pools</h3>
            <button className="btn btn--secondary" style={{ fontSize: '12px', padding: '6px 14px' }} onClick={() => { setShowLpForm(f => !f); setMsg(''); setStatus('idle') }}>
              {showLpForm ? 'Hide Form' : '+ Add Liquidity'}
            </button>
          </div>

          {/* LP form */}
          {showLpForm && (
            <div style={{ marginBottom: 16, padding: '12px', background: 'rgba(255,255,255,0.04)', borderRadius: 10 }}>
              {msg && (
                <p className={`status-msg status-msg--${status === 'error' ? 'error' : status === 'done' ? 'success' : 'loading'}`} style={{ marginBottom: 8 }}>{msg}</p>
              )}
              <div className="modal__field" style={{ marginBottom: 8 }}>
                <label>KITE Amount</label>
                <input className="input" type="number" placeholder="0.00" value={kiteAmt} onChange={e => setKiteAmt(e.target.value)} disabled={busy} />
              </div>
              <div className="modal__field" style={{ marginBottom: 10 }}>
                <label>USDC Amount</label>
                <input className="input" type="number" placeholder="0.00" value={usdcAmt} onChange={e => setUsdcAmt(e.target.value)} disabled={busy} />
              </div>
              <div className="btn-row">
                <button className="btn btn--primary" disabled={!isConnected || !onKite || busy || !kiteAmt || !usdcAmt} onClick={handleAddLiquidity} style={{ fontSize: 13 }}>
                  {status === 'approving' ? 'Approving…' : status === 'adding' ? 'Adding…' : 'Add Liquidity'}
                </button>
                {parseFloat(userLp) > 0 && (
                  <button className="btn btn--secondary" disabled={busy} onClick={handleRemoveLiquidity} style={{ fontSize: 13 }}>
                    {status === 'removing' ? 'Removing…' : 'Remove All'}
                  </button>
                )}
              </div>
              {parseFloat(userLp) > 0 && (
                <p style={{ fontSize: 12, color: '#9CA3AF', marginTop: 8 }}>
                  Your position: {userShareA} KITE + {userShareB} USDC ({userLp} KLP)
                </p>
              )}
            </div>
          )}

          <div className="pool-list">
            {POOLS.map(p => (
              <div key={p.pair} className="pool-item">
                <div>
                  <p className="pool-item__pair">
                    {p.pair}
                    {p.live && <span style={{ fontSize: 10, color: '#22C55E', marginLeft: 6, fontWeight: 600 }}>● LIVE</span>}
                  </p>
                  <p className="pool-item__tvl">TVL {p.tvl}</p>
                </div>
                <div className="pool-item__stats">
                  <span className="pool-item__apr">{p.apr} APR</span>
                </div>
                <button
                  className="btn btn--secondary"
                  style={{ fontSize: '12px', padding: '6px 12px' }}
                  onClick={() => { if (p.live) { setShowLpForm(true) } }}
                  disabled={!p.live}
                >
                  {p.live ? 'Join' : 'Soon'}
                </button>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
