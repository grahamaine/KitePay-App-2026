# KitePay App 2026 — Project Memory

## Machine
- OS: Windows 11, Lenovo
- Shell: PowerShell
- Tools: Flutter, Node.js, npm, Vercel CLI, VS Code

## Project Location
C:\Users\Lenovo\Desktop\KitePay-App-2026\

## Flutter App
- Framework: Flutter (web target)
- State: provider ^6.1.2
- Auth: turnkey_sdk_flutter ^1.2.1
- Deployed: https://kite-pay-app-2026.vercel.app

## File Structure
lib/
  main.dart
  services/agent_service.dart
  screens/login_screen.dart
  screens/home_screen.dart
test/widget_test.dart
pubspec.yaml

## Turnkey
- Org ID: 725d7232-944c-4a2e-b71f-30997b3868a4
- RP ID: kite-pay-app-2026.vercel.app
- Auth Proxy User ID: 929e...e74b
- Root User ID: 5128...b0d4

## Blockchain
- Network: Ethereum Sepolia testnet
- Deployer wallet: 0x65c545aa1a9FDc6db6094B829d5aB583AEF67dBd
- Contract: NOT YET DEPLOYED (in progress)
- Contract folder: contracts-hardhat/
- Hardhat version: 2.22.0 (downgrading from 3.4.5)

## Secrets (NEVER store values here — rotate if exposed)
- Alchemy Sepolia URL: stored in contracts-hardhat/.env
- Wallet private key: stored in contracts-hardhat/.env
- Google OAuth Client ID: ROTATE — was exposed in chat

## Vercel
- Project: ainegb/kite-pay-app-2026
- Latest deploy: https://kite-pay-app-2026-5ycnbauxd-ainegb.vercel.app
- Stable URL: https://kite-pay-app-2026.vercel.app

## Build Command
flutter build web --release \
  --dart-define=TURNKEY_ORG_ID=725d7232-944c-4a2e-b71f-30997b3868a4 \
  --dart-define=ETH_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY

## Deploy Command
vercel --prod

## Current Status
- [x] Flutter app builds
- [x] Deployed to Vercel
- [x] Turnkey auth set up
- [x] Passkey login/signup in code
- [ ] Smart contract deployed
- [ ] Turnkey smart contract interface registered
- [ ] Google OAuth configured
- [ ] End-to-end passkey test on live site

## Next Steps
1. Downgrade Hardhat to 2.22.0
2. Deploy KitePayToken to Sepolia
3. Register contract in Turnkey
4. Test passkey sign-up on live Vercel URL
