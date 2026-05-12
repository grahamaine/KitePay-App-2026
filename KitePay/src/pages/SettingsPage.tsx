import { useState } from 'react'
import { useAppKitAccount } from '@reown/appkit/react'
import { useAppKitNetwork } from '@reown/appkit/react'
import { kiteTestnet, kiteMainnet } from '../config'

export const SettingsPage = () => {
  const { address, isConnected } = useAppKitAccount()
  const { chainId, switchNetwork } = useAppKitNetwork()
  const [currency, setCurrency] = useState('USD')
  const [language, setLanguage] = useState('en')
  const [notifications, setNotifications] = useState(true)
  const [darkMode] = useState(true)

  const onKiteTestnet = Number(chainId) === 2368
  const onKiteMainnet = Number(chainId) === 2366

  return (
    <div className="page">
      <div className="page__header">
        <h2 className="page__title">⚙ Settings</h2>
        <p className="page__sub">Customize your KitePay experience</p>
      </div>

      {/* Account */}
      <div className="widget">
        <div className="widget__header"><h3 className="widget__title">👤 Account</h3></div>
        <div className="settings-row">
          <span className="settings-row__label">Wallet</span>
          <span className="settings-row__value" style={{ fontFamily: 'monospace', fontSize: 12 }}>
            {isConnected && address ? `${address.slice(0, 10)}...${address.slice(-6)}` : 'Not connected'}
          </span>
        </div>
        <div className="settings-row">
          <span className="settings-row__label">Status</span>
          <span style={{ color: isConnected ? '#22C55E' : '#EF4444', fontWeight: 600, fontSize: 13 }}>
            {isConnected ? '● Connected' : '○ Disconnected'}
          </span>
        </div>
      </div>

      {/* Network */}
      <div className="widget">
        <div className="widget__header"><h3 className="widget__title">🌐 Network</h3></div>
        <div className="network-btns">
          <button
            className={`network-btn ${onKiteTestnet ? 'network-btn--active' : ''}`}
            onClick={() => switchNetwork(kiteTestnet)}
          >
            <span>Kite Testnet</span>
            <span className="network-btn__id">2368</span>
          </button>
          <button
            className={`network-btn ${onKiteMainnet ? 'network-btn--active' : ''}`}
            onClick={() => switchNetwork(kiteMainnet)}
          >
            <span>Kite Mainnet</span>
            <span className="network-btn__id">2366</span>
          </button>
        </div>
        <p className="widget__hint" style={{ textAlign: 'left', marginTop: 10 }}>
          Current chain ID: <strong style={{ color: '#fff' }}>{chainId ?? '—'}</strong>
        </p>
      </div>

      {/* Preferences */}
      <div className="widget">
        <div className="widget__header"><h3 className="widget__title">🎨 Preferences</h3></div>

        <div className="settings-row">
          <span className="settings-row__label">Currency</span>
          <select className="select select--sm" value={currency} onChange={e => setCurrency(e.target.value)}>
            {['USD', 'EUR', 'GBP', 'UGX', 'KES'].map(c => <option key={c}>{c}</option>)}
          </select>
        </div>

        <div className="settings-row">
          <span className="settings-row__label">Language</span>
          <select className="select select--sm" value={language} onChange={e => setLanguage(e.target.value)}>
            <option value="en">English</option>
            <option value="fr">Français</option>
            <option value="es">Español</option>
            <option value="ar">العربية</option>
            <option value="zh">中文</option>
          </select>
        </div>

        <div className="settings-row">
          <span className="settings-row__label">Dark Mode</span>
          <span style={{ color: darkMode ? '#00C2D4' : '#6B7280', fontWeight: 600, fontSize: 13 }}>
            {darkMode ? 'On' : 'Off'}
          </span>
        </div>

        <div className="settings-row">
          <span className="settings-row__label">Push Notifications</span>
          <button
            className={`toggle ${notifications ? 'toggle--on' : ''}`}
            onClick={() => setNotifications(!notifications)}
          >
            <span className="toggle__thumb" />
          </button>
        </div>
      </div>

      {/* About */}
      <div className="widget">
        <div className="widget__header"><h3 className="widget__title">ℹ About</h3></div>
        <div className="settings-row"><span className="settings-row__label">Version</span><span className="settings-row__value">1.0.0</span></div>
        <div className="settings-row"><span className="settings-row__label">Network</span><span className="settings-row__value">Kite Chain</span></div>
        <div className="settings-row">
          <span className="settings-row__label">Contract</span>
          <a href="https://testnet.kitescan.ai/address/0x0105FBf3EDF5297870066ef351E5ca6399b9FF8b" target="_blank" rel="noreferrer" style={{ color: '#00C2D4', fontSize: 12, fontFamily: 'monospace' }}>
            0x0105...FF8b ↗
          </a>
        </div>
      </div>
    </div>
  )
}
