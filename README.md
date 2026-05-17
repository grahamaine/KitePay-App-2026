<p align="center">
  <img src="KitePay/public/logo.png" alt="KitePay" width="96" style="border-radius:20px"/>
</p>

<h1 align="center">KitePay — Fly Further With Every Payment</h1>

<p align="center">
  <img src="KitePay%20main%20Logo.png" alt="KitePay — Elevate Every Payment" width="720"/>
</p>

<p align="center">
  <strong>Autonomous AI payment wallet built natively on Kite Chain</strong><br/>
  React web dApp · Flutter mobile app · ERC-20 smart contract · AI agent payments · Kite Passport identity
</p>

<p align="center">
  <a href="https://kitepay.vercel.app"><img src="https://img.shields.io/badge/Live%20App-kitepay.vercel.app-00C2D4?style=flat-square&logo=vercel" /></a>
  <img src="https://img.shields.io/badge/Chain-Kite%20Testnet%202368-F0B429?style=flat-square" />
  <img src="https://img.shields.io/badge/AI-Llama%203.3%20%E2%80%A2%20Groq-8B5CF6?style=flat-square" />
  <img src="https://img.shields.io/badge/Passport-Kite%20Passport-22C55E?style=flat-square" />
  <img src="https://img.shields.io/badge/Protocol-x402%20HTTP-F97316?style=flat-square" />
  <img src="https://img.shields.io/badge/React-19-61DAFB?style=flat-square&logo=react" />
  <img src="https://img.shields.io/badge/Flutter-3.x-027DFD?style=flat-square&logo=flutter" />
</p>

---

## Overview

KitePay is a full-stack autonomous AI payment platform built on **Kite Chain** (EVM-compatible, chainId 2368/2366). It demonstrates the complete agentic commerce loop — an LLM agent that pays for what it needs, stays within delegated spending limits enforced by Kite Passport, and commits every decision to Kite Chain as an immutable attestation.

| Component | Description |
|-----------|-------------|
| **React Web dApp** | Browser + mobile-responsive dashboard with wallet connect, AI agent, Kite Passport panel |
| **AI Agent** | Llama 3.3-70b (Groq) tool-use loop — calls paid oracles, attests results on-chain |
| **x402 Services** | Serverless price, DeFi, and sentiment oracles behind HTTP 402 payment gates |
| **Kite Passport** | Passkey-secured agent identity with session-based spending delegation |
| **On-chain Attestations** | keccak256 proofs written to Kite Testnet after every AI analysis |
| **Flutter Mobile App** | iOS/Android wallet with embedded EVM wallets, send/receive, staking |
| **KitePayToken** | ERC-20 KITE token deployed on Kite Testnet |
| **Dart SDK** | `kitepay_sdk` — REST client for KitePay payment gateway |

---

## Live Links

| Resource | URL |
|----------|-----|
| 🌐 Web App | [kitepay.vercel.app](https://kitepay.vercel.app) |
| 🔗 Contract (Testnet) | [0x0105FBf3...FF8b](https://testnet.kitescan.ai/address/0x0105FBf3EDF5297870066ef351E5ca6399b9FF8b) |
| 🔍 Explorer | [testnet.kitescan.ai](https://testnet.kitescan.ai) |
| 🛂 Kite Passport | [agentpassport.ai](https://agentpassport.ai) |
| 💧 Testnet Faucet | [faucet.gokite.ai](https://faucet.gokite.ai) |

---

## Features

### 🤖 AI Agent (`api/agent.ts`)

A fully autonomous agent that runs a complete **intelligence → pay → attest** loop:

1. **Task intake** — user submits a market intelligence task via the web UI
2. **LLM reasoning** — Llama 3.3-70b (Groq) decides which paid data sources to call
3. **x402 micropayments** — each service returns `402 Payment Required`; agent pays 0.0001 KITE autonomously
4. **Live data ingestion** — real CoinGecko prices, DeFiLlama yields, Fear & Greed index flow back after on-chain payment verification
5. **On-chain attestation** — final analysis committed as `keccak256(task::result::timestamp)` to Kite Testnet
6. **SSE streaming** — every step (`thinking → calling → paying → paid → data → attesting → attested → complete`) streams to the UI in real time

#### Paid Oracles (`api/services/`)

| Service | Endpoint | Data |
|---------|----------|------|
| Price Oracle | `/api/services/price` | BTC/ETH/SOL/BNB live prices + 24h change (CoinGecko) |
| DeFi Scanner | `/api/services/defi` | Top yield opportunities from 500+ protocols (DeFiLlama) |
| Sentiment Oracle | `/api/services/sentiment` | Fear & Greed index + 7-day trend + trending coins |

### 🛂 Kite Passport Integration

Passkey-secured identity and spending delegation for AI agents:

- **Session creation** — `kpass agent:session create` generates a spending policy (max per tx, total budget, TTL)
- **Passkey approval** — user approves via device biometrics at `agentpassport.ai`
- **Session binding** — session ID pasted into the KitePay Passport panel; passed with every agent request
- **Identity display** — connected state shows session ID, expiry, x402 auth chip, and "Passport Active" stat

### 💳 Web dApp (`KitePay/`)

- **Cinematic splash screen** — canvas matrix rain, logo materialisation with glitch rings, sequential boot lines, animated progress bar
- **Mobile-first layout** — hamburger dropdown menu on mobile (≤768 px) replaces scrolling bottom tab bar; Reown wallet connect modal works above all UI layers
- **AI Agent page** — Kite Passport panel, quick task chips, real-time execution log, result with on-chain attestation proof link
- **Dashboard widgets** — balance card (native + KITE), quick-action buttons (Send / Receive / Vault)
- **Payments** — searchable, filterable transaction history
- **Degens** — token swap UI and liquidity pool browser
- **Maturity** — staking APY calculator (Flexible / 30d / 90d / 1yr)
- **Triella** — portfolio allocation breakdown and activity log
- **Security** — 2FA toggles, session management, auto-lock
- **Settings** — network switcher (Kite Testnet / Mainnet / Sepolia)
- **Kite Chain integration** — Reown AppKit v1, WalletConnect v2, ethers.js v6

### 📱 Flutter Mobile App (`lib/`)

- Embedded EVM wallets (BIP39 mnemonic / private key import)
- Send & Receive KITE with QR codes
- Transaction history via KiteScan API
- AI Agent screen with x402 HTTP payment protocol
- USDC service with daily/per-tx spending limits
- Identity service — on-chain agent attestation
- Firebase auth (email OTP + password)
- Multi-language (EN, FR, ES, AR, ZH)

### ⛓ Smart Contract (`contracts-hardhat/`)

- **KitePayToken (KITE)** — ERC-20, 1,000,000 initial supply
- Deployed on Kite Testnet: `0x0105FBf3EDF5297870066ef351E5ca6399b9FF8b`
- Hardhat + Turnkey for deployment key management

---

## Tech Stack

| Layer | Technologies |
|-------|-------------|
| Web UI | React 19, TypeScript, Vite 7, Oswald font, Lucide icons |
| Blockchain | Kite Chain (EVM, 2368/2366), ethers.js v6, Reown AppKit v1 |
| Wallet Connect | WalletConnect v2, MetaMask, mobile deep-links |
| AI Agent | Llama 3.3-70b via Groq API, tool-use loop, SSE streaming |
| Agent Identity | Kite Passport (kpass CLI), passkey auth, x402_http sessions |
| Payment Protocol | HTTP 402 x402, KITE ERC-20 micropayments |
| Data Sources | CoinGecko (prices), DeFiLlama (yields), alternative.me (Fear & Greed) |
| Attestations | keccak256 self-send tx as calldata on Kite Testnet |
| Serverless | Vercel Functions (Node.js, TypeScript) |
| Mobile | Flutter 3.x, Dart, web3dart, Firebase, FlutterSecureStorage |
| Wallet Infra | Turnkey (key management), Reown AppKit |
| Deploy | Vercel (web + API, auto-deploy from `main`) |

---

## Project Structure

```
KitePay-App-2026/
├── api/                            # Vercel serverless functions
│   ├── agent.ts                    # AI agent — Groq tool-use loop + SSE streaming
│   ├── lib/
│   │   └── chain.ts                # Kite chain helpers (wallet, pay, attest, verify)
│   └── services/
│       ├── price.ts                # x402 price oracle  (CoinGecko)
│       ├── defi.ts                 # x402 DeFi yield scanner (DeFiLlama)
│       └── sentiment.ts            # x402 sentiment oracle (Fear & Greed + trending)
│
├── KitePay/                        # React web dApp (Vite + TypeScript)
│   ├── src/
│   │   ├── App.tsx                 # Root — splash, routing, sidebar, hamburger nav
│   │   ├── App.css                 # Dark theme — mobile-first, agent, passport styles
│   │   ├── config/index.tsx        # Networks + Reown AppKit config
│   │   ├── components/             # BalanceCard, QuickActions, Modals, Widgets
│   │   └── pages/
│   │       ├── AgentPage.tsx       # AI Agent UI — Passport panel + execution log
│   │       ├── PaymentsPage.tsx
│   │       ├── SecurityPage.tsx
│   │       ├── DegensPage.tsx
│   │       ├── MaturityPage.tsx
│   │       ├── TriellaPage.tsx
│   │       └── SettingsPage.tsx
│   └── public/
│       ├── logo.png                # App icon (used in sidebar, topbar, splash)
│       └── icon-*.png              # PWA icons (16 → 1024 px)
│
├── lib/                            # Flutter mobile app
│   ├── main.dart
│   ├── screens/
│   ├── services/                   # wallet_manager, kite_chain, x402, usdc, identity
│   └── widgets/
│
├── contracts-hardhat/              # Hardhat smart contract project
│   ├── contracts/KitePayToken.sol
│   └── hardhat.config.ts
│
├── kitepay_sdk/                    # Dart payment gateway SDK
├── artifacts/KitePayToken.json     # Compiled contract ABI
└── vercel.json                     # Vercel build + function config
```

---

## Getting Started

### Prerequisites

- **Node.js 18+** and npm
- **Flutter 3.x SDK** (mobile app only)
- A wallet with KITE testnet tokens → [faucet.gokite.ai](https://faucet.gokite.ai)
- Free [Groq API key](https://console.groq.com) for AI agent
- Free [Reown project](https://dashboard.reown.com) — create a project and copy the Project ID
- [kpass CLI](https://agentpassport.ai) for Kite Passport sessions

---

### 1. Clone

```bash
git clone https://github.com/grahamaine/KitePay_.git
cd KitePay_
```

### 2. Run the Web App only (no AI agent)

```bash
cd KitePay
npm install

# Create a local env file
cat > .env.local << 'EOF'
VITE_PROJECT_ID=your_reown_project_id
VITE_KITE_TOKEN_ADDRESS=0x0105FBf3EDF5297870066ef351E5ca6399b9FF8b
EOF

npm run dev
# Open http://localhost:5173
```

### 3. Run with AI Agent (Vercel dev — full stack)

```bash
# Install root API dependencies
npm install

# Create env file at repo root
cat > .env << 'EOF'
GROQ_API_KEY=your_groq_api_key
AGENT_PRIVATE_KEY=0x_your_agent_wallet_private_key
SERVICE_WALLET_ADDRESS=0x_address_that_receives_x402_payments
VITE_PROJECT_ID=your_reown_project_id
VITE_KITE_TOKEN_ADDRESS=0x0105FBf3EDF5297870066ef351E5ca6399b9FF8b
EOF

vercel dev
# Open http://localhost:3000
```

### 4. Connect a Wallet (Web)

1. Open the app — you'll land on the KitePay dashboard
2. On **desktop**: click **Connect Wallet** in the top-right
3. On **mobile**: tap the **≡** hamburger menu to navigate, or use the **Connect Wallet** banner on the Home dashboard
4. Select MetaMask, WalletConnect, or any EIP-1193 wallet
5. The app auto-switches to **Kite Testnet** (chainId 2368)

> **Tip:** Get free KITE test tokens at [faucet.gokite.ai](https://faucet.gokite.ai) after connecting.

### 5. Set Up Kite Passport (AI Agent identity)

```bash
# Install kpass CLI
irm https://cli.gokite.ai/install.ps1 | iex          # Windows
curl -fsSL https://agentpassport.ai/install.sh | bash  # Mac / Linux

# Authenticate
kpass login init --email you@example.com
kpass login verify --login-id <id> --code <otp>

# Register agent + create spending session
kpass agent:register --type x402_http
kpass agent:session create \
  --task-summary "KitePay AI Agent — market intelligence" \
  --max-amount-per-tx 0.001 \
  --max-total-amount 0.01 \
  --ttl 24h
# Approve the URL shown in your browser, then paste the session ID into the KitePay UI
```

### 6. Run the Flutter App

```bash
flutter pub get
flutter run
```

### 7. Deploy the Smart Contract

```bash
cd contracts-hardhat
npm install

# Add Turnkey keys to contracts-hardhat/.env
npx hardhat run scripts/deploy.js --network kite-testnet
```

### 8. Deploy to Vercel

The repo is connected to Vercel — any push to `main` auto-deploys to [kitepay.vercel.app](https://kitepay.vercel.app).

For manual deploy:

```bash
vercel --prod
```

---

## Environment Variables

### API / Vercel Functions (root `.env` or Vercel dashboard)

| Variable | Required | Description |
|----------|----------|-------------|
| `GROQ_API_KEY` | AI Agent | Free Groq API key — powers Llama 3.3-70b reasoning |
| `AGENT_PRIVATE_KEY` | AI Agent | Private key of the wallet that pays for x402 services in KITE |
| `SERVICE_WALLET_ADDRESS` | AI Agent | Address that receives x402 micropayments |

### Web App — `KitePay/.env.local`

| Variable | Required | Description |
|----------|----------|-------------|
| `VITE_PROJECT_ID` | Yes | Reown AppKit project ID — get one at [dashboard.reown.com](https://dashboard.reown.com) |
| `VITE_KITE_TOKEN_ADDRESS` | Yes | Deployed KitePayToken contract (`0x0105FBf3...FF8b`) |

> Add your deployed domain (e.g. `kitepay.vercel.app`) to the **Allowed Domains** list in your Reown project dashboard to avoid WalletConnect websocket errors.

### Hardhat — `contracts-hardhat/.env`

| Variable | Description |
|----------|-------------|
| `TURNKEY_API_PUBLIC_KEY` | Turnkey API public key |
| `TURNKEY_API_PRIVATE_KEY` | Turnkey API private key |
| `TURNKEY_ORGANIZATION_ID` | Turnkey organisation ID |

---

## Smart Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract KitePayToken is ERC20 {
    constructor() ERC20("KitePay", "KITE") {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }
}
```

| Property | Value |
|----------|-------|
| Name | KitePay |
| Symbol | KITE |
| Decimals | 18 |
| Initial Supply | 1,000,000 KITE |
| Network | Kite Testnet (chainId 2368) |
| Address | [`0x0105FBf3EDF5297870066ef351E5ca6399b9FF8b`](https://testnet.kitescan.ai/address/0x0105FBf3EDF5297870066ef351E5ca6399b9FF8b) |

---

## Kite Chain Network Details

| | Testnet | Mainnet |
|--|---------|---------|
| Chain ID | 2368 | 2366 |
| RPC | `https://rpc-testnet.gokite.ai` | `https://rpc.gokite.ai` |
| Explorer | `https://testnet.kitescan.ai` | `https://kitescan.ai` |
| Symbol | KITE | KITE |
| Faucet | [faucet.gokite.ai](https://faucet.gokite.ai) | — |

---

## x402 Agent Payment Protocol

KitePay implements HTTP 402 for fully autonomous AI agent micropayments:

```
Agent  →  GET /api/services/price
       ←  402 { amount: "0.0001", token: "KITE", to: "0x...", chain: 2368 }
Agent  →  pays 0.0001 KITE on Kite Testnet
Agent  →  GET /api/services/price  { x-payment-hash: "0x..." }
       ←  200 { prices: { BTC: ..., ETH: ..., SOL: ... } }
Agent  →  write_attestation → keccak256 tx on Kite Chain
```

Each paid service verifies the transaction via `eth_getTransactionByHash` (works for pending txs — no block confirmation wait) before releasing data.

---

## On-Chain Attestations

Every AI analysis is committed to Kite Testnet as a cryptographic proof:

```typescript
// keccak256(task::result::timestamp) written as calldata in a self-send tx
const data = ethers.keccak256(ethers.toUtf8Bytes(`${task}::${result}::${Date.now()}`))
await wallet.sendTransaction({ to: wallet.address, value: 0n, data })
```

This gives users an immutable, auditable record of what the agent concluded and when — turning AI outputs into verifiable on-chain facts.

---

## Dart SDK

```dart
final client = Kitepay(apiKey: 'key', environment: KitepayEnvironment.sandbox);

await client.createPayment(amount: 100, currency: 'USD', customerEmail: 'u@e.com');
await client.createPayout(amount: 50,  currency: 'USD', cardNumber: '4111111111111111');
```

---

## Contributing

1. Fork → `git checkout -b feature/my-feature`
2. Commit → `git commit -m 'feat: add my feature'`
3. Push → `git push origin feature/my-feature`
4. Open a Pull Request against `main`

---

## License

MIT — see [LICENSE](LICENSE)

---

<p align="center">
  <img src="KitePay/public/logo.png" alt="" width="40"/>
  <br/>
  <strong>Autonomous · Attested · Built on Kite Chain</strong>
</p>
