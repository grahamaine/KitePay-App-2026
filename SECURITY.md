# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest (`main`) | ✅ |
| Older branches | ❌ |

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

Use one of these private channels:

- **GitHub Private Vulnerability Reporting** — [Report a vulnerability](https://github.com/grahamaine/KitePay_/security/advisories/new) (preferred)
- **Email** — ainegb05@gmail.com

Include as much detail as possible:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

You will receive a response within **72 hours**. We aim to patch confirmed vulnerabilities within **7 days**.

## Scope

The following are in scope:

- `api/` — Vercel serverless functions (agent payments, x402 services)
- `KitePay/src/` — React web dApp
- `contracts-hardhat/contracts/` — Smart contracts

The following are **out of scope**:

- Third-party dependencies (report upstream)
- Issues requiring physical access to a device
- Social engineering attacks

## Security Considerations

KitePay handles private keys and API credentials. **Never commit the following to the repository:**

- `AGENT_PRIVATE_KEY` — wallet private key for agent payments
- `GROQ_API_KEY` — LLM API credentials
- `SERVICE_WALLET_ADDRESS` — service payment recipient
- Any `.env` files containing secrets

All secrets are managed via Vercel environment variables and must never appear in source code or git history.
