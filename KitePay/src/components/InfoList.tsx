import { useEffect, useState } from 'react'
import {
  useAppKitState,
  useAppKitTheme,
  useAppKitEvents,
  useAppKitAccount,
  useWalletInfo,
  useAppKitProvider,
  useAppKitNetworkCore,
  type Provider,
} from '@reown/appkit/react'
import { BrowserProvider } from 'ethers'

interface InfoListProps {
  hash: string
  signedMsg: string
  balance: string
}

const EXPLORER: Record<number, string> = {
  2368: 'https://testnet.kitescan.ai',
  2366: 'https://kitescan.ai',
  11155111: 'https://sepolia.etherscan.io',
  1: 'https://etherscan.io',
}

export const InfoList = ({ hash, signedMsg, balance }: InfoListProps) => {
  const [statusTx, setStatusTx] = useState('')

  const { themeMode, themeVariables } = useAppKitTheme()
  const state = useAppKitState()
  const { chainId } = useAppKitNetworkCore()
  const { address, caipAddress, isConnected, embeddedWalletInfo } = useAppKitAccount()
  const events = useAppKitEvents()
  const walletInfo = useWalletInfo()
  const { walletProvider } = useAppKitProvider<Provider>('eip155')

  const explorerBase = chainId ? EXPLORER[Number(chainId)] ?? '' : ''

  useEffect(() => {
    console.log('Events:', events)
  }, [events])

  useEffect(() => {
    const checkTxStatus = async () => {
      if (hash && walletProvider) {
        try {
          const provider = new BrowserProvider(walletProvider, chainId)
          const receipt = await provider.getTransactionReceipt(hash)
          setStatusTx(
            receipt?.status === 1 ? 'Success ✓' : receipt?.status === 0 ? 'Failed ✗' : 'Pending…'
          )
        } catch {
          setStatusTx('Error')
        }
      }
    }
    checkTxStatus()
  }, [hash, walletProvider, chainId])

  return (
    <>
      {hash && (
        <section>
          <h2>Last Transaction</h2>
          <pre>
            {explorerBase ? (
              <>
                {'Hash: '}
                <a href={`${explorerBase}/tx/${hash}`} target="_blank" rel="noreferrer" className="tx-link">
                  {hash.slice(0, 14)}…{hash.slice(-8)}
                </a>
                {`\nStatus: ${statusTx}`}
              </>
            ) : (
              `Hash: ${hash}\nStatus: ${statusTx}`
            )}
          </pre>
        </section>
      )}

      {signedMsg && (
        <section>
          <h2>Signed Message</h2>
          <pre>{signedMsg}</pre>
        </section>
      )}

      {balance && (
        <section>
          <h2>Native Balance</h2>
          <pre>{balance}</pre>
        </section>
      )}

      <section>
        <h2>Account</h2>
        <pre>
          {`Address:   ${address ?? '—'}\n`}
          {`CAIP:      ${caipAddress ?? '—'}\n`}
          {`Connected: ${isConnected}\n`}
          {embeddedWalletInfo?.accountType ? `Type:      ${embeddedWalletInfo.accountType}\n` : ''}
          {embeddedWalletInfo?.user?.email ? `Email:     ${embeddedWalletInfo.user.email}\n` : ''}
          {embeddedWalletInfo?.authProvider ? `Provider:  ${embeddedWalletInfo.authProvider}\n` : ''}
        </pre>
      </section>

      <section>
        <h2>Network</h2>
        <pre>
          {`Chain ID:  ${chainId ?? '—'}\n`}
          {explorerBase ? `Explorer:  ${explorerBase}\n` : ''}
          {`Active:    ${state.activeChain ?? '—'}\n`}
          {`Selected:  ${state.selectedNetworkId ?? '—'}`}
        </pre>
      </section>

      <section>
        <h2>Wallet</h2>
        <pre>
          {`Name:      ${walletInfo.walletInfo?.name ?? '—'}\n`}
          {`Theme:     ${themeMode}\n`}
          {`Accent:    ${themeVariables?.['--w3m-accent'] ?? '—'}`}
        </pre>
      </section>
    </>
  )
}
