import React, { useState, useRef, useEffect } from 'react'
import {
  Brain, Zap, CreditCard, CheckCircle, Shield, AlertCircle,
  ExternalLink, Send, Cpu, Activity, TrendingUp, BarChart2, RefreshCw,
} from 'lucide-react'
// Mirrors api/agent.ts AgentStep — defined locally to avoid backend deps leaking into frontend build
export interface AgentStep {
  type: 'thinking' | 'calling' | 'paying' | 'paid' | 'data' | 'analyzing' | 'attesting' | 'attested' | 'complete' | 'error'
  message: string
  service?: string
  txHash?: string
  explorer?: string
  data?: unknown
}

// ── Suggested tasks (current trends in agentic commerce) ─────────────────────
const SUGGESTED = [
  { label: 'Market Analysis',  task: 'Analyze current crypto market conditions across BTC, ETH and SOL. Give me a clear buy/hold/sell recommendation with confidence score.' },
  { label: 'DeFi Optimizer',   task: 'Find the top 3 DeFi yield opportunities available right now. Rank them by risk-adjusted return and recommend the best one for a moderate risk appetite.' },
  { label: 'Sentiment Check',  task: 'What is the current market sentiment? Is the Fear & Greed index signaling a buying or selling opportunity? Give a specific action.' },
  { label: 'Full Intel',       task: 'Run a complete market intelligence report: prices, sentiment, and best DeFi yield. Summarise in 5 bullet points and give one actionable trade idea.' },
]

// ── Step icon + colour helpers ────────────────────────────────────────────────
function StepIcon({ type }: { type: AgentStep['type'] }) {
  const map: Record<AgentStep['type'], { icon: React.ReactNode; cls: string }> = {
    thinking:  { icon: <Brain      size={14} />, cls: 'step--thinking'  },
    calling:   { icon: <Zap        size={14} />, cls: 'step--calling'   },
    paying:    { icon: <CreditCard size={14} />, cls: 'step--paying'    },
    paid:      { icon: <CreditCard size={14} />, cls: 'step--paid'      },
    data:      { icon: <Activity   size={14} />, cls: 'step--data'      },
    analyzing: { icon: <Cpu        size={14} />, cls: 'step--analyzing' },
    attesting: { icon: <Shield     size={14} />, cls: 'step--attesting' },
    attested:  { icon: <Shield     size={14} />, cls: 'step--attested'  },
    complete:  { icon: <CheckCircle size={14} />, cls: 'step--complete' },
    error:     { icon: <AlertCircle size={14} />, cls: 'step--error'    },
  }
  const m = map[type] ?? map.thinking
  return <span className={`step-icon ${m.cls}`}>{m.icon}</span>
}

// ── Reputation score (derived from stored attestation count) ──────────────────
function ReputationBadge({ count }: { count: number }) {
  const tier = count === 0 ? 'New Agent' : count < 5 ? 'Trusted' : count < 20 ? 'Verified' : 'Elite'
  const score = Math.min(100, count * 8 + 20)
  return (
    <div className="reputation-badge">
      <span className="rep-label">Agent Reputation</span>
      <div className="rep-bar"><div className="rep-fill" style={{ width: `${score}%` }} /></div>
      <span className="rep-tier">{tier}</span>
    </div>
  )
}

// ── Main component ────────────────────────────────────────────────────────────
export function AgentPage() {
  const [task, setTask]         = useState('')
  const [running, setRunning]   = useState(false)
  const [steps, setSteps]       = useState<AgentStep[]>([])
  const [result, setResult]     = useState<{ text: string; attestTx?: string; explorer?: string; spent?: string; demo?: boolean } | null>(null)
  const [taskCount, setTaskCount] = useState(0)
  const [totalSpent, setTotalSpent] = useState(0)
  const logRef = useRef<HTMLDivElement>(null)

  // Auto-scroll log
  useEffect(() => {
    if (logRef.current) logRef.current.scrollTop = logRef.current.scrollHeight
  }, [steps])

  async function runAgent(taskText: string) {
    if (!taskText.trim() || running) return
    setRunning(true)
    setSteps([])
    setResult(null)

    try {
      const res = await fetch('/api/agent', {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ task: taskText }),
      })

      if (!res.body) throw new Error('No response body')

      const reader  = res.body.getReader()
      const decoder = new TextDecoder()
      let   buffer  = ''

      while (true) {
        const { done, value } = await reader.read()
        if (done) break

        buffer += decoder.decode(value, { stream: true })
        const lines = buffer.split('\n')
        buffer = lines.pop() ?? ''

        for (const line of lines) {
          if (!line.startsWith('data: ')) continue
          try {
            const step: AgentStep = JSON.parse(line.slice(6))
            setSteps(prev => [...prev, step])

            if (step.type === 'complete' && step.data) {
              const d = step.data as { result: string; attestTx?: string; explorer?: string; totalSpent?: string; demoMode?: boolean }
              setResult({ text: d.result, attestTx: d.attestTx, explorer: d.explorer, spent: d.totalSpent, demo: d.demoMode })
              setTaskCount(c => c + 1)
              if (d.totalSpent) {
                const kite = parseFloat(d.totalSpent)
                if (!isNaN(kite)) setTotalSpent(p => +(p + kite).toFixed(4))
              }
            }
          } catch { /* skip malformed */ }
        }
      }
    } catch (err) {
      setSteps(prev => [...prev, { type: 'error', message: err instanceof Error ? err.message : 'Connection failed' }])
    }

    setRunning(false)
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    runAgent(task)
  }

  return (
    <div className="agent-page">

      {/* ── Header ────────────────────────────────────────────────────────── */}
      <div className="agent-header">
        <div className="agent-header__left">
          <div className="agent-avatar">
            <Brain size={22} />
          </div>
          <div>
            <h1 className="agent-title">KitePay AI Agent</h1>
            <p className="agent-subtitle">Autonomous · x402 Payments · Kite Chain Attestations</p>
          </div>
        </div>
        <div className="agent-header__right">
          <ReputationBadge count={taskCount} />
        </div>
      </div>

      {/* ── Stats row ─────────────────────────────────────────────────────── */}
      <div className="agent-stats">
        <div className="agent-stat">
          <Cpu size={14} />
          <span>{taskCount} tasks run</span>
        </div>
        <div className="agent-stat">
          <CreditCard size={14} />
          <span>{totalSpent} KITE spent</span>
        </div>
        <div className="agent-stat">
          <Shield size={14} />
          <span>{taskCount} attestations</span>
        </div>
        <div className="agent-stat agent-stat--chain">
          <Activity size={14} />
          <span>Kite Testnet</span>
          <span className="chain-dot" />
        </div>
      </div>

      <div className="agent-body">

        {/* ── Left: input + suggestions ─────────────────────────────────── */}
        <div className="agent-left">

          <div className="agent-panel">
            <p className="panel-label">Quick Tasks</p>
            <div className="suggestion-grid">
              {SUGGESTED.map(s => (
                <button
                  key={s.label}
                  className="suggestion-chip"
                  onClick={() => { setTask(s.task); runAgent(s.task) }}
                  disabled={running}
                >
                  <TrendingUp size={12} />
                  {s.label}
                </button>
              ))}
            </div>
          </div>

          <form className="agent-panel agent-input-panel" onSubmit={handleSubmit}>
            <p className="panel-label">Custom Task</p>
            <textarea
              className="agent-textarea"
              placeholder="Ask the agent anything — it will autonomously pay for data, analyze, and attest results on Kite chain..."
              value={task}
              onChange={e => setTask(e.target.value)}
              rows={4}
              disabled={running}
            />
            <button className="agent-run-btn" type="submit" disabled={running || !task.trim()}>
              {running
                ? <><RefreshCw size={14} className="spin" /> Running...</>
                : <><Send size={14} /> Run Agent</>}
            </button>
          </form>

          {/* How it works */}
          <div className="agent-panel agent-how">
            <p className="panel-label">How It Works</p>
            <ol className="how-list">
              <li><span className="how-num">1</span> Agent receives task, selects data sources</li>
              <li><span className="how-num">2</span> Services return <code>402 Payment Required</code></li>
              <li><span className="how-num">3</span> Agent pays autonomously in KITE on Kite Testnet</li>
              <li><span className="how-num">4</span> Services verify payment on-chain, return data</li>
              <li><span className="how-num">5</span> Claude analyzes, writes attestation to Kite chain</li>
            </ol>
          </div>
        </div>

        {/* ── Right: execution log + result ─────────────────────────────── */}
        <div className="agent-right">

          <div className="agent-panel agent-log-panel">
            <div className="log-header">
              <p className="panel-label">Execution Log</p>
              {running && <span className="live-badge"><span className="live-dot" />LIVE</span>}
            </div>
            <div className="agent-log" ref={logRef}>
              {steps.length === 0 && !running && (
                <p className="log-empty">Select a task or type a custom one to start the agent.</p>
              )}
              {steps.map((s, i) => (
                <div key={i} className={`log-step log-step--${s.type}`}>
                  <StepIcon type={s.type} />
                  <div className="step-body">
                    <span className="step-msg">{s.message}</span>
                    {s.txHash && (
                      <a
                        className="step-tx"
                        href={s.explorer ?? '#'}
                        target="_blank"
                        rel="noopener noreferrer"
                      >
                        {s.txHash.slice(0, 10)}…{s.txHash.slice(-6)}
                        <ExternalLink size={10} />
                      </a>
                    )}
                  </div>
                </div>
              ))}
              {running && (
                <div className="log-step log-step--thinking">
                  <span className="step-icon step--thinking"><Brain size={14} /></span>
                  <span className="step-msg typing-dots">Processing<span>.</span><span>.</span><span>.</span></span>
                </div>
              )}
            </div>
          </div>

          {result && (
            <div className="agent-panel agent-result-panel">
              <div className="result-header">
                <CheckCircle size={16} className="result-check" />
                <p className="panel-label">Agent Result</p>
                {result.demo && <span className="demo-badge">DEMO MODE</span>}
              </div>
              <p className="result-text">{result.text}</p>

              <div className="result-meta">
                {result.spent && (
                  <div className="meta-chip">
                    <CreditCard size={11} />
                    {result.spent} paid
                  </div>
                )}
                {result.attestTx && (
                  <a
                    className="meta-chip meta-chip--link"
                    href={result.explorer ?? '#'}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <Shield size={11} />
                    Attestation on-chain
                    <ExternalLink size={10} />
                  </a>
                )}
              </div>

              {result.attestTx && !result.demo && (
                <div className="attest-proof">
                  <BarChart2 size={12} />
                  <span>Kite chain proof: </span>
                  <code>{result.attestTx}</code>
                </div>
              )}
            </div>
          )}

        </div>
      </div>
    </div>
  )
}
