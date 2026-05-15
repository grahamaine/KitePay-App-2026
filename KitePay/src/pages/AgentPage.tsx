import React, { useState, useRef, useEffect } from 'react'
import {
  Brain, Zap, CreditCard, CheckCircle, Shield, AlertCircle,
  ExternalLink, Send, Cpu, Activity, TrendingUp, BarChart2, RefreshCw,
  Fingerprint, LogIn, LogOut, Key,
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

const PASSPORT_LOGIN_URL = 'https://agentpassport.ai/login?redirect=%2Fdashboard&mode=login&addAccount=false&step=email'

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
function ReputationBadge({ count, passportConnected }: { count: number; passportConnected: boolean }) {
  const tier = count === 0 ? 'New Agent' : count < 5 ? 'Trusted' : count < 20 ? 'Verified' : 'Elite'
  const score = Math.min(100, count * 8 + 20)
  return (
    <div className="reputation-badge">
      <span className="rep-label">Agent Reputation</span>
      <div className="rep-bar"><div className="rep-fill" style={{ width: `${score}%` }} /></div>
      <span className="rep-tier">{tier}</span>
      {passportConnected && <span className="passport-verified-chip"><Fingerprint size={10} /> Passport</span>}
    </div>
  )
}

// ── Kite Passport panel ───────────────────────────────────────────────────────
function PassportPanel({
  connected,
  sessionId,
  sessionInput,
  onSessionInputChange,
  onConnect,
  onDisconnect,
}: {
  connected: boolean
  sessionId: string
  sessionInput: string
  onSessionInputChange: (v: string) => void
  onConnect: () => void
  onDisconnect: () => void
}) {
  return (
    <div className={`agent-panel passport-panel ${connected ? 'passport-panel--connected' : ''}`}>
      <div className="passport-panel__header">
        <div className="passport-panel__title">
          <Fingerprint size={14} />
          <span className="panel-label">Kite Passport</span>
        </div>
        {connected && <span className="passport-status-chip"><span className="passport-dot" />Connected</span>}
      </div>

      {!connected ? (
        <>
          <p className="passport-desc">
            Link your Kite Passport to authenticate agent sessions with passkey security and session-based spending limits.
          </p>
          <a
            className="passport-login-btn"
            href={PASSPORT_LOGIN_URL}
            target="_blank"
            rel="noopener noreferrer"
          >
            <LogIn size={13} />
            Sign in at agentpassport.ai
            <ExternalLink size={11} />
          </a>
          <div className="passport-divider"><span>then paste your session ID</span></div>
          <div className="passport-input-row">
            <div className="passport-input-wrap">
              <Key size={12} className="passport-input-icon" />
              <input
                className="passport-session-input"
                type="text"
                placeholder="kp_sess_xxxxxxxxxxxxxxxx"
                value={sessionInput}
                onChange={e => onSessionInputChange(e.target.value)}
                spellCheck={false}
              />
            </div>
            <button
              className="passport-connect-btn"
              onClick={onConnect}
              disabled={sessionInput.trim().length < 8}
            >
              Connect
            </button>
          </div>
        </>
      ) : (
        <div className="passport-identity">
          <div className="passport-identity__row">
            <Fingerprint size={16} className="passport-identity__icon" />
            <div className="passport-identity__info">
              <span className="passport-identity__label">Session Active</span>
              <code className="passport-identity__id">{sessionId.slice(0, 14)}…{sessionId.slice(-6)}</code>
            </div>
          </div>
          <div className="passport-identity__meta">
            <span className="passport-meta-chip"><Shield size={10} /> x402 Authenticated</span>
            <span className="passport-meta-chip"><Activity size={10} /> Kite Testnet</span>
          </div>
          <button className="passport-disconnect-btn" onClick={onDisconnect}>
            <LogOut size={11} /> Disconnect
          </button>
        </div>
      )}
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

  // Kite Passport state
  const [passportSessionInput, setPassportSessionInput] = useState('')
  const [passportSessionId, setPassportSessionId]       = useState('')
  const [passportConnected, setPassportConnected]       = useState(false)

  // Auto-scroll log
  useEffect(() => {
    if (logRef.current) logRef.current.scrollTop = logRef.current.scrollHeight
  }, [steps])

  function connectPassport() {
    const id = passportSessionInput.trim()
    if (id.length < 8) return
    setPassportSessionId(id)
    setPassportConnected(true)
  }

  function disconnectPassport() {
    setPassportSessionId('')
    setPassportSessionInput('')
    setPassportConnected(false)
  }

  async function runAgent(taskText: string) {
    if (!taskText.trim() || running) return
    setRunning(true)
    setSteps([])
    setResult(null)

    if (passportConnected) {
      setSteps([{ type: 'thinking', message: `Kite Passport session authenticated — running with identity ${passportSessionId.slice(0, 10)}…` }])
    }

    try {
      const res = await fetch('/api/agent', {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({
          task: taskText,
          ...(passportConnected && { passportSession: passportSessionId }),
        }),
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
          <div className={`agent-avatar ${passportConnected ? 'agent-avatar--passport' : ''}`}>
            {passportConnected ? <Fingerprint size={22} /> : <Brain size={22} />}
          </div>
          <div>
            <h1 className="agent-title">KitePay AI Agent</h1>
            <p className="agent-subtitle">
              {passportConnected
                ? 'Passport Authenticated · x402 Payments · Kite Chain Attestations'
                : 'Autonomous · x402 Payments · Kite Chain Attestations'}
            </p>
          </div>
        </div>
        <div className="agent-header__right">
          <ReputationBadge count={taskCount} passportConnected={passportConnected} />
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
        <div className={`agent-stat ${passportConnected ? 'agent-stat--passport' : 'agent-stat--chain'}`}>
          {passportConnected ? <Fingerprint size={14} /> : <Activity size={14} />}
          <span>{passportConnected ? 'Passport Active' : 'Kite Testnet'}</span>
          <span className="chain-dot" />
        </div>
      </div>

      <div className="agent-body">

        {/* ── Left: passport + input + suggestions ──────────────────────── */}
        <div className="agent-left">

          {/* Kite Passport */}
          <PassportPanel
            connected={passportConnected}
            sessionId={passportSessionId}
            sessionInput={passportSessionInput}
            onSessionInputChange={setPassportSessionInput}
            onConnect={connectPassport}
            onDisconnect={disconnectPassport}
          />

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
              <li><span className="how-num">1</span> Kite Passport authenticates the agent session</li>
              <li><span className="how-num">2</span> Agent selects data sources for your task</li>
              <li><span className="how-num">3</span> Services return <code>402 Payment Required</code></li>
              <li><span className="how-num">4</span> Agent pays autonomously in KITE on Kite Testnet</li>
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
              {passportConnected && !running && (
                <span className="passport-log-chip"><Fingerprint size={10} /> Passport</span>
              )}
            </div>
            <div className="agent-log" ref={logRef}>
              {steps.length === 0 && !running && (
                <p className="log-empty">
                  {passportConnected
                    ? 'Kite Passport connected. Select a task to run.'
                    : 'Select a task or type a custom one to start the agent.'}
                </p>
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
                {passportConnected && <span className="passport-result-chip"><Fingerprint size={10} /> Verified</span>}
              </div>
              <p className="result-text">{result.text}</p>

              <div className="result-meta">
                {result.spent && (
                  <div className="meta-chip">
                    <CreditCard size={11} />
                    {result.spent} paid
                  </div>
                )}
                {passportConnected && (
                  <div className="meta-chip meta-chip--passport">
                    <Fingerprint size={11} />
                    Kite Passport session
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
