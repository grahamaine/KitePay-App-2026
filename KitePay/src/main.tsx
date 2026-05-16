import { StrictMode, Component } from 'react'
import type { ReactNode, ErrorInfo } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'

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
          <img src={`${import.meta.env.BASE_URL}logo.png`} style={{ width: 56, borderRadius: 12 }} alt="" />
          <h2 style={{ color: '#00C2D4', margin: 0 }}>KitePay failed to load</h2>
          <pre style={{
            background: '#111827', padding: '1rem', borderRadius: 8, maxWidth: '90vw',
            overflowX: 'auto', fontSize: 12, color: '#EF4444', whiteSpace: 'pre-wrap', wordBreak: 'break-word'
          }}>
            {(error as Error).message}
            {'\n\n'}
            {(error as Error).stack}
          </pre>
          <button
            onClick={() => window.location.reload()}
            style={{ background: '#00C2D4', color: '#0B0F1E', border: 'none', padding: '0.6rem 1.4rem', borderRadius: 8, cursor: 'pointer', fontWeight: 600 }}
          >
            Reload
          </button>
        </div>
      )
    }
    return this.props.children
  }
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ErrorBoundary>
      <App />
    </ErrorBoundary>
  </StrictMode>,
)
