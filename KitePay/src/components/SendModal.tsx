import { useState } from 'react'
import { useAppKitAccount, useAppKitProvider, useAppKitNetwork } from '@reown/appkit/react'
import { BrowserProvider, parseUnits, Contract } from 'ethers'
import type { Provider } from '@reown/appkit/react'

const KITE_TOKEN_ADDRESS = import.meta.env.VITE_KITE_TOKEN_ADDRESS || ''
const TRANSFER_ABI = [
  { inputs: [{ internalType: 'address', name: 'to', type: 'address' }, { internalType: 'uint256', name: 'value', type: 'uint256' }], name: 'transfer', outputs: [{ internalType: 'bool', name: '', type: 'bool' }], stateMutability: 'nonpayable', type: 'function' },
]

interface SendModalProps { onClose: () => void }

export const SendModal = ({ onClose }: SendModalProps) => {
  const { isConnected } = useAppKitAccount()
  const { chainId } = useAppKitNetwork()
  const { walletProvider } = useAppKitProvider<Provider>('eip155')
  const [to, setTo] = useState('')
  const [amount, setAmount] = useState('')
  const [status, setStatus] = useState<'idle' | 'sending' | 'done' | 'error'>('idle')
  const [msg, setMsg] = useState('')
  const onKite = [2368, 2366].includes(Number(chainId))
  const useKiteToken = onKite && !!KITE_TOKEN_ADDRESS
  const sendLabel = useKiteToken ? 'KITE' : onKite ? 'KITE (native)' : 'ETH'

  const handleSend = async () => {
    if (!to || !amount || !walletProvider) return
    setStatus('sending'); setMsg('Sending…')
    try {
      const provider = new BrowserProvider(walletProvider)
      const signer = await provider.getSigner()
      if (useKiteToken) {
        const contract = new Contract(KITE_TOKEN_ADDRESS, TRANSFER_ABI, signer)
        const tx = await contract.transfer(to, parseUnits(amount, 18))
        await tx.wait()
        setMsg(`✓ Sent ${amount} KITE`)
      } else {
        const tx = await signer.sendTransaction({ to, value: parseUnits(amount, 'ether') })
        await tx.wait()
        setMsg(`✓ Sent ${amount} ${onKite ? 'KITE' : 'ETH'}`)
      }
      setStatus('done')
    } catch (e: any) {
      setStatus('error'); setMsg(e?.reason || e?.message || 'Transaction failed')
    }
  }

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={e => e.stopPropagation()}>
        <div className="modal__header">
          <h2 className="modal__title">Send {sendLabel}</h2>
          <button className="modal__close" onClick={onClose}>✕</button>
        </div>
        {!isConnected ? (
          <p className="modal__hint">Connect your wallet first</p>
        ) : (
          <>
            <div className="modal__field">
              <label>Recipient Address</label>
              <input className="input" placeholder="0x..." value={to} onChange={e => setTo(e.target.value)} />
            </div>
            <div className="modal__field">
              <label>Amount</label>
              <input className="input" type="number" placeholder="0.00" min="0" value={amount} onChange={e => setAmount(e.target.value)} />
            </div>
            {msg && <p className={`status-msg status-msg--${status === 'error' ? 'error' : status === 'done' ? 'success' : 'loading'}`}>{msg}</p>}
            <button className="btn btn--primary btn--full" onClick={handleSend} disabled={status === 'sending' || !to || !amount}>
              {status === 'sending' ? 'Sending…' : 'Send'}
            </button>
          </>
        )}
      </div>
    </div>
  )
}
