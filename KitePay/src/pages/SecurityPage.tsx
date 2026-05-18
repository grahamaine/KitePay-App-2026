import { useState } from 'react'
import { useAppKitAccount, useDisconnect } from '@reown/appkit/react'

export const SecurityPage = () => {
  const { isConnected, address } = useAppKitAccount()
  const { disconnect } = useDisconnect()
  const [twoFA, setTwoFA] = useState(true)
  const [autoLock, setAutoLock] = useState(true)
  const [biometrics, setBiometrics] = useState(false)
  const [txConfirm, setTxConfirm] = useState(true)
  const [revokeMsg, setRevokeMsg] = useState('')

  const handleRevoke = async (label: string) => {
    await disconnect()
    setRevokeMsg(`Session "${label}" disconnected`)
    setTimeout(() => setRevokeMsg(''), 3000)
  }

  const handleRevokeAll = async () => {
    await disconnect()
    setRevokeMsg('All sessions disconnected')
    setTimeout(() => setRevokeMsg(''), 3000)
  }

  const short = address ? `${address.slice(0, 10)}...${address.slice(-6)}` : '—'

  return (
    <div className="page">
      <div className="page__header">
        <h2 className="page__title">Security</h2>
        <p className="page__sub">Manage your account protection</p>
      </div>

      {/* Wallet info */}
      <div className="widget">
        <div className="widget__header">
          <h3 className="widget__title">🔐 Connected Wallet</h3>
        </div>
        <div className="security-wallet">
          <div className="security-wallet__dot" style={{ background: isConnected ? '#22C55E' : '#EF4444' }} />
          <div>
            <p className="security-wallet__status">{isConnected ? 'Connected' : 'Not connected'}</p>
            {isConnected && <p className="security-wallet__addr">{short}</p>}
          </div>
        </div>
      </div>

      {/* Toggle settings */}
      <div className="widget">
        <div className="widget__header">
          <h3 className="widget__title">🛡 Protection Settings</h3>
        </div>
        <div className="toggle-list">
          {[
            { label: '2-Factor Authentication', sub: 'Require OTP on login', val: twoFA, set: setTwoFA },
            { label: 'Auto-Lock', sub: 'Lock after 5 minutes of inactivity', val: autoLock, set: setAutoLock },
            { label: 'Biometric Auth', sub: 'Use fingerprint or face ID', val: biometrics, set: setBiometrics },
            { label: 'Transaction Confirmation', sub: 'Always confirm before sending', val: txConfirm, set: setTxConfirm },
          ].map(({ label, sub, val, set }) => (
            <div key={label} className="toggle-item">
              <div className="toggle-item__info">
                <span className="toggle-item__label">{label}</span>
                <span className="toggle-item__sub">{sub}</span>
              </div>
              <button
                className={`toggle ${val ? 'toggle--on' : ''}`}
                onClick={() => set(!val)}
                aria-label={label}
              >
                <span className="toggle__thumb" />
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* Session info */}
      <div className="widget">
        <div className="widget__header">
          <h3 className="widget__title">📋 Active Sessions</h3>
          <button className="btn btn--secondary" style={{ fontSize: '12px', padding: '6px 12px' }} onClick={handleRevokeAll} disabled={!isConnected}>
            Revoke All
          </button>
        </div>
        {revokeMsg && <p className="status-msg status-msg--success" style={{ marginBottom: 8 }}>{revokeMsg}</p>}
        {[
          { device: 'Chrome on Windows', location: 'Kampala, UG', time: 'Now', current: true },
          { device: 'KitePay Mobile App', location: 'Kampala, UG', time: '2h ago', current: false },
        ].map(s => (
          <div key={s.device} className="session-item">
            <span className="session-item__icon">{s.current ? '💻' : '📱'}</span>
            <div className="session-item__info">
              <p className="session-item__device">{s.device} {s.current && <span className="badge-current">Current</span>}</p>
              <p className="session-item__meta">{s.location} · {s.time}</p>
            </div>
            {!s.current && (
              <button className="btn-ghost" style={{ color: '#EF4444' }} onClick={() => handleRevoke(s.device)} disabled={!isConnected}>
                Revoke
              </button>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}
