import { useState } from 'react'
import { useAppKitAccount, useAppKitNetwork } from '@reown/appkit/react'

type TokenOption = 'KITE' | 'USDC' | 'USDT'

const TOKEN_COLORS: Record<TokenOption, string> = {
  KITE: '#00C2D4',
  USDC: '#2775CA',
  USDT: '#26A17B',
}

interface ReceiveModalProps { onClose: () => void }

export const ReceiveModal = ({ onClose }: ReceiveModalProps) => {
  const { address, isConnected } = useAppKitAccount()
  const { chainId } = useAppKitNetwork()
  const [copied, setCopied] = useState(false)
  const [selectedToken, setSelectedToken] = useState<TokenOption>('KITE')

  const onKite = [2368, 2366].includes(Number(chainId))
  const tokens: TokenOption[] = onKite ? ['KITE', 'USDC', 'USDT'] : ['KITE']
  const color = TOKEN_COLORS[selectedToken]

  const copy = () => {
    if (!address) return
    navigator.clipboard.writeText(address)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  const QRPlaceholder = () => (
    <div className="qr-box">
      <div className="qr-box__inner">
        <svg viewBox="0 0 100 100" width="160" height="160">
          {Array.from({ length: 10 }, (_, r) =>
            Array.from({ length: 10 }, (_, c) => {
              const seed = address ? address.charCodeAt((r * 10 + c) % address.length) : 0
              return seed % 3 !== 0 ? (
                <rect key={`${r}-${c}`} x={c * 10} y={r * 10} width="9" height="9" rx="1" fill={color} opacity="0.85" />
              ) : null
            })
          )}
        </svg>
      </div>
      <p className="qr-box__label">Scan to receive {selectedToken}</p>
    </div>
  )

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={e => e.stopPropagation()}>
        <div className="modal__header">
          <h2 className="modal__title">Receive {selectedToken}</h2>
          <button className="modal__close" onClick={onClose}>✕</button>
        </div>
        {!isConnected ? (
          <p className="modal__hint">Connect your wallet first</p>
        ) : (
          <>
            {onKite && (
              <div className="modal__field">
                <label>Token</label>
                <div className="token-selector">
                  {tokens.map(t => (
                    <button
                      key={t}
                      className={`token-selector__btn ${selectedToken === t ? 'token-selector__btn--active' : ''}`}
                      style={selectedToken === t ? { borderColor: TOKEN_COLORS[t], color: TOKEN_COLORS[t] } : {}}
                      onClick={() => setSelectedToken(t)}
                    >
                      {t}
                    </button>
                  ))}
                </div>
              </div>
            )}
            <QRPlaceholder />
            <div className="address-box">
              <span className="address-box__text">{address}</span>
            </div>
            <button className="btn btn--primary btn--full" onClick={copy}>
              {copied ? '✓ Copied!' : 'Copy Address'}
            </button>
          </>
        )}
      </div>
    </div>
  )
}
