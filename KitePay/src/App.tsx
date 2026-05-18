import { createAppKit, useAppKitAccount, useAppKitProvider, useAppKitNetwork, type Provider } from '@reown/appkit/react'
import React, { useState, useEffect, useRef, useCallback } from 'react'
import {
  LayoutDashboard, ArrowUpDown, ShieldCheck, Zap, Target,
  Hexagon, Settings, Home, Bot, ChevronLeft,
} from 'lucide-react'
import { BrowserProvider, formatEther } from 'ethers'
import { networks, projectId, metadata, ethersAdapter } from './config'
import { BalanceCard } from './components/BalanceCard'
import { QuickActions } from './components/QuickActions'
import { PaymentsWidget } from './components/PaymentsWidget'
import { TokenWidget } from './components/TokenWidget'
import { SendModal } from './components/SendModal'
import { ReceiveModal } from './components/ReceiveModal'
import { VaultWidget } from './components/VaultWidget'
import { PaymentsPage } from './pages/PaymentsPage'
import { SecurityPage } from './pages/SecurityPage'
import { DegensPage } from './pages/DegensPage'
import { MaturityPage } from './pages/MaturityPage'
import { TriellaPage } from './pages/TriellaPage'
import { SettingsPage } from './pages/SettingsPage'
import { AgentPage }   from './pages/AgentPage'
import './App.css'

createAppKit({
  adapters: [ethersAdapter],
  networks,
  metadata,
  projectId,
  themeMode: 'dark',
  features: { analytics: true, swaps: true, onramp: true, send: true },
  themeVariables: { '--w3m-accent': '#00C2D4', '--w3m-border-radius-master': '12px' },
})

type Page = 'home' | 'payments' | 'security' | 'degenerates' | 'maturity' | 'triella' | 'agent' | 'settings'
type Modal = 'send' | 'receive' | 'vault' | null

const PAGE_TITLES: Record<Page, string> = {
  home:        'Dashboard',
  payments:    'Payments',
  security:    'Security',
  degenerates: 'Degens',
  maturity:    'Maturity',
  triella:     'Triella',
  agent:       'AI Agent',
  settings:    'Settings',
}

const NAV_ITEMS: { id: Page; icon: React.ReactNode; label: string; highlight?: boolean }[] = [
  { id: 'home',        icon: <LayoutDashboard size={17} />, label: 'Home'     },
  { id: 'payments',    icon: <ArrowUpDown     size={17} />, label: 'Payments' },
  { id: 'security',    icon: <ShieldCheck     size={17} />, label: 'Security' },
  { id: 'degenerates', icon: <Zap             size={17} />, label: 'Degens'   },
  { id: 'maturity',    icon: <Target          size={17} />, label: 'Maturity' },
  { id: 'triella',     icon: <Hexagon         size={17} />, label: 'Triella'  },
  { id: 'agent',       icon: <Bot             size={17} />, label: 'AI Agent', highlight: true },
]

function HomeDashboard({
  nativeBalance,
  kiteBalance,
  usdcBalance,
  usdtBalance,
  onGetBalance,
  onKiteBalance,
  onUsdcBalance,
  onUsdtBalance,
  onModal,
  address,
}: {
  nativeBalance: string
  kiteBalance: string
  usdcBalance: string
  usdtBalance: string
  onGetBalance: () => void
  onKiteBalance: (b: string) => void
  onUsdcBalance: (b: string) => void
  onUsdtBalance: (b: string) => void
  onModal: (m: Modal) => void
  address: string | undefined
}) {
  const connected = !!address
  return (
    <main className="dashboard">
      <div className="dashboard__left">
        <BalanceCard
          nativeBalance={nativeBalance}
          kiteBalance={kiteBalance}
          usdcBalance={usdcBalance}
          usdtBalance={usdtBalance}
          onGetBalance={onGetBalance}
        />
        <QuickActions
          onSend={() => onModal('send')}
          onReceive={() => onModal('receive')}
          onVault={() => onModal('vault')}
          onPayments={() => onModal(null)}
        />
        <PaymentsWidget />
      </div>
      <div className="dashboard__right">
        <TokenWidget onKiteBalance={onKiteBalance} onUsdcBalance={onUsdcBalance} onUsdtBalance={onUsdtBalance} />
        <div className="passport-card">
          <div className="passport-card__header">
            <img src="/logo.png" alt="" className="passport-card__logo" />
            <div>
              <p className="passport-card__title">Kite Passport</p>
              <span className={`passport-card__status ${connected ? 'passport-card__status--active' : 'passport-card__status--disconnected'}`}>
                {connected ? 'Active' : 'Disconnected'}
              </span>
            </div>
          </div>
          <p className="passport-card__tagline">Elevate every payment</p>
          {connected && (
            <p className="passport-card__address">{address.slice(0, 6)}…{address.slice(-4)}</p>
          )}
          <div className="passport-card__glow" />
        </div>
      </div>
    </main>
  )
}

function Dashboard() {
  const [page, setPage] = useState<Page>('home')
  const [modal, setModal] = useState<Modal>(null)
  const [nativeBalance, setNativeBalance] = useState('')
  const [kiteBalance, setKiteBalance] = useState('')
  const [usdcBalance, setUsdcBalance] = useState('')
  const [usdtBalance, setUsdtBalance] = useState('')

  const { address } = useAppKitAccount()
  const { chainId } = useAppKitNetwork()
  const { walletProvider } = useAppKitProvider<Provider>('eip155')

  const handleGetBalance = useCallback(async () => {
    if (!walletProvider || !address) return
    try {
      const provider = new BrowserProvider(walletProvider)
      const bal = await provider.getBalance(address)
      const sym = [2368, 2366].includes(Number(chainId)) ? 'KITE' : 'ETH'
      setNativeBalance(`${parseFloat(formatEther(bal)).toFixed(4)} ${sym}`)
    } catch {
      setNativeBalance('—')
    }
  }, [walletProvider, address, chainId])

  useEffect(() => {
    if (address && walletProvider) {
      handleGetBalance()
    } else {
      setNativeBalance('')
      setKiteBalance('')
      setUsdcBalance('')
      setUsdtBalance('')
    }
  }, [address, chainId, walletProvider, handleGetBalance])

  const renderPage = () => {
    switch (page) {
      case 'payments': return <PaymentsPage />
      case 'security': return <SecurityPage />
      case 'degenerates': return <DegensPage />
      case 'maturity': return <MaturityPage />
      case 'triella':  return <TriellaPage />
      case 'agent':    return <AgentPage />
      case 'settings': return <SettingsPage />
      default: return (
        <HomeDashboard
          nativeBalance={nativeBalance}
          kiteBalance={kiteBalance}
          usdcBalance={usdcBalance}
          usdtBalance={usdtBalance}
          onGetBalance={handleGetBalance}
          onKiteBalance={setKiteBalance}
          onUsdcBalance={setUsdcBalance}
          onUsdtBalance={setUsdtBalance}
          onModal={setModal}
          address={address}
        />
      )
    }
  }

  return (
    <div className="app-shell">
      <div className="bg-canvas" aria-hidden>
        <div className="bg-blob bg-blob--1" />
        <div className="bg-blob bg-blob--2" />
        <div className="bg-blob bg-blob--3" />
      </div>
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar__brand">
          <img src="/logo.png" alt="KitePay" className="sidebar__logo" />
          <span className="sidebar__name">KitePay</span>
        </div>
        <nav className="sidebar__nav">
          {NAV_ITEMS.map(n => (
            <button
              key={n.id}
              className={`nav-item ${page === n.id ? 'nav-item--active' : ''} ${n.highlight ? 'nav-item--highlight' : ''}`}
              onClick={() => setPage(n.id)}
            >
              <span className="nav-item__icon">{n.icon}</span>
              <span className="nav-item__label">{n.label}</span>
              {n.highlight && <span className="nav-item__badge">AI</span>}
            </button>
          ))}
        </nav>
        <div className="sidebar__bottom">
          <button
            className={`nav-item ${page === 'settings' ? 'nav-item--active' : ''}`}
            onClick={() => setPage('settings')}
          >
            <span className="nav-item__icon"><Settings size={17} /></span>
            <span className="nav-item__label">Settings</span>
          </button>
        </div>
      </aside>

      {/* Main */}
      <div className="main-area">
        <header className="topbar">
          <div className="topbar__left">
            {page !== 'home' && (
              <button className="topbar__back" onClick={() => setPage('home')}>
                <ChevronLeft size={22} />
              </button>
            )}
            <img src="/logo.png" alt="KitePay" className="topbar__logo" />
            <h1 className="topbar__title">{PAGE_TITLES[page]}</h1>
          </div>
          <div className="topbar__right">
            <appkit-button />
          </div>
        </header>

        <div className="page-content">
          {renderPage()}
        </div>
      </div>

      {/* Bottom nav (mobile) */}
      <nav className="bottom-nav">
        {[
          { id: 'home' as Page,        icon: <Home         size={18} />, label: 'Home'     },
          { id: 'payments' as Page,    icon: <ArrowUpDown  size={18} />, label: 'Pay'      },
          { id: 'security' as Page,    icon: <ShieldCheck  size={18} />, label: 'Security' },
          { id: 'degenerates' as Page, icon: <Zap          size={18} />, label: 'Degens'   },
          { id: 'maturity' as Page,    icon: <Target       size={18} />, label: 'Maturity' },
          { id: 'triella' as Page,     icon: <Hexagon      size={18} />, label: 'Triella'  },
          { id: 'agent' as Page,       icon: <Bot          size={18} />, label: 'Agent'    },
          { id: 'settings' as Page,    icon: <Settings     size={18} />, label: 'Settings' },
        ].map(n => (
          <button
            key={n.id}
            className={`bottom-nav__item ${page === n.id ? 'bottom-nav__item--active' : ''}`}
            onClick={() => setPage(n.id)}
          >
            <span className="bottom-nav__icon">{n.icon}</span>
            <span className="bottom-nav__label">{n.label}</span>
          </button>
        ))}
      </nav>

      {/* Modals */}
      {modal === 'send' && <SendModal onClose={() => setModal(null)} />}
      {modal === 'receive' && <ReceiveModal onClose={() => setModal(null)} />}
      {modal === 'vault' && <VaultWidget onClose={() => setModal(null)} />}
    </div>
  )
}

const HEX_CHARS = '0123456789ABCDEF'
const RAIN_CHARS = '0123456789ABCDEF₿⟁∑Ξ⬡◈⬢'
const BRAND = 'KITEPAY'

const BOOT_LINES = [
  'INITIALIZING KITE CHAIN NODE...',
  'AUTHENTICATING KITE PASSPORT...',
  'LOADING AGENT PROTOCOLS...',
]

function MatrixRain({ active }: { active: boolean }) {
  const canvasRef = useRef<HTMLCanvasElement>(null)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')!

    const resize = () => {
      canvas.width  = window.innerWidth
      canvas.height = window.innerHeight
    }
    resize()
    window.addEventListener('resize', resize)

    const fontSize = 13
    const cols = Math.floor(canvas.width / fontSize)
    const drops = Array.from({ length: cols }, () => Math.random() * -50)

    let raf: number
    const draw = () => {
      ctx.fillStyle = 'rgba(2,4,8,0.18)'
      ctx.fillRect(0, 0, canvas.width, canvas.height)

      for (let i = 0; i < drops.length; i++) {
        const ch = RAIN_CHARS[Math.floor(Math.random() * RAIN_CHARS.length)]
        const y  = drops[i] * fontSize

        // bright leading char
        ctx.fillStyle = 'rgba(0,255,220,0.95)'
        ctx.font = `bold ${fontSize}px monospace`
        ctx.fillText(ch, i * fontSize, y)

        // dimmer trail char one step behind
        ctx.fillStyle = 'rgba(0,194,212,0.35)'
        ctx.font = `${fontSize}px monospace`
        ctx.fillText(
          RAIN_CHARS[Math.floor(Math.random() * RAIN_CHARS.length)],
          i * fontSize, y - fontSize
        )

        if (y > canvas.height && Math.random() > 0.975) drops[i] = 0
        drops[i] += 0.45
      }
      raf = requestAnimationFrame(draw)
    }

    if (active) draw()
    return () => { cancelAnimationFrame(raf); window.removeEventListener('resize', resize) }
  }, [active])

  return <canvas ref={canvasRef} className="splash__rain" />
}

function SplashScreen({ onDone }: { onDone: () => void }) {
  const [phase, setPhase]       = useState<'boot' | 'ignite' | 'reveal' | 'stable' | 'exit'>('boot')
  const [scramble, setScramble] = useState('·······')
  const [lineIdx, setLineIdx]   = useState(-1)
  const [progress, setProgress] = useState(0)
  const doneRef = useRef(false)

  // Phase timeline
  useEffect(() => {
    const t1 = setTimeout(() => setPhase('ignite'),  350)
    const t2 = setTimeout(() => setPhase('reveal'),  1100)
    const t3 = setTimeout(() => setPhase('stable'),  2300)
    const t4 = setTimeout(() => setPhase('exit'),    4000)
    const t5 = setTimeout(() => { if (!doneRef.current) { doneRef.current = true; onDone() } }, 4600)
    return () => { [t1,t2,t3,t4,t5].forEach(clearTimeout) }
  }, [onDone])

  // Wordmark scramble during reveal
  useEffect(() => {
    if (phase !== 'reveal') return
    let frame = 0
    const total = 24
    const id = setInterval(() => {
      frame++
      const resolved = Math.floor((frame / total) * BRAND.length)
      setScramble(BRAND.split('').map((ch, i) =>
        i < resolved ? ch : HEX_CHARS[Math.floor(Math.random() * 16)]
      ).join(''))
      if (frame >= total) { setScramble(BRAND); clearInterval(id) }
    }, 52)
    return () => clearInterval(id)
  }, [phase])

  useEffect(() => {
    if (phase === 'stable' || phase === 'exit') setScramble(BRAND)
  }, [phase])

  // Sequential boot lines during stable
  useEffect(() => {
    if (phase !== 'stable') return
    const timers = BOOT_LINES.map((_, i) =>
      setTimeout(() => setLineIdx(i), i * 380)
    )
    return () => timers.forEach(clearTimeout)
  }, [phase])

  // Progress bar during stable
  useEffect(() => {
    if (phase !== 'stable') return
    const start = Date.now()
    const duration = 1500
    const id = setInterval(() => {
      const p = Math.min(100, ((Date.now() - start) / duration) * 100)
      setProgress(p)
      if (p >= 100) clearInterval(id)
    }, 16)
    return () => clearInterval(id)
  }, [phase])

  return (
    <div className={`splash splash--${phase}`}>
      <MatrixRain active={phase !== 'exit'} />
      <div className="splash__vignette" />

      <div className="splash__center">
        {/* Logo + ring */}
        <div className="splash__logo-wrap">
          <div className="splash__ring splash__ring--1" />
          <div className="splash__ring splash__ring--2" />
          <img src="/logo.png" className="splash__logo" alt="KitePay" />
        </div>

        {/* Wordmark */}
        <p className="splash__wordmark">{scramble}</p>

        {/* Boot lines */}
        <div className="splash__lines">
          {BOOT_LINES.map((line, i) => (
            <div
              key={i}
              className={`splash__line ${i <= lineIdx ? 'splash__line--visible' : ''} ${i === BOOT_LINES.length - 1 && i <= lineIdx ? 'splash__line--ready' : ''}`}
            >
              <span className="splash__line-prefix">&gt;</span>
              <span>{line}</span>
              <span className="splash__line-status">
                {i < lineIdx ? '✓' : i === lineIdx && i < BOOT_LINES.length - 1 ? '···' : i === lineIdx ? 'READY' : ''}
              </span>
            </div>
          ))}
        </div>

        {/* Progress bar */}
        {phase === 'stable' || phase === 'exit' ? (
          <div className="splash__progress-wrap">
            <div className="splash__progress-bar">
              <div className="splash__progress-fill" style={{ width: `${progress}%` }} />
            </div>
            <span className="splash__progress-pct">{Math.round(progress)}%</span>
          </div>
        ) : null}
      </div>

      <div className="splash__flash" />
    </div>
  )
}

export function App() {
  const [ready, setReady] = useState(false)
  const handleDone = React.useCallback(() => setReady(true), [])
  return (
    <>
      {!ready && <SplashScreen onDone={handleDone} />}
      <div className={`app-wrapper ${ready ? 'app-wrapper--visible' : ''}`}>
        <Dashboard />
      </div>
    </>
  );
}
export default App
