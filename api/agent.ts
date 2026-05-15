import type { VercelRequest, VercelResponse } from '@vercel/node';
import Anthropic from '@anthropic-ai/sdk';
import { ethers }   from 'ethers';
import { getAgentWallet, getServiceWallet, payService, writeAttestation, KITE_EXPLORER } from './lib/chain';

// ── Types ─────────────────────────────────────────────────────────────────────

export interface AgentStep {
  type: 'thinking' | 'calling' | 'paying' | 'paid' | 'data' | 'analyzing' | 'attesting' | 'attested' | 'complete' | 'error';
  message: string;
  service?: string;
  txHash?: string;
  explorer?: string;
  data?: unknown;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function baseUrl(): string {
  if (process.env.VERCEL_URL)                    return `https://${process.env.VERCEL_URL}`;
  if (process.env.VERCEL_PROJECT_PRODUCTION_URL) return `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`;
  return 'http://localhost:3000';
}

async function callPaidService(
  path: string,
  wallet: ethers.Wallet,
  emit: (step: AgentStep) => void
): Promise<unknown> {
  const url         = `${baseUrl()}${path}`;
  const serviceWallet = getServiceWallet();

  // First pass — trigger 402
  const r1 = await fetch(url);

  if (r1.status === 402) {
    const info = await r1.json() as { description?: string };
    emit({ type: 'paying', message: `Service requires payment: ${info.description ?? path}` });

    // Pay autonomously on Kite chain
    const txHash = await payService(serviceWallet, wallet);
    emit({ type: 'paid', message: `Paid 0.0001 KITE on Kite Testnet`, txHash, explorer: `${KITE_EXPLORER}/tx/${txHash}` });

    // Retry with payment proof
    const r2 = await fetch(url, { headers: { 'x-payment-hash': txHash } });
    if (!r2.ok) throw new Error(`Service rejected payment (${r2.status})`);
    return await r2.json();
  }

  if (!r1.ok) throw new Error(`Service error: ${r1.status}`);
  return await r1.json();
}

// ── Claude tools definition ───────────────────────────────────────────────────

const TOOLS: Anthropic.Tool[] = [
  {
    name: 'get_crypto_prices',
    description: 'Fetch live BTC, ETH, SOL, BNB prices with 24h change. Costs 0.0001 KITE. Use when the user asks about prices, market conditions, or whether to buy/sell.',
    input_schema: { type: 'object' as const, properties: {}, required: [] },
  },
  {
    name: 'get_defi_yields',
    description: 'Scan 500+ DeFi protocols for the best yield opportunities with risk-adjusted scoring. Costs 0.0001 KITE. Use for yield optimization, passive income questions.',
    input_schema: { type: 'object' as const, properties: {}, required: [] },
  },
  {
    name: 'get_market_sentiment',
    description: 'Get the Fear & Greed index, 7-day trend, trending coins, and a trading signal. Costs 0.0001 KITE. Use for sentiment analysis and market timing questions.',
    input_schema: { type: 'object' as const, properties: {}, required: [] },
  },
  {
    name: 'write_attestation',
    description: 'Write a cryptographic proof of this analysis to the Kite blockchain. ALWAYS call this last, once you have a final answer. Creates an immutable on-chain record.',
    input_schema: {
      type: 'object' as const,
      properties: {
        summary:    { type: 'string', description: 'One-sentence summary of what was analyzed' },
        result:     { type: 'string', description: 'Your final recommendation or answer' },
        confidence: { type: 'number', description: 'Confidence score 0-100' },
      },
      required: ['summary', 'result', 'confidence'],
    },
  },
];

// ── Main handler ──────────────────────────────────────────────────────────────

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST')    return res.status(405).end();

  const { task, spendingLimit = '0.001' } = req.body as { task?: string; spendingLimit?: string };
  if (!task?.trim()) return res.status(400).json({ error: 'task is required' });

  // ── SSE setup ─────────────────────────────────────────────────────────────
  res.setHeader('Content-Type',  'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection',    'keep-alive');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.flushHeaders();

  const emit = (step: AgentStep) => {
    res.write(`data: ${JSON.stringify(step)}\n\n`);
  };

  try {
    // Check if wallet is configured (demo fallback if not)
    let wallet: ethers.Wallet | null = null;
    let demoMode = false;
    try {
      wallet = getAgentWallet();
    } catch {
      demoMode = true;
      emit({ type: 'thinking', message: '⚠️  AGENT_PRIVATE_KEY not set — running in demo mode (payments simulated)' });
    }

    emit({ type: 'thinking', message: 'Analyzing task and selecting data sources...' });

    const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

    const messages: Anthropic.MessageParam[] = [{ role: 'user', content: task }];
    let totalSpent  = 0n;
    const limit     = ethers.parseEther(spendingLimit);
    let finalResult = '';
    let attestTx    = '';

    // ── Agentic tool-use loop ─────────────────────────────────────────────
    for (let iter = 0; iter < 10; iter++) {
      const response = await client.messages.create({
        model:      'claude-haiku-4-5-20251001',
        max_tokens: 1024,
        system: `You are KitePay AI Agent — an autonomous crypto intelligence agent that settles every action on Kite chain (chain ID 2368).

Your capabilities:
- Fetch live crypto prices, DeFi yields, and market sentiment (each costs 0.0001 KITE, paid autonomously)
- Write cryptographic proofs of analysis to Kite chain for auditability

Rules:
1. Always gather relevant data before answering.
2. Always call write_attestation once you have a final, confident answer.
3. Be concise, data-driven, and actionable.
4. Express confidence as a number 0-100.`,
        tools:    TOOLS,
        messages,
      });

      // Append assistant turn
      messages.push({ role: 'assistant', content: response.content });

      if (response.stop_reason === 'end_turn') {
        for (const b of response.content)
          if (b.type === 'text') finalResult = b.text;
        break;
      }

      if (response.stop_reason === 'tool_use') {
        const toolResults: Anthropic.ToolResultBlockParam[] = [];

        for (const b of response.content) {
          if (b.type !== 'tool_use') continue;

          let result: unknown;

          // ── Spending limit guard ────────────────────────────────────────
          if (['get_crypto_prices', 'get_defi_yields', 'get_market_sentiment'].includes(b.name)) {
            if (totalSpent + ethers.parseEther('0.0001') > limit) {
              result = { error: 'Spending limit reached. Provide answer with available data.' };
              toolResults.push({ type: 'tool_result', tool_use_id: b.id, content: JSON.stringify(result) });
              continue;
            }
          }

          try {
            switch (b.name) {

              case 'get_crypto_prices': {
                emit({ type: 'calling', service: 'Price Oracle', message: 'Calling Price Oracle...' });
                if (demoMode || !wallet) {
                  result = { prices: { BTC: { usd: 95200, change24h: 2.1 }, ETH: { usd: 3420, change24h: 1.8 }, SOL: { usd: 185, change24h: 3.2 } }, source: 'demo', timestamp: Date.now() };
                  emit({ type: 'data', service: 'Price Oracle', message: 'Price data received (demo)' });
                } else {
                  result = await callPaidService('/api/services/price', wallet, emit);
                  totalSpent += ethers.parseEther('0.0001');
                  emit({ type: 'data', service: 'Price Oracle', message: 'Live price data received ✓' });
                }
                break;
              }

              case 'get_defi_yields': {
                emit({ type: 'calling', service: 'DeFi Scanner', message: 'Scanning DeFi protocols for best yields...' });
                if (demoMode || !wallet) {
                  result = { topYields: [{ protocol: 'Aave', chain: 'Ethereum', asset: 'USDC', apy: 12.4, tvlM: 2300 }], source: 'demo', timestamp: Date.now() };
                  emit({ type: 'data', service: 'DeFi Scanner', message: 'DeFi data received (demo)' });
                } else {
                  result = await callPaidService('/api/services/defi', wallet, emit);
                  totalSpent += ethers.parseEther('0.0001');
                  emit({ type: 'data', service: 'DeFi Scanner', message: 'DeFi yield scan complete ✓' });
                }
                break;
              }

              case 'get_market_sentiment': {
                emit({ type: 'calling', service: 'Sentiment Oracle', message: 'Fetching Fear & Greed index...' });
                if (demoMode || !wallet) {
                  result = { fearGreed: { score: 68, label: 'Greed', sentiment: 'greed' }, signal: 'Healthy optimism — momentum favors longs', source: 'demo', timestamp: Date.now() };
                  emit({ type: 'data', service: 'Sentiment Oracle', message: 'Sentiment data received (demo)' });
                } else {
                  result = await callPaidService('/api/services/sentiment', wallet, emit);
                  totalSpent += ethers.parseEther('0.0001');
                  emit({ type: 'data', service: 'Sentiment Oracle', message: 'Sentiment analysis complete ✓' });
                }
                break;
              }

              case 'write_attestation': {
                const { summary, result: rec, confidence } = b.input as { summary: string; result: string; confidence: number };
                emit({ type: 'attesting', message: 'Writing cryptographic proof to Kite chain...' });

                if (demoMode || !wallet) {
                  attestTx    = '0xdemo' + Math.random().toString(16).slice(2, 18);
                  finalResult = rec;
                  result      = { success: true, txHash: attestTx, mode: 'demo' };
                  emit({ type: 'attested', message: `Attestation written (demo)`, txHash: attestTx });
                } else {
                  attestTx    = await writeAttestation(summary, rec, wallet);
                  finalResult = rec;
                  result      = { success: true, txHash: attestTx };
                  emit({ type: 'attested', message: `Proof on Kite chain`, txHash: attestTx, explorer: `${KITE_EXPLORER}/tx/${attestTx}` });
                }
                void confidence; // used by Claude context, not needed here
                break;
              }

              default:
                result = { error: 'Unknown tool' };
            }
          } catch (err: unknown) {
            const msg = err instanceof Error ? err.message : 'Tool error';
            result = { error: msg };
            emit({ type: 'error', message: `Tool ${b.name} failed: ${msg}` });
          }

          toolResults.push({ type: 'tool_result', tool_use_id: b.id, content: JSON.stringify(result) });
        }

        messages.push({ role: 'user', content: toolResults });
      }
    }

    emit({
      type:    'complete',
      message: 'Agent task complete',
      data: {
        result:     finalResult,
        attestTx,
        explorer:   attestTx ? `${KITE_EXPLORER}/tx/${attestTx}` : null,
        totalSpent: ethers.formatEther(totalSpent) + ' KITE',
        demoMode,
      },
    });

  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Agent error';
    emit({ type: 'error', message: msg });
  }

  res.end();
}

export const config = { maxDuration: 60 };
