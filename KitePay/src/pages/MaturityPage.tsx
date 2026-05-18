import { useState, useEffect, useCallback } from 'react'
import { useAppKitAccount, useAppKitProvider, useAppKitNetwork } from '@reown/appkit/react'
import { BrowserProvider, Contract, parseUnits, formatUnits } from 'ethers'
import type { Provider } from '@reown/appkit/react'
import { STAKING_ADDRESS, STAKING_ABI } from '../abi/KiteStaking'
import { KITE_TOKEN_ADDRESS, KITE_TOKEN_ABI } from '../abi/KitePayToken'

const PLANS = [
  { id: 'flex', name: 'Flexible', apy: '8%',   lock: 'No lock',  min: '100',   color: '#00C2D4' },
  { id: '30d',  name: '30 Days',  apy: '12.5%', lock: '30 days', min: '500',   color: '#F0B429' },
  { id: '90d',  name: '90 Days',  apy: '18%',   lock: '90 days', min: '1000',  color: '#8B5CF6' },
  { id: '1y',   name: '1 Year',   apy: '28%',   lock: '365 days',min: '5000',  color: '#22C55E' },
]

type TxStatus = 'idle' | 'approving' | 'staking' | 'unstaking' | 'claiming' | 'done' | 'error'

export const MaturityPage = () => {
  const { isConnected, address } = useAppKitAccount()
  const { chainId } = useAppKitNetwork()
  const { walletProvider } = useAppKitProvider<Provider>('eip155')

  const [selectedPlan, setSelectedPlan] = useState('30d')
  const [stakeAmt, setStakeAmt] = useState('')
  const [stakedBalance, setStakedBalance] = useState('0')
  const [pendingRewards, setPendingRewards] = useState('0')
  const [totalStaked, setTotalStaked] = useState('0')
  const [status, setStatus] = useState<TxStatus>('idle')
  const [msg, setMsg] = useState('')

  const plan = PLANS.find(p => p.id === selectedPlan)!
  const onKite = [2368, 2366].includes(Number(chainId))
  const busy = ['approving', 'staking', 'unstaking', 'claiming'].includes(status)

  const estReward = stakeAmt
    ? (parseFloat(stakeAmt) * parseFloat(plan.apy) / 100).toFixed(2)
    : ''

  const fetchInfo = useCallback(async () => {
    if (!address || !walletProvider || !onKite) return
    try {
      const provider = new BrowserProvider(walletProvider)
      const contract = new Contract(STAKING_ADDRESS, STAKING_ABI, provider)
      const [[amount, , pending], total] = await Promise.all([
        contract.getStakeInfo(address),
        contract.totalStaked(),
      ])
      setStakedBalance(parseFloat(formatUnits(amount, 18)).toFixed(4))
      setPendingRewards(parseFloat(formatUnits(pending, 18)).toFixed(6))
      setTotalStaked(parseFloat(formatUnits(total, 18)).toLocaleString())
    } catch { /* silent */ }
  }, [address, walletProvider, onKite])

  useEffect(() => { fetchInfo() }, [fetchInfo])

  const handleStake = async () => {
    if (!stakeAmt || !walletProvider || !address) return
    try {
      const provider = new BrowserProvider(walletProvider)
      const signer = await provider.getSigner()
      const amount = parseUnits(stakeAmt, 18)

      setStatus('approving'); setMsg('Approving KITE…')
      const kite = new Contract(KITE_TOKEN_ADDRESS, KITE_TOKEN_ABI, signer)
      const approveTx = await kite.approve(STAKING_ADDRESS, amount)
      await approveTx.wait()

      setStatus('staking'); setMsg('Staking KITE…')
      const staking = new Contract(STAKING_ADDRESS, STAKING_ABI, signer)
      const tx = await staking.stake(amount)
      await tx.wait()

      setStatus('done'); setMsg(`✓ Staked ${stakeAmt} KITE on ${plan.name} plan`)
      setStakeAmt('')
      fetchInfo()
    } catch (e: any) {
      setStatus('error'); setMsg(e?.reason || e?.message || 'Stake failed')
    }
  }

  const handleUnstake = async () => {
    if (!walletProvider || parseFloat(stakedBalance) === 0) return
    try {
      const provider = new BrowserProvider(walletProvider)
      const signer = await provider.getSigner()
      const amount = parseUnits(stakedBalance, 18)

      setStatus('unstaking'); setMsg('Unstaking all…')
      const staking = new Contract(STAKING_ADDRESS, STAKING_ABI, signer)
      const tx = await staking.unstake(amount)
      await tx.wait()

      setStatus('done'); setMsg('✓ Unstaked KITE + rewards returned')
      fetchInfo()
    } catch (e: any) {
      setStatus('error'); setMsg(e?.reason || e?.message || 'Unstake failed')
    }
  }

  const handleClaim = async () => {
    if (!walletProvider) return
    try {
      const provider = new BrowserProvider(walletProvider)
      const signer = await provider.getSigner()

      setStatus('claiming'); setMsg('Claiming rewards…')
      const staking = new Contract(STAKING_ADDRESS, STAKING_ABI, signer)
      const tx = await staking.claimRewards()
      await tx.wait()

      setStatus('done'); setMsg('✓ Rewards claimed')
      fetchInfo()
    } catch (e: any) {
      setStatus('error'); setMsg(e?.reason || e?.message || 'Claim failed')
    }
  }

  return (
    <div className="page">
      <div className="page__header">
        <h2 className="page__title">◎ Maturity</h2>
        <p className="page__sub">Stake KITE and earn passive rewards</p>
      </div>

      {/* Live stats */}
      <div className="summary-row">
        <div className="summary-card">
          <span className="summary-card__label">Your Staked</span>
          <span className="summary-card__value">{stakedBalance} KITE</span>
        </div>
        <div className="summary-card summary-card--green">
          <span className="summary-card__label">Pending Rewards</span>
          <span className="summary-card__value">{pendingRewards} KITE</span>
        </div>
        <div className="summary-card">
          <span className="summary-card__label">Total Staked</span>
          <span className="summary-card__value">{totalStaked} KITE</span>
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
              <span className="plan-card__min">Min: {p.min} KITE</span>
            </button>
          ))}
        </div>
      </div>

      {/* Stake form */}
      <div className="widget">
        <div className="widget__header">
          <h3 className="widget__title">Stake KITE — {plan.name} ({plan.apy} APY)</h3>
          {isConnected && onKite && (
            <button className="btn-ghost" onClick={fetchInfo} style={{ fontSize: 12 }}>Refresh ↺</button>
          )}
        </div>

        {msg && (
          <p className={`status-msg status-msg--${status === 'error' ? 'error' : status === 'done' ? 'success' : 'loading'}`} style={{ marginBottom: 12 }}>
            {msg}
          </p>
        )}

        <div className="modal__field">
          <label>Amount to Stake (KITE)</label>
          <input className="input" type="number" placeholder={`Min ${plan.min} KITE`} value={stakeAmt} onChange={e => setStakeAmt(e.target.value)} disabled={busy} />
        </div>

        {estReward && (
          <div className="swap-info" style={{ marginTop: 12 }}>
            <span>Est. Annual Reward</span>
            <span style={{ color: '#22C55E' }}>+{estReward} KITE</span>
          </div>
        )}

        <div className="btn-row" style={{ marginTop: 16 }}>
          <button className="btn btn--primary" disabled={!isConnected || !onKite || busy || !stakeAmt} onClick={handleStake}>
            {status === 'approving' ? 'Approving…' : status === 'staking' ? 'Staking…' : isConnected ? 'Stake Now' : 'Connect Wallet'}
          </button>
          <button className="btn btn--secondary" disabled={!isConnected || !onKite || busy || parseFloat(stakedBalance) === 0} onClick={handleUnstake}>
            {status === 'unstaking' ? 'Unstaking…' : 'Unstake All'}
          </button>
          <button className="btn btn--secondary" disabled={!isConnected || !onKite || busy || parseFloat(pendingRewards) === 0} onClick={handleClaim}>
            {status === 'claiming' ? 'Claiming…' : 'Claim Rewards'}
          </button>
        </div>

        {!onKite && isConnected && (
          <p className="modal__hint" style={{ marginTop: 8 }}>Switch to Kite Testnet to stake</p>
        )}
      </div>
    </div>
  )
}
