import { useState } from 'react'
import { useAppKitNetwork, useAppKitAccount, useAppKitProvider } from '@reown/appkit/react'
import { Contract, BrowserProvider, parseUnits, formatUnits } from 'ethers'
import type { Provider } from '@reown/appkit/react'

const KITE_TOKEN_ABI = [
  {
    inputs: [{ internalType: 'address', name: 'account', type: 'address' }],
    name: 'balanceOf',
    outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [
      { internalType: 'address', name: 'to', type: 'address' },
      { internalType: 'uint256', name: 'value', type: 'uint256' },
    ],
    name: 'transfer',
    outputs: [{ internalType: 'bool', name: '', type: 'bool' }],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [
      { internalType: 'address', name: 'spender', type: 'address' },
      { internalType: 'uint256', name: 'value', type: 'uint256' },
    ],
    name: 'approve',
    outputs: [{ internalType: 'bool', name: '', type: 'bool' }],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [],
    name: 'totalSupply',
    outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'name',
    outputs: [{ internalType: 'string', name: '', type: 'string' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'symbol',
    outputs: [{ internalType: 'string', name: '', type: 'string' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'decimals',
    outputs: [{ internalType: 'uint8', name: '', type: 'uint8' }],
    stateMutability: 'view',
    type: 'function',
  },
]

const KITE_CHAIN_IDS = [2368, 2366]
const KITE_TOKEN_ADDRESS = import.meta.env.VITE_KITE_TOKEN_ADDRESS || ''

interface KiteTokenPanelProps {
  sendKiteBalance?: (balance: string) => void
}

export const SmartContractActionButtonList = ({ sendKiteBalance }: KiteTokenPanelProps) => {
  const { isConnected, address } = useAppKitAccount()
  const { chainId } = useAppKitNetwork()
  const { walletProvider } = useAppKitProvider<Provider>('eip155')

  const [kiteBalance, setKiteBalance] = useState('')
  const [totalSupply, setTotalSupply] = useState('')
  const [recipient, setRecipient] = useState('')
  const [amount, setAmount] = useState('')
  const [txHash, setTxHash] = useState('')
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle')
  const [statusMsg, setStatusMsg] = useState('')

  const onKiteChain = chainId !== undefined && KITE_CHAIN_IDS.includes(Number(chainId))

  const getContract = async (withSigner = false) => {
    const provider = new BrowserProvider(walletProvider)
    if (withSigner) {
      const signer = await provider.getSigner()
      return new Contract(KITE_TOKEN_ADDRESS, KITE_TOKEN_ABI, signer)
    }
    return new Contract(KITE_TOKEN_ADDRESS, KITE_TOKEN_ABI, provider)
  }

  const handleGetBalance = async () => {
    if (!address || !KITE_TOKEN_ADDRESS) return
    setStatus('loading')
    setStatusMsg('Fetching KITE balance...')
    try {
      const contract = await getContract()
      const bal = await contract.balanceOf(address)
      const formatted = formatUnits(bal, 18)
      setKiteBalance(formatted)
      sendKiteBalance?.(`${parseFloat(formatted).toFixed(4)} KITE`)
      setStatus('success')
      setStatusMsg('')
    } catch (e) {
      setStatus('error')
      setStatusMsg('Failed to fetch balance')
    }
  }

  const handleGetTotalSupply = async () => {
    if (!KITE_TOKEN_ADDRESS) return
    setStatus('loading')
    setStatusMsg('Fetching total supply...')
    try {
      const contract = await getContract()
      const supply = await contract.totalSupply()
      setTotalSupply(parseFloat(formatUnits(supply, 18)).toLocaleString())
      setStatus('success')
      setStatusMsg('')
    } catch (e) {
      setStatus('error')
      setStatusMsg('Failed to fetch supply')
    }
  }

  const handleTransfer = async () => {
    if (!recipient || !amount || !KITE_TOKEN_ADDRESS) return
    setStatus('loading')
    setStatusMsg('Sending KITE tokens...')
    setTxHash('')
    try {
      const contract = await getContract(true)
      const tx = await contract.transfer(recipient, parseUnits(amount, 18))
      setStatusMsg('Transaction sent, waiting for confirmation...')
      await tx.wait()
      setTxHash(tx.hash)
      setStatus('success')
      setStatusMsg('Transfer successful!')
      setRecipient('')
      setAmount('')
      handleGetBalance()
    } catch (e: any) {
      setStatus('error')
      setStatusMsg(e?.reason || e?.message || 'Transfer failed')
    }
  }

  if (!isConnected) return null

  if (!onKiteChain) {
    return (
      <div className="token-panel token-panel--inactive">
        <div className="token-panel__header">
          <span className="token-badge">KITE</span>
          <span className="token-panel__title">KitePay Token</span>
        </div>
        <p className="token-panel__hint">Switch to Kite Testnet or Kite Mainnet to interact with KITE token</p>
      </div>
    )
  }

  if (!KITE_TOKEN_ADDRESS) {
    return (
      <div className="token-panel token-panel--warning">
        <div className="token-panel__header">
          <span className="token-badge">KITE</span>
          <span className="token-panel__title">KitePay Token</span>
        </div>
        <p className="token-panel__hint">Set <code>VITE_KITE_TOKEN_ADDRESS</code> in your .env to enable token actions</p>
      </div>
    )
  }

  return (
    <div className="token-panel">
      <div className="token-panel__header">
        <span className="token-badge">KITE</span>
        <span className="token-panel__title">KitePay Token</span>
        <span className="chain-badge">{chainId === 2368 ? 'Testnet' : 'Mainnet'}</span>
      </div>

      {/* Balance & Supply Row */}
      <div className="token-stats">
        <div className="token-stat">
          <span className="token-stat__label">Your Balance</span>
          <span className="token-stat__value">{kiteBalance ? `${parseFloat(kiteBalance).toFixed(4)} KITE` : '—'}</span>
        </div>
        <div className="token-stat">
          <span className="token-stat__label">Total Supply</span>
          <span className="token-stat__value">{totalSupply ? `${totalSupply} KITE` : '—'}</span>
        </div>
      </div>

      <div className="token-actions">
        <button className="btn btn--secondary" onClick={handleGetBalance} disabled={status === 'loading'}>
          Get Balance
        </button>
        <button className="btn btn--secondary" onClick={handleGetTotalSupply} disabled={status === 'loading'}>
          Total Supply
        </button>
      </div>

      {/* Transfer Form */}
      <div className="transfer-form">
        <h3 className="transfer-form__title">Transfer KITE</h3>
        <input
          className="input"
          type="text"
          placeholder="Recipient address (0x...)"
          value={recipient}
          onChange={(e) => setRecipient(e.target.value)}
        />
        <input
          className="input"
          type="number"
          placeholder="Amount (KITE)"
          min="0"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
        />
        <button
          className="btn btn--primary"
          onClick={handleTransfer}
          disabled={status === 'loading' || !recipient || !amount}
        >
          {status === 'loading' ? 'Processing...' : 'Send KITE'}
        </button>
      </div>

      {statusMsg && (
        <p className={`status-msg status-msg--${status}`}>{statusMsg}</p>
      )}

      {txHash && (
        <div className="tx-result">
          <span>Tx: </span>
          <a
            href={`https://${chainId === 2368 ? 'testnet.' : ''}kitescan.ai/tx/${txHash}`}
            target="_blank"
            rel="noreferrer"
            className="tx-link"
          >
            {txHash.slice(0, 14)}...{txHash.slice(-8)}
          </a>
        </div>
      )}
    </div>
  )
}
