import { useState } from 'react'
import { useAppKitAccount } from '@reown/appkit/react'

interface ReceiveModalProps { onClose: () => void }

export const ReceiveModal = ({ onClose }: ReceiveModalProps) => {
  const { address, isConnected } = useAppKitAccount()
  const [copied, setCopied] = useState(false)

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
                <rect key={`${r}-${c}`} x={c * 10} y={r * 10} width="9" height="9" rx="1" fill="#00C2D4" opacity="0.85" />
              ) : null
            })
          )}
        </svg>
      </div>
      <p className="qr-box__label">Scan to receive KITE</p>
    </div>
  )

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={e => e.stopPropagation()}>
        <div className="modal__header">
          <h2 className="modal__title">Receive KITE</h2>
          <button className="modal__close" onClick={onClose}>✕</button>
        </div>
        {!isConnected ? (
          <p className="modal__hint">Connect your wallet first</p>
        ) : (
          <>
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
