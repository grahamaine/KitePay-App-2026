import type { VercelRequest, VercelResponse } from '@vercel/node';
import { verifyPayment, getServiceWallet, PAYMENT_AMOUNT } from '../lib/chain';

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
      description: `Pay ${PAYMENT_AMOUNT} KITE on Kite Testnet to access real-time crypto prices`,
      protocol:    'x402',
    });
  }

  // ── Verify on Kite chain ──────────────────────────────────────────────────
  const valid = await verifyPayment(paymentHash, serviceWallet);
  if (!valid) {
    return res.status(402).json({ error: 'Payment proof invalid or not found on Kite chain' });
  }

  // ── Fetch live data (CoinGecko free tier) ─────────────────────────────────
  try {
    const cgRes = await fetch(
      'https://api.coingecko.com/api/v3/simple/price' +
      '?ids=bitcoin,ethereum,solana,binancecoin' +
      '&vs_currencies=usd' +
      '&include_24hr_change=true' +
      '&include_market_cap=true'
    );
    const raw = await cgRes.json() as Record<string, Record<string, number>>;

    return res.status(200).json({
      prices: {
        BTC: { usd: raw.bitcoin?.usd,      change24h: raw.bitcoin?.usd_24h_change,      mcap: raw.bitcoin?.usd_market_cap },
        ETH: { usd: raw.ethereum?.usd,     change24h: raw.ethereum?.usd_24h_change,     mcap: raw.ethereum?.usd_market_cap },
        SOL: { usd: raw.solana?.usd,       change24h: raw.solana?.usd_24h_change,       mcap: raw.solana?.usd_market_cap },
        BNB: { usd: raw.binancecoin?.usd,  change24h: raw.binancecoin?.usd_24h_change,  mcap: raw.binancecoin?.usd_market_cap },
      },
      timestamp:  Date.now(),
      source:     'CoinGecko',
      paymentTx:  paymentHash,
      chain:      'Kite Testnet (2368)',
    });
  } catch {
    return res.status(503).json({ error: 'Upstream price feed unavailable' });
  }
}
