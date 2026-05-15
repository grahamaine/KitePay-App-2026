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
      description: `Pay ${PAYMENT_AMOUNT} KITE to access real-time market sentiment and Fear & Greed index`,
      protocol:    'x402',
    });
  }

  // ── Verify on Kite chain ──────────────────────────────────────────────────
  const valid = await verifyPayment(paymentHash, serviceWallet);
  if (!valid) {
    return res.status(402).json({ error: 'Payment proof invalid or not found on Kite chain' });
  }

  // ── Fetch Fear & Greed index + trending coins ─────────────────────────────
  try {
    const [fngRes, trendingRes] = await Promise.all([
      fetch('https://api.alternative.me/fng/?limit=7'),
      fetch('https://api.coingecko.com/api/v3/search/trending'),
    ]);

    const fng      = await fngRes.json() as { data: { value: string; value_classification: string; timestamp: string }[] };
    const trending = await trendingRes.json() as { coins: { item: { name: string; symbol: string; market_cap_rank: number } }[] };

    const today     = fng.data[0];
    const yesterday = fng.data[1];
    const week      = fng.data.slice(0, 7).map(d => ({
      score: +d.value,
      label: d.value_classification,
      date:  new Date(+d.timestamp * 1000).toLocaleDateString('en-US', { weekday: 'short' }),
    }));

    const score = +today.value;
    const sentiment: 'extreme_fear' | 'fear' | 'neutral' | 'greed' | 'extreme_greed' =
      score < 25 ? 'extreme_fear' :
      score < 45 ? 'fear' :
      score < 55 ? 'neutral' :
      score < 75 ? 'greed' : 'extreme_greed';

    return res.status(200).json({
      fearGreed: {
        score,
        label:     today.value_classification,
        sentiment,
        yesterday: +yesterday.value,
        change:    score - +yesterday.value,
        weekTrend: week,
      },
      trending: trending.coins.slice(0, 5).map(c => ({
        name:   c.item.name,
        symbol: c.item.symbol,
        rank:   c.item.market_cap_rank,
      })),
      signal: score < 30 ? 'Strong buying opportunity — extreme fear historically precedes rebounds'
            : score < 45 ? 'Cautious accumulation zone — fear may persist short-term'
            : score < 55 ? 'Neutral market — wait for clearer directional signal'
            : score < 75 ? 'Healthy optimism — momentum favors longs'
            : 'Extreme greed — consider taking profits or tightening stops',
      timestamp:  Date.now(),
      source:     'alternative.me + CoinGecko',
      paymentTx:  paymentHash,
      chain:      'Kite Testnet (2368)',
    });
  } catch {
    return res.status(503).json({ error: 'Sentiment feed unavailable' });
  }
}
