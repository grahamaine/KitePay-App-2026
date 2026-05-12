import { useDisconnect, useAppKit, useAppKitNetwork, useAppKitAccount, useAppKitProvider, useAppKitNetworkCore, type Provider } from '@reown/appkit/react'
import { BrowserProvider, JsonRpcSigner, formatEther } from 'ethers'
import { kiteTestnet, networks } from '../config'

interface ActionButtonListProps {
  sendHash: (hash: string) => void
  sendSignMsg: (msg: string) => void
  sendBalance: (balance: string) => void
}

export const ActionButtonList = ({ sendHash, sendSignMsg, sendBalance }: ActionButtonListProps) => {
  const { disconnect } = useDisconnect()
  const { open } = useAppKit()
  const { chainId } = useAppKitNetworkCore()
  const { switchNetwork } = useAppKitNetwork()
  const { isConnected, address } = useAppKitAccount()
  const { walletProvider } = useAppKitProvider<Provider>('eip155')

  const handleDisconnect = async () => {
    try {
      await disconnect()
    } catch (error) {
      console.error('Disconnect failed:', error)
    }
  }

  const handleSignMsg = async () => {
    if (!walletProvider || !address) throw Error('Not connected')
    const provider = new BrowserProvider(walletProvider, chainId)
    const signer = new JsonRpcSigner(provider, address)
    const sig = await signer.signMessage('KitePay — Fly further with every payment')
    sendSignMsg(sig)
  }

  const handleGetBalance = async () => {
    if (!walletProvider || !address) throw Error('Not connected')
    const provider = new BrowserProvider(walletProvider, chainId)
    const balance = await provider.getBalance(address)
    const symbol = [2368, 2366].includes(Number(chainId)) ? 'KITE' : 'ETH'
    sendBalance(`${parseFloat(formatEther(balance)).toFixed(6)} ${symbol}`)
  }

  const handleSwitchToKite = () => switchNetwork(kiteTestnet)

  if (!isConnected) return null

  return (
    <div className="action-bar">
      <button className="btn btn--outline" onClick={() => open()}>Wallet</button>
      <button className="btn btn--outline" onClick={handleDisconnect}>Disconnect</button>
      <button className="btn btn--outline" onClick={handleSwitchToKite}>→ Kite Testnet</button>
      <button className="btn btn--outline" onClick={handleSignMsg}>Sign</button>
      <button className="btn btn--outline" onClick={handleGetBalance}>Balance</button>
    </div>
  )
}
