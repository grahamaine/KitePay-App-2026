// KiteStaking — Kite Testnet 2368
// Contract: 0x75978e39a02638349a67DF44c4eE0014F189CE97

export const STAKING_ADDRESS = import.meta.env.VITE_STAKING_ADDRESS || '0x75978e39a02638349a67DF44c4eE0014F189CE97'

export const STAKING_ABI = [
  { inputs: [{ internalType: 'uint256', name: 'amount', type: 'uint256' }], name: 'stake', outputs: [], stateMutability: 'nonpayable', type: 'function' },
  { inputs: [{ internalType: 'uint256', name: 'amount', type: 'uint256' }], name: 'unstake', outputs: [], stateMutability: 'nonpayable', type: 'function' },
  { inputs: [], name: 'claimRewards', outputs: [], stateMutability: 'nonpayable', type: 'function' },
  { inputs: [{ internalType: 'address', name: 'user', type: 'address' }], name: 'getStakeInfo', outputs: [{ internalType: 'uint256', name: 'amount', type: 'uint256' }, { internalType: 'uint256', name: 'stakedAt', type: 'uint256' }, { internalType: 'uint256', name: 'pending', type: 'uint256' }], stateMutability: 'view', type: 'function' },
  { inputs: [{ internalType: 'address', name: 'user', type: 'address' }], name: 'pendingRewards', outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }], stateMutability: 'view', type: 'function' },
  { inputs: [], name: 'totalStaked', outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }], stateMutability: 'view', type: 'function' },
] as const
