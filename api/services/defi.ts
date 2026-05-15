import type { VercelRequest, VercelResponse } from '@vercel/node';
import { verifyPayment, getServiceWallet, PAYMENT_AMOUNT } from '../lib/chain';

interface Pool {
  project: string;
  chain: string;
  symbol: string;
  apy: number;
  tvlUsd: number;
  apyBase?: number;
  apyReward?: number;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'x-payment-hash, content-type');
  if (req.method === 'OPTIONS') return res.status(200).end();

  const serviceWallet = getServiceWallet();
  const paymentHash = req.headers['x-payment-hash'] as string | undefined;

  // ── x402: demand payment ──────────────────────────────────────────────────
  if (!paymentHash) {
    return res.status(402).json({
      error:       'Payment Required',
      amount:      PAYMENT_AMOUNT,
      token:       'KITE',
      to:          serviceWallet,
      chain:       2368,
      description: `Pay ${PAYMENT_AMOUNT} KITE to access DeFi yield intelligence across 500+ protocols`,
      protocol:    'x402',
    });
  }

  // ── Verify on Kite chain ──────────────────────────────────────────────────
  const valid = await verifyPayment(paymentHash, serviceWallet);
  if (!valid) {
    return res.status(402).json({ error: 'Payment proof invalid or not found on Kite chain' });
  }

  // ── Fetch top DeFi yields (DeFiLlama — no API key needed) ─────────────────
  try {
    const llamaRes = await fetch('https://yields.llama.fi/pools');
    const { data } = await llamaRes.json() as { data: Pool[] };

    // Top 8 by APY, min $1M TVL, from major chains
    const majorChains = new Set(['Ethereum', 'Arbitrum', 'Base', 'Optimism', 'Polygon', 'BSC', 'Avalanche', 'Solana']);
    const top = data
      .filter(p => majorChains.has(p.chain) && p.tvlUsd > 1_000_000 && p.apy > 0 && p.apy < 500)
      .sort((a, b) => b.apy - a.apy)
      .slice(0, 8)
      .map(p => ({
        protocol:  p.project,
        chain:     p.chain,
        asset:     p.symbol,
        apy:       +p.apy.toFixed(2),
        tvlM:      +(p.tvlUsd / 1_000_000).toFixed(1),
        baseApy:   p.apyBase ? +p.apyBase.toFixed(2) : null,
        rewardApy: p.apyReward ? +p.apyReward.toFixed(2) : null,
      }));

    // Best risk-adjusted (high TVL = lower risk proxy)
    const best = [...top].sort((a, b) => (b.apy * Math.log(b.tvlM + 1)) - (a.apy * Math.log(a.tvlM + 1)))[0];

    return res.status(200).json({
      topYields:     top,
      bestRiskAdj:   best,
      totalProtocols: data.length,
      timestamp:     Date.now(),
      source:        'DeFiLlama',
      paymentTx:     paymentHash,
      chain:         'Kite Testnet (2368)',
    });
  } catch {
    return res.status(503).json({ error: 'DeFi data feed unavailable' });
  }
}
