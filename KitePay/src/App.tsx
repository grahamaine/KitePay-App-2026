import { createAppKit, useAppKitAccount, useAppKitProvider, useAppKitNetworkCore, type Provider } from '@reown/appkit/react'
import React, { useState, useEffect, useRef } from 'react'
import {
  LayoutDashboard, ArrowUpDown, ShieldCheck, Zap, Target,
  Hexagon, Settings, Home, Bot,
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
  features: { analytics: true },
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
  onGetBalance,
  onKiteBalance,
  onModal,
  address,
}: {
  nativeBalance: string
  kiteBalance: string
  onGetBalance: () => void
  onKiteBalance: (b: string) => void
  onModal: (m: Modal) => void
  address: string | undefined
}) {
  const connected = !!address
  return (
    <main className="dashboard">
      <div className="dashboard__left">
        <BalanceCard nativeBalance={nativeBalance} kiteBalance={kiteBalance} onGetBalance={onGetBalance} />
        <QuickActions
          onSend={() => onModal('send')}
          onReceive={() => onModal('receive')}
          onVault={() => onModal('vault')}
          onPayments={() => onModal(null)}
        />
        <PaymentsWidget />
      </div>
      <div className="dashboard__right">
        <TokenWidget onKiteBalance={onKiteBalance} />
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

  const { address } = useAppKitAccount()
  const { chainId } = useAppKitNetworkCore()
  const { walletProvider } = useAppKitProvider<Provider>('eip155')

  const handleGetBalance = async () => {
    if (!walletProvider || !address) return
    const provider = new BrowserProvider(walletProvider, chainId)
    const bal = await provider.getBalance(address)
    const sym = [2368, 2366].includes(Number(chainId)) ? 'KITE' : 'ETH'
    setNativeBalance(`${parseFloat(formatEther(bal)).toFixed(4)} ${sym}`)
  }

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
          onGetBalance={handleGetBalance}
          onKiteBalance={setKiteBalance}
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
          { id: 'home' as Page,        icon: <Home         size={20} />, label: 'Home'     },
          { id: 'payments' as Page,    icon: <ArrowUpDown  size={20} />, label: 'Payments' },
          { id: 'degenerates' as Page, icon: <Zap          size={20} />, label: 'Degens'   },
          { id: 'settings' as Page,    icon: <Settings     size={20} />, label: 'Settings' },
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
const BRAND = 'KITEPAY'

function SplashScreen({ onDone }: { onDone: () => void }) {
  const [phase, setPhase] = useState<'boot' | 'reveal' | 'stable' | 'exit'>('boot')
  const [scramble, setScramble] = useState('·······')
  const [hexAddr, setHexAddr] = useState('0x????????????????')
  const doneRef = useRef(false)

  useEffect(() => {
    const t1 = setTimeout(() => setPhase('reveal'), 300)
    const t2 = setTimeout(() => setPhase('stable'), 1500)
    const t3 = setTimeout(() => setPhase('exit'), 2600)
    const t4 = setTimeout(() => { if (!doneRef.current) { doneRef.current = true; onDone() } }, 3200)
    return () => { clearTimeout(t1); clearTimeout(t2); clearTimeout(t3); clearTimeout(t4) }
  }, [onDone])

  // Hex address ticker
  useEffect(() => {
    const id = setInterval(() => {
      setHexAddr('0x' + Array.from({ length: 16 }, () => HEX_CHARS[Math.floor(Math.random() * 16)]).join(''))
    }, 90)
    return () => clearInterval(id)
  }, [])

  // Scramble wordmark during reveal
  useEffect(() => {
    if (phase !== 'reveal') return
    let frame = 0
    const total = 22
    const id = setInterval(() => {
      frame++
      const resolved = Math.floor((frame / total) * BRAND.length)
      setScramble(BRAND.split('').map((ch, i) =>
        i < resolved ? ch : HEX_CHARS[Math.floor(Math.random() * 16)]
      ).join(''))
      if (frame >= total) { setScramble(BRAND); clearInterval(id) }
    }, 55)
    return () => clearInterval(id)
  }, [phase])

  useEffect(() => {
    if (phase === 'stable' || phase === 'exit') setScramble(BRAND)
  }, [phase])

  return (
    <div className={`splash splash--${phase}`}>
      <div className="splash__grid" />
      <div className="splash__scanline" />
      <img src="/logo.png" className="splash__logo" alt="KitePay" />
      <p className="splash__wordmark">{scramble}</p>
      <p className="splash__hex">{hexAddr}</p>
      <div className="splash__status">
        <span className="splash__cursor" />
        <span>INITIALIZING SECURE CHANNEL</span>
      </div>
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
