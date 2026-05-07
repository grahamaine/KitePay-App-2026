# KitePay Agent 2026: Autonomous Commerce Dashboard

An advanced Flutter-based autonomous agent that performs on-chain commerce via Trusted Execution Environments (TEE). This agent monitors spending policies and autonomously signs transactions using Turnkey’s secure vault infrastructure and KitePay’s settlement rails.

## 🚀 The Vision

In 2026, commerce isn't just for humans. This project demonstrates a "Human-in-the-Loop" dashboard where an AI agent manages high-frequency micro-payments within a secure hardware enclave, ensuring that your private keys are never exposed even to the agent itself.

## 🛠️ System Architecture

The application follows a "Policy-Action-Settlement" flow:

- **Policy:** The agent heartbeat scans network conditions and daily budgets.
- **Action:** Upon a positive trigger, the agent requests a signature from the Turnkey TEE.
- **Settlement:** The KitePay SDK broadcasts the signed intent to the blockchain for instant finality.

## 📦 Getting Started

### 1. Prerequisites

- Flutter SDK `^3.0.0`
- A Turnkey account (for Passkeys)
- A Kite Passport wallet

### 2. Clone and Setup

```bash
git clone https://github.com/your-username/kitepay_app_2026.git
cd kitepay_app_2026
