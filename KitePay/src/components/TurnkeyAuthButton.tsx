import { useState } from 'react'
import { useTurnkey } from '@turnkey/react-wallet-kit'

export const TurnkeyAuthButton = () => {
  const { session, user, handleLogin, logout } = useTurnkey()
  const [showMenu, setShowMenu] = useState(false)
  const [busy, setBusy] = useState(false)

  const email = (user as any)?.email ?? session?.userId ?? null
  const display = email
    ? email.length > 22 ? email.slice(0, 10) + '…' + email.slice(-8) : email
    : null

  const handleSignIn = async () => {
    try {
      await handleLogin()
    } catch { /* modal dismissed */ }
  }

  const handleSignOut = async () => {
    setBusy(true)
    try {
      await logout()
    } finally {
      setBusy(false)
      setShowMenu(false)
    }
  }

  if (!session) {
    return (
      <button className="tk-signin-btn" onClick={handleSignIn}>
        ✉ Email Login
      </button>
    )
  }

  return (
    <div className="tk-user" style={{ position: 'relative' }}>
      <button
        className="tk-user__chip"
        onClick={() => setShowMenu(m => !m)}
        title={email ?? 'Signed in'}
      >
        <span className="tk-user__dot" />
        <span className="tk-user__email">{display ?? 'Signed in'}</span>
        <span style={{ fontSize: 10, opacity: 0.6 }}>▾</span>
      </button>
      {showMenu && (
        <div className="tk-user__menu" onMouseLeave={() => setShowMenu(false)}>
          {email && <p className="tk-user__menu-email">{email}</p>}
          <button
            className="tk-user__menu-signout"
            onClick={handleSignOut}
            disabled={busy}
          >
            {busy ? 'Signing out…' : 'Sign Out'}
          </button>
        </div>
      )}
    </div>
  )
}
