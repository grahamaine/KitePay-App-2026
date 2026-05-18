import { useState } from 'react'
import { useAppKitAccount, useAppKitProvider, useAppKitNetwork } from '@reown/appkit/react'
import { BrowserProvider, parseUnits, Contract } from 'ethers'
import type { Provider } from '@reown/appkit/react'
import { KITE_TOKEN_ADDRESS, USDC_TOKEN_ADDRESS, USDT_TOKEN_ADDRESS } from '../abi/KitePayToken'

const TRANSFER_ABI = [
  { inputs: [{ internalType: 'address', name: 'to', type: 'address' }, { internalType: 'uint256', name: 'value', type: 'uint256' }], name: 'transfer', outputs: [{ internalType: 'bool', name: '', type: 'bool' }], stateMutability: 'nonpayable', type: 'function' },
]

type TokenOption = 'KITE' | 'USDC' | 'USDT' | 'NATIVE'

const TOKEN_CONFIG: Record<TokenOption, { label: string; address: string | null; decimals: number; color: string }> = {
  KITE:   { label: 'KITE',        address: KITE_TOKEN_ADDRESS, decimals: 18, color: '#00C2D4' },
  USDC:   { label: 'USDC',        address: USDC_TOKEN_ADDRESS, decimals: 6,  color: '#2775CA' },
  USDT:   { label: 'USDT',        address: USDT_TOKEN_ADDRESS, decimals: 6,  color: '#26A17B' },
  NATIVE: { label: 'KITE (native)', address: null,             decimals: 18, color: '#0077FF' },
}

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
  const [selectedToken, setSelectedToken] = useState<TokenOption>('KITE')

  const token = TOKEN_CONFIG[selectedToken]
  const availableTokens: TokenOption[] = onKite ? ['KITE', 'USDC', 'USDT', 'NATIVE'] : ['NATIVE']

  const handleSend = async () => {
    if (!to || !amount || !walletProvider) return
    setStatus('sending'); setMsg('Sending…')
    try {
      const provider = new BrowserProvider(walletProvider)
      const signer = await provider.getSigner()
      if (token.address) {
        const contract = new Contract(token.address, TRANSFER_ABI, signer)
        const tx = await contract.transfer(to, parseUnits(amount, token.decimals))
        await tx.wait()
        setMsg(`✓ Sent ${amount} ${token.label}`)
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
          <h2 className="modal__title">Send</h2>
          <button className="modal__close" onClick={onClose}>✕</button>
        </div>
        {!isConnected ? (
          <p className="modal__hint">Connect your wallet first</p>
        ) : (
          <>
            {/* Token selector */}
            <div className="modal__field">
              <label>Token</label>
              <div className="token-selector">
                {availableTokens.map(t => (
                  <button
                    key={t}
                    className={`token-selector__btn ${selectedToken === t ? 'token-selector__btn--active' : ''}`}
                    style={selectedToken === t ? { borderColor: TOKEN_CONFIG[t].color, color: TOKEN_CONFIG[t].color } : {}}
                    onClick={() => { setSelectedToken(t); setMsg(''); setStatus('idle') }}
                  >
                    {TOKEN_CONFIG[t].label}
                  </button>
                ))}
              </div>
            </div>
            <div className="modal__field">
              <label>Recipient Address</label>
              <input className="input" placeholder="0x..." value={to} onChange={e => setTo(e.target.value)} />
            </div>
            <div className="modal__field">
              <label>Amount ({token.label})</label>
              <input className="input" type="number" placeholder="0.00" min="0" value={amount} onChange={e => setAmount(e.target.value)} />
            </div>
            {msg && <p className={`status-msg status-msg--${status === 'error' ? 'error' : status === 'done' ? 'success' : 'loading'}`}>{msg}</p>}
            <button className="btn btn--primary btn--full" onClick={handleSend} disabled={status === 'sending' || !to || !amount}>
              {status === 'sending' ? 'Sending…' : `Send ${token.label}`}
            </button>
          </>
        )}
      </div>
    </div>
  )
}
