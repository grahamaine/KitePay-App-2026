import { useState, useEffect, useCallback } from 'react'
import { useAppKitAccount, useAppKitProvider, useAppKitNetwork } from '@reown/appkit/react'
import { BrowserProvider, Contract, parseUnits, formatUnits } from 'ethers'
import type { Provider } from '@reown/appkit/react'
import { STAKING_ADDRESS, STAKING_ABI } from '../abi/KiteStaking'
import { KITE_TOKEN_ADDRESS, KITE_TOKEN_ABI } from '../abi/KitePayToken'

interface VaultWidgetProps { onClose: () => void }

type TxStatus = 'idle' | 'approving' | 'staking' | 'unstaking' | 'claiming' | 'done' | 'error'

export const VaultWidget = ({ onClose }: VaultWidgetProps) => {
  const { isConnected, address } = useAppKitAccount()
  const { chainId } = useAppKitNetwork()
  const { walletProvider } = useAppKitProvider<Provider>('eip155')

  const [stakeAmt, setStakeAmt] = useState('')
  const [unstakeAmt, setUnstakeAmt] = useState('')
  const [stakedBalance, setStakedBalance] = useState('0')
  const [pendingRewards, setPendingRewards] = useState('0')
  const [status, setStatus] = useState<TxStatus>('idle')
  const [msg, setMsg] = useState('')

  const onKite = [2368, 2366].includes(Number(chainId))
  const busy = ['approving', 'staking', 'unstaking', 'claiming'].includes(status)

  const fetchStakeInfo = useCallback(async () => {
    if (!address || !walletProvider || !onKite) return
    try {
      const provider = new BrowserProvider(walletProvider)
      const contract = new Contract(STAKING_ADDRESS, STAKING_ABI, provider)
      const [amount, , pending] = await contract.getStakeInfo(address)
      setStakedBalance(parseFloat(formatUnits(amount, 18)).toFixed(4))
      setPendingRewards(parseFloat(formatUnits(pending, 18)).toFixed(6))
    } catch { /* silent */ }
  }, [address, walletProvider, onKite])

  useEffect(() => { fetchStakeInfo() }, [fetchStakeInfo])

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

      setStatus('done'); setMsg(`✓ Staked ${stakeAmt} KITE`)
      setStakeAmt('')
      fetchStakeInfo()
    } catch (e: any) {
      setStatus('error'); setMsg(e?.reason || e?.message || 'Stake failed')
    }
  }

  const handleUnstake = async () => {
    if (!unstakeAmt || !walletProvider) return
    try {
      const provider = new BrowserProvider(walletProvider)
      const signer = await provider.getSigner()
      const amount = parseUnits(unstakeAmt, 18)

      setStatus('unstaking'); setMsg('Unstaking…')
      const staking = new Contract(STAKING_ADDRESS, STAKING_ABI, signer)
      const tx = await staking.unstake(amount)
      await tx.wait()

      setStatus('done'); setMsg(`✓ Unstaked ${unstakeAmt} KITE + rewards`)
      setUnstakeAmt('')
      fetchStakeInfo()
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

      setStatus('done'); setMsg(`✓ Rewards claimed`)
      fetchStakeInfo()
    } catch (e: any) {
      setStatus('error'); setMsg(e?.reason || e?.message || 'Claim failed')
    }
  }

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal modal--wide" onClick={e => e.stopPropagation()}>
        <div className="modal__header">
          <h2 className="modal__title">🔒 Vault</h2>
          <button className="modal__close" onClick={onClose}>✕</button>
        </div>

        {/* Live stats */}
        <div className="vault-stats">
          <div className="vault-stat">
            <span className="vault-stat__icon" style={{ color: '#8B5CF6' }}>🔒</span>
            <span className="vault-stat__label">KITE Staked</span>
            <span className="vault-stat__value" style={{ color: '#8B5CF6' }}>{stakedBalance} KITE</span>
          </div>
          <div className="vault-stat">
            <span className="vault-stat__icon" style={{ color: '#F0B429' }}>✨</span>
            <span className="vault-stat__label">Pending Rewards</span>
            <span className="vault-stat__value" style={{ color: '#F0B429' }}>{pendingRewards} KITE</span>
          </div>
          <div className="vault-stat">
            <span className="vault-stat__icon" style={{ color: '#22C55E' }}>📈</span>
            <span className="vault-stat__label">APY</span>
            <span className="vault-stat__value" style={{ color: '#22C55E' }}>12.5%</span>
          </div>
        </div>

        {!isConnected ? (
          <p className="modal__hint">Connect wallet to access Vault</p>
        ) : !onKite ? (
          <p className="modal__hint">Switch to Kite Testnet to stake</p>
        ) : (
          <>
            {msg && (
              <p className={`status-msg status-msg--${status === 'error' ? 'error' : status === 'done' ? 'success' : 'loading'}`}>
                {msg}
              </p>
            )}

            <div className="modal__field">
              <label>Stake Amount (KITE)</label>
              <input className="input" type="number" placeholder="0.00" value={stakeAmt} onChange={e => setStakeAmt(e.target.value)} disabled={busy} />
            </div>

            <div className="modal__field" style={{ marginTop: 8 }}>
              <label>Unstake Amount (KITE)</label>
              <input className="input" type="number" placeholder={`Max: ${stakedBalance}`} value={unstakeAmt} onChange={e => setUnstakeAmt(e.target.value)} disabled={busy} />
            </div>

            <div className="btn-row" style={{ marginTop: 12 }}>
              <button className="btn btn--primary" disabled={busy || !stakeAmt} onClick={handleStake}>
                {status === 'approving' ? 'Approving…' : status === 'staking' ? 'Staking…' : 'Stake KITE'}
              </button>
              <button className="btn btn--secondary" disabled={busy || !unstakeAmt} onClick={handleUnstake}>
                {status === 'unstaking' ? 'Unstaking…' : 'Unstake'}
              </button>
              <button className="btn btn--secondary" disabled={busy || parseFloat(pendingRewards) === 0} onClick={handleClaim}>
                {status === 'claiming' ? 'Claiming…' : 'Claim Rewards'}
              </button>
            </div>

            <p className="modal__hint" style={{ marginTop: 12 }}>
              Staking earns 12.5% APY. Rewards accrue per second and are paid from the reward pool.
            </p>
          </>
        )}
      </div>
    </div>
  )
}
