interface QuickActionsProps {
  onSend: () => void
  onReceive: () => void
  onVault: () => void
  onPayments: () => void
  disabled?: boolean
}

export const QuickActions = ({ onSend, onReceive, onVault, onPayments, disabled }: QuickActionsProps) => {
  const actions = [
    { label: 'Send', icon: '↑', color: '#00C2D4', onClick: onSend },
    { label: 'Receive', icon: '↓', color: '#F0B429', onClick: onReceive },
    { label: 'Vault', icon: '🔒', color: '#8B5CF6', onClick: onVault },
    { label: 'Payments', icon: '⚡', color: '#22C55E', onClick: onPayments },
  ]

  return (
    <div className="quick-actions">
      {actions.map(({ label, icon, color, onClick }) => (
        <button
          key={label}
          className="quick-action-btn"
          onClick={onClick}
          disabled={disabled}
          style={{ '--action-color': color } as React.CSSProperties}
        >
          <span className="quick-action-btn__icon">{icon}</span>
          <span className="quick-action-btn__label">{label}</span>
        </button>
      ))}
    </div>
  )
}
