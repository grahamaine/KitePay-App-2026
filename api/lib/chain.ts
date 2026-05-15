import { ethers } from 'ethers';

export const KITE_RPC      = 'https://rpc-testnet.gokite.ai';
export const KITE_EXPLORER = 'https://testnet.kitescan.ai';
export const PAYMENT_AMOUNT = '0.0001'; // KITE per service call

// ── Provider / wallet helpers ─────────────────────────────────────────────────

export function getProvider(): ethers.JsonRpcProvider {
  return new ethers.JsonRpcProvider(KITE_RPC);
}

export function getAgentWallet(): ethers.Wallet {
  const pk = process.env.AGENT_PRIVATE_KEY;
  if (!pk) throw new Error('AGENT_PRIVATE_KEY not configured');
  return new ethers.Wallet(pk, getProvider());
}

export function getServiceWallet(): string {
  if (process.env.SERVICE_WALLET_ADDRESS) return process.env.SERVICE_WALLET_ADDRESS;
  if (process.env.AGENT_PRIVATE_KEY) return new ethers.Wallet(process.env.AGENT_PRIVATE_KEY).address;
  return '0x000000000000000000000000000000000000dEaD';
}

// ── x402 payment verification ─────────────────────────────────────────────────
// Checks the mempool + confirmed txs. Pending txs are visible immediately.

export async function verifyPayment(txHash: string, expectedTo: string): Promise<boolean> {
  if (!txHash || !/^0x[0-9a-fA-F]{64}$/.test(txHash)) return false;

  const provider = getProvider();
  for (let i = 0; i < 4; i++) {
    try {
      const tx = await provider.getTransaction(txHash);
      if (tx &&
          tx.to?.toLowerCase() === expectedTo.toLowerCase() &&
          tx.value >= ethers.parseEther(PAYMENT_AMOUNT)) {
        return true;
      }
    } catch { /* retry */ }
    if (i < 3) await new Promise(r => setTimeout(r, 1500));
  }
  return false;
}

// ── On-chain attestation ──────────────────────────────────────────────────────
// Self-send tx with keccak256(task::result::ts) as calldata — immutable proof.

export async function writeAttestation(
  task: string,
  result: string,
  wallet: ethers.Wallet
): Promise<string> {
  const digest = ethers.keccak256(
    ethers.toUtf8Bytes(`${task}::${result}::${Date.now()}`)
  );
  const tx = await wallet.sendTransaction({
    to: wallet.address,
    value: 0n,
    data: digest,
  });
  return tx.hash;
}

// ── Payment helper used by agent ──────────────────────────────────────────────

export async function payService(
  toAddress: string,
  wallet: ethers.Wallet
): Promise<string> {
  const tx = await wallet.sendTransaction({
    to: toAddress,
    value: ethers.parseEther(PAYMENT_AMOUNT),
  });
  return tx.hash;
}
