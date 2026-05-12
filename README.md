# KitePay — Fly Further With Every Payment

<p align="center">
  <img src="assets/KitePay_Dapp.png" alt="KitePay" width="600"/>
</p>

<p align="center">
  <strong>A full-stack Web3 payment platform on Kite Chain</strong><br/>
  Flutter mobile app · React web dApp · ERC-20 smart contract · AI agent payments
</p>

<p align="center">
  <a href="https://kitepay.vercel.app"><img src="https://img.shields.io/badge/Live%20App-kitepay.vercel.app-00C2D4?style=flat-square" /></a>
  <img src="https://img.shields.io/badge/Chain-Kite%20Testnet%202368-F0B429?style=flat-square" />
  <img src="https://img.shields.io/badge/Contract-Verified-22C55E?style=flat-square" />
  <img src="https://img.shields.io/badge/Flutter-3.x-027DFD?style=flat-square" />
  <img src="https://img.shields.io/badge/React-19-61DAFB?style=flat-square" />
</p>

---

## Overview

KitePay is a full-stack crypto payment platform built on the **Kite Chain** (EVM-compatible, chainId 2368/2366). It consists of:

| Component | Description |
|-----------|-------------|
| **Flutter Mobile App** | iOS/Android wallet with embedded EVM wallets, send/receive, staking |
| **React Web dApp** | Browser-based dashboard with wallet connect, KITE token panel |
| **KitePayToken** | ERC-20 smart contract deployed on Kite Testnet |
| **Dart SDK** | `kitepay_sdk` — REST client for KitePay payment gateway |
| **AI Agent Payments** | Autonomous x402 payment protocol for agent API calls |

---

## Live Links

| Resource | URL |
|----------|-----|
| 🌐 Web App | [kitepay.vercel.app](https://kitepay.vercel.app) |
| 🔗 Contract (Testnet) | [0x0105FBf3...FF8b](https://testnet.kitescan.ai/address/0x0105FBf3EDF5297870066ef351E5ca6399b9FF8b) |
| 🔍 Explorer | [testnet.kitescan.ai](https://testnet.kitescan.ai) |

---

## Features

### 💳 Web dApp (KitePay/)
- **Widget-style dashboard** — balance card with sparkline, quick-action buttons
- **Send / Receive** — transfer KITE tokens or native ETH with modals
- **Vault** — staking interface with flexible, 30-day, 90-day, and 1-year plans
- **Payments** — searchable, filterable full transaction history
- **Degens** — token swap UI and liquidity pool browser
- **Maturity** — staking plans with APY calculator
- **Triella** — portfolio breakdown and activity log
- **Security** — 2FA toggles, session management, auto-lock
- **Settings** — network switch (Kite Testnet ↔ Mainnet), language, currency
- **Kite Chain integration** — Kite Testnet + Mainnet custom networks via Reown AppKit
- **KITE ERC-20** — live balance, transfer, approve via deployed contract

### 📱 Flutter Mobile App (lib/)
- **Embedded EVM wallets** — generate or import wallets (BIP39 mnemonic / private key)
- **Send & Receive KITE** — QR code scanner (pay), QR code display (receive)
- **Transaction history** — fetched from KiteScan API
- **AI Agent screen** — x402 HTTP payment protocol, autonomous spending
- **USDC service** — daily/per-tx spending limits, approval flows
- **Identity service** — on-chain agent identity attestation
- **Firebase auth** — email OTP and password login
- **Multi-language** — English, French, Spanish, Arabic, Chinese

### ⛓ Smart Contract (contracts-hardhat/)
- **KitePayToken (KITE)** — ERC-20, 1,000,000 initial supply
- Deployed on Kite Testnet: `0x0105FBf3EDF5297870066ef351E5ca6399b9FF8b`
- Hardhat + Turnkey for deployment key management
- Configured for Kite Testnet (2368), Kite Mainnet (2366), Sepolia (11155111)

---

## Tech Stack

| Layer | Technologies |
|-------|-------------|
| Mobile | Flutter 3.x, Dart, web3dart, Firebase, FlutterSecureStorage |
| Web | React 19, TypeScript, Vite, ethers.js v6, Reown AppKit |
| Blockchain | Kite Chain (EVM), Solidity ^0.8.20, Hardhat, OpenZeppelin |
| Wallet Infra | Turnkey (key management), Reown AppKit (wallet connect) |
| Payments | HTTP 402 x402 protocol, USDC ERC-20, KITE ERC-20 |
| Auth | Firebase Auth (email/password, OTP) |
| Deploy | Vercel (web), Hardhat (contracts) |

---

## Project Structure

```
KitePay-App-2026/
├── lib/                        # Flutter mobile app
│   ├── main.dart               # App entry, theme, Firebase init
│   ├── screens/                # Home, Wallet, Login, Portfolio, Swap
│   ├── services/               # wallet_manager, kite_chain, x402, usdc, identity
│   └── widgets/                # Send, Receive, Pay, Vault, Checkout, etc.
│
├── KitePay/                    # React web dApp
│   ├── src/
│   │   ├── App.tsx             # Root — routing + layout
│   │   ├── config/index.tsx    # Networks + AppKit config
│   │   ├── components/         # BalanceCard, QuickActions, Modals, Widgets
│   │   └── pages/              # Payments, Security, Degens, Maturity, Triella, Settings
│   └── public/logo.png         # KitePay logo
│
├── contracts-hardhat/          # Hardhat project
│   ├── contracts/
│   │   └── KitePayToken.sol    # ERC-20 KITE token
│   ├── scripts/
│   │   └── deploy.js           # Turnkey-based deployment
│   └── hardhat.config.ts       # Network configs
│
├── kitepay_sdk/                # Dart payment gateway SDK
│   └── lib/kitepay_sdk.dart    # REST client (payments + payouts)
│
└── artifacts/
    └── KitePayToken.json       # Compiled ABI + bytecode
```

---

## Getting Started

### Prerequisites
- Node.js 18+
- Flutter 3.x SDK
- Dart SDK 3.3+
- A wallet with KITE testnet tokens ([faucet](https://faucet.gokite.ai))

### 1. Clone
```bash
git clone https://github.com/grahamaine/KitePay_.git
cd KitePay_
```

### 2. Run the Web App
```bash
cd KitePay
cp .env.test .env.local
# Fill in VITE_PROJECT_ID from dashboard.reown.com
# VITE_KITE_TOKEN_ADDRESS is pre-filled
npm install
npm run dev
# Open http://localhost:5173
```

### 3. Run the Flutter App
```bash
flutter pub get
flutter run
```

### 4. Deploy the Smart Contract
```bash
cd contracts-hardhat
npm install
# Add TURNKEY credentials to .env
npx hardhat run scripts/deploy.js --network kite-testnet
```

### 5. Deploy the Web App
```bash
cd KitePay
vercel deploy --prod
```

---

## Environment Variables

### KitePay web app — `KitePay/.env.local`
| Variable | Description |
|----------|-------------|
| `VITE_PROJECT_ID` | Reown AppKit project ID (dashboard.reown.com) |
| `VITE_KITE_TOKEN_ADDRESS` | Deployed KitePayToken contract address |

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
| Network | Kite Testnet (2368) |
| Address | `0x0105FBf3EDF5297870066ef351E5ca6399b9FF8b` |

---

## Kite Chain Network Details

| | Testnet | Mainnet |
|--|---------|---------|
| Chain ID | 2368 | 2366 |
| RPC | `https://rpc-testnet.gokite.ai` | `https://rpc.gokite.ai` |
| Explorer | `https://testnet.kitescan.ai` | `https://kitescan.ai` |
| Symbol | KITE | KITE |

---

## x402 Agent Payment Protocol

KitePay implements HTTP 402 for autonomous AI agent payments:

1. Agent calls paid API → receives `402 Payment Required`
2. Parses payment requirements (amount, token, address)
3. Auto-signs and broadcasts KITE transaction on Kite chain
4. Retries with `X-Payment-Proof` header
5. Stores on-chain attestation

---

## Dart SDK

```dart
final client = Kitepay(apiKey: 'key', environment: KitepayEnvironment.sandbox);

await client.createPayment(amount: 100, currency: 'USD', customerEmail: 'u@e.com');
await client.createPayout(amount: 50, currency: 'USD', cardNumber: '4111111111111111');
```

---

## Contributing

1. Fork → `git checkout -b feature/my-feature`
2. Commit → `git commit -m 'Add my feature'`
3. Push → `git push origin feature/my-feature`
4. Open a Pull Request

---

## License

MIT — see [LICENSE](LICENSE)

---

<p align="center"><strong>Elevate Every Payment · Built on Kite Chain</strong></p>
