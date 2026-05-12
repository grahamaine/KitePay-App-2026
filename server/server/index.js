const express = require('express');
const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const KITE_TOKEN = process.env.KITE_TOKEN_ADDRESS ||
    '0x0105FBf3EDF5297870066ef351E5ca6399b9FF8b';
const SERVICE_WALLET = process.env.SERVICE_WALLET ||
    '0xd472B174cf4aDDb8b9f1DA784D5D9578312dE9a5';

// ── Free endpoint (no payment needed) ────────────────────────────────────────
app.get('/api/free/ping', (req, res) => {
    res.json({ status: 'ok', message: 'KitePay demo server running', time: new Date() });
});

// ── Paid endpoint: crypto price feed ─────────────────────────────────────────
app.get('/api/paid/price/:symbol', async (req, res) => {
    const proof = req.headers['x-payment-proof'];
    const txHash = req.headers['x-payment-tx'];

    // No payment proof — return 402
    if (!proof || !txHash) {
        return res.status(402)
            .set('X-Payment-Required',
                `amount=0.01;currency=USDC;recipient=${SERVICE_WALLET}`)
            .json({
                error: 'Payment required',
                payment: {
                    amount: 0.01,
                    currency: 'USDC',
                    recipient: SERVICE_WALLET,
                    token: KITE_TOKEN,
                    chain: 2368,
                    description: `Price feed for ${req.params.symbol}`,
                },
            });
    }

    // Validate proof exists (in production: verify tx on Kite chain)
    try {
        const decoded = JSON.parse(
            Buffer.from(proof, 'base64').toString('utf8'));
        console.log('Payment proof received:', decoded);

        // Fetch real price data
        const fetch = (await import('node-fetch')).default;
        const r = await fetch(
            `https://api.coingecko.com/api/v3/simple/price?ids=${req.params.symbol}&vs_currencies=usd,btc`
        );
        const data = await r.json();

        res.json({
            symbol: req.params.symbol,
            price: data,
            paidWith: decoded.currency,
            txHash: decoded.txHash,
            servedAt: new Date(),
            attestation: `https://testnet.kitescan.ai/tx/${decoded.txHash}`,
        });
    } catch (e) {
        res.status(400).json({ error: 'Invalid payment proof' });
    }
});

// ── Paid endpoint: AI inference ───────────────────────────────────────────────
app.post('/api/paid/ai', async (req, res) => {
    const proof = req.headers['x-payment-proof'];
    const txHash = req.headers['x-payment-tx'];

    if (!proof || !txHash) {
        return res.status(402)
            .set('X-Payment-Required',
                `amount=0.05;currency=USDC;recipient=${SERVICE_WALLET}`)
            .json({
                error: 'Payment required',
                payment: {
                    amount: 0.05,
                    currency: 'USDC',
                    recipient: SERVICE_WALLET,
                    token: KITE_TOKEN,
                    chain: 2368,
                    description: 'AI inference call',
                },
            });
    }

    const { prompt } = req.body;
    res.json({
        result: `Agent processed: "${prompt}" — settled on Kite chain`,
        txHash,
        model: 'kite-agent-v1',
        cost: '0.05 USDC',
        attestation: `https://testnet.kitescan.ai/tx/${txHash}`,
    });
});

// ── Subscription endpoint ─────────────────────────────────────────────────────
app.post('/api/subscription/create', (req, res) => {
    const { address, plan } = req.body;
    const plans = {
        basic: { price: 1.00, interval: 'monthly', calls: 100 },
        pro: { price: 5.00, interval: 'monthly', calls: 1000 },
        unlimited: { price: 20.00, interval: 'monthly', calls: -1 },
    };

    const selected = plans[plan] || plans.basic;
    res.json({
        subscriptionId: `sub_${Date.now()}`,
        address,
        plan: selected,
        nextPayment: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        payTo: SERVICE_WALLET,
        token: KITE_TOKEN,
    });
});

app.listen(PORT, () =>
    console.log(`KitePay demo server running on port ${PORT}`));