import { StrictMode, Component } from 'react'
import type { ReactNode, ErrorInfo } from 'react'
import { createRoot } from 'react-dom/client'
import { TurnkeyProvider } from '@turnkey/react-wallet-kit'
import '@turnkey/react-wallet-kit/styles.css'

const turnkeyConfig = {
  organizationId: import.meta.env.VITE_TURNKEY_ORG_ID as string,
  authProxyConfigId: import.meta.env.VITE_TURNKEY_CONFIG_ID as string,
}

class ErrorBoundary extends Component<{ children: ReactNode }, { error: Error | null }> {
  state = { error: null }
  static getDerivedStateFromError(error: Error) { return { error } }
  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error('[KitePay crash]', error, info)
  }
  render() {
    const { error } = this.state
    if (error) {
      return (
        <div style={{
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
          height: '100vh', background: '#0B0F1E', color: '#fff', fontFamily: 'monospace', padding: '2rem', gap: '1rem'
        }}>
          <h2 style={{ color: '#EF4444', margin: 0 }}>KitePay failed to load</h2>
          <pre style={{
            background: '#111827', padding: '1rem', borderRadius: 8, maxWidth: '90vw',
            overflow: 'auto', fontSize: 12, color: '#fca5a5', whiteSpace: 'pre-wrap', wordBreak: 'break-word'
          }}>
            {(error as Error).message}{'\n\n'}{(error as Error).stack}
          </pre>
          <button onClick={() => window.location.reload()}
            style={{ background: '#00C2D4', color: '#0B0F1E', border: 'none', padding: '0.6rem 1.4rem', borderRadius: 8, cursor: 'pointer', fontWeight: 600 }}>
            Reload
          </button>
        </div>
      )
    }
    return this.props.children
  }
}

// Purge stale WalletConnect sessions when the project ID changes.
// Stale sessions cause isValidSessionTopic errors on the relay websocket.
function clearStaleWcSessions() {
  try {
    const PROJECT_ID = import.meta.env.VITE_PROJECT_ID || '330707bcc383f56d2f8710e23161f96b'
    const CACHE_KEY  = '__kp_wc_pid'
    if (localStorage.getItem(CACHE_KEY) !== PROJECT_ID) {
      Object.keys(localStorage)
        .filter(k => k.startsWith('wc@2') || k.startsWith('W3M') || k.startsWith('wagmi'))
        .forEach(k => localStorage.removeItem(k))
      localStorage.setItem(CACHE_KEY, PROJECT_ID)
    }
  } catch { /* localStorage may be blocked in some browsers */ }
}
clearStaleWcSessions()

// Dynamic import catches module-level throws (e.g. createAppKit failing)
import('./App').then(({ App }) => {
  createRoot(document.getElementById('root')!).render(
    <StrictMode>
      <ErrorBoundary>
        <TurnkeyProvider config={turnkeyConfig}>
          <App />
        </TurnkeyProvider>
      </ErrorBoundary>
    </StrictMode>,
  )
}).catch((err: unknown) => {
  const e = err instanceof Error ? err : new Error(String(err))
  window.__kitepay_err?.(e.message, '', 0, 0, e)
})
