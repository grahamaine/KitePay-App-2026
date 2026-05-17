import { sepolia } from '@reown/appkit/networks'
import type { AppKitNetwork } from '@reown/appkit/networks'
import { EthersAdapter } from '@reown/appkit-adapter-ethers'

export const projectId = import.meta.env.VITE_PROJECT_ID || "7b1e50998db0cb3bfff97d58635c4b56"

if (!projectId) {
  throw new Error('Project ID is not defined')
}

export const metadata = {
  name: 'KitePay',
  description: 'KitePay — Fly further with every payment',
  url: 'https://kitepay.vercel.app',
  icons: ['https://kitepay.vercel.app/icon-192.png'],
}

export const kiteTestnet: AppKitNetwork = {
  id: 2368,
  name: 'Kite Testnet',
  nativeCurrency: { name: 'KITE', symbol: 'KITE', decimals: 18 },
  rpcUrls: {
    default: { http: ['https://rpc-testnet.gokite.ai'] },
  },
  blockExplorers: {
    default: { name: 'KiteScan', url: 'https://testnet.kitescan.ai' },
  },
}

export const kiteMainnet: AppKitNetwork = {
  id: 2366,
  name: 'Kite',
  nativeCurrency: { name: 'KITE', symbol: 'KITE', decimals: 18 },
  rpcUrls: {
    default: { http: ['https://rpc.gokite.ai'] },
  },
  blockExplorers: {
    default: { name: 'KiteScan', url: 'https://kitescan.ai' },
  },
}

export const networks = [kiteTestnet, kiteMainnet, sepolia] as [AppKitNetwork, ...AppKitNetwork[]]

export const ethersAdapter = new EthersAdapter()