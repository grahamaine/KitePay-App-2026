import { createAppKit } from '@reown/appkit/react'
import { networks, projectId, metadata, ethersAdapter } from './config'
import { ActionButtonList } from './components/ActionButtonList'
import { SmartContractActionButtonList } from './components/SmartContractActionButtonList'
import { InfoList } from './components/InfoList'
import { useState } from 'react'
import './App.css'

createAppKit({
  adapters: [ethersAdapter],
  networks,
  metadata,
  projectId,
  themeMode: 'light',
  features: { analytics: true },
  themeVariables: { '--w3m-accent': '#00C2D4' },
})

export function App() {
  const [txHash, setTxHash] = useState('')
  const [signedMsg, setSignedMsg] = useState('')
  const [balance, setBalance] = useState('')
  const [kiteBalance, setKiteBalance] = useState('')

  return (
    <div className="app-shell">
      {/* Header */}
      <header className="app-header">
        <div className="app-header__brand">
          <div className="app-logo">K</div>
          <div>
            <h1 className="app-header__title">KitePay</h1>
            <p className="app-header__sub">Fly further with every payment</p>
          </div>
        </div>
        <appkit-button />
      </header>

      <main className="app-main">
        {/* Balance Hero */}
        {(balance || kiteBalance) && (
          <div className="balance-hero">
            {kiteBalance && (
              <div className="balance-hero__item">
                <span className="balance-hero__label">KITE Token</span>
                <span className="balance-hero__value">{kiteBalance}</span>
              </div>
            )}
            {balance && (
              <div className="balance-hero__item">
                <span className="balance-hero__label">Native Balance</span>
                <span className="balance-hero__value">{balance}</span>
              </div>
            )}
          </div>
        )}

        {/* Action bar */}
        <ActionButtonList
          sendHash={setTxHash}
          sendSignMsg={setSignedMsg}
          sendBalance={setBalance}
        />

        {/* KITE Token Panel */}
        <SmartContractActionButtonList sendKiteBalance={setKiteBalance} />

        {/* Info */}
        <InfoList hash={txHash} signedMsg={signedMsg} balance={balance} />

        <p className="app-footer-note">
          This projectId only works on localhost.{' '}
          <a href="https://dashboard.reown.com" target="_blank" rel="noreferrer" className="link">
            Get your own at Reown Dashboard
          </a>
        </p>
      </main>
    </div>
  )
}

export default App
