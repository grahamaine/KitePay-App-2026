// KiteLiquidityPool (KITE/USDC) — Kite Testnet 2368
// Contract: 0x01A5eAF9aE06faC7945cf4F2c9dFE53b5e3D23F7

export const LP_ADDRESS = import.meta.env.VITE_LP_ADDRESS || '0x01A5eAF9aE06faC7945cf4F2c9dFE53b5e3D23F7'

export const LP_ABI = [
  { inputs: [{ internalType: 'uint256', name: 'amountA', type: 'uint256' }, { internalType: 'uint256', name: 'amountB', type: 'uint256' }], name: 'addLiquidity', outputs: [{ internalType: 'uint256', name: 'lpTokens', type: 'uint256' }], stateMutability: 'nonpayable', type: 'function' },
  { inputs: [{ internalType: 'uint256', name: 'lpTokens', type: 'uint256' }], name: 'removeLiquidity', outputs: [{ internalType: 'uint256', name: 'amountA', type: 'uint256' }, { internalType: 'uint256', name: 'amountB', type: 'uint256' }], stateMutability: 'nonpayable', type: 'function' },
  { inputs: [], name: 'getPoolInfo', outputs: [{ internalType: 'uint256', name: '_reserveA', type: 'uint256' }, { internalType: 'uint256', name: '_reserveB', type: 'uint256' }, { internalType: 'uint256', name: '_totalSupply', type: 'uint256' }], stateMutability: 'view', type: 'function' },
  { inputs: [{ internalType: 'address', name: 'user', type: 'address' }], name: 'getUserPosition', outputs: [{ internalType: 'uint256', name: 'lpBalance', type: 'uint256' }, { internalType: 'uint256', name: 'shareA', type: 'uint256' }, { internalType: 'uint256', name: 'shareB', type: 'uint256' }], stateMutability: 'view', type: 'function' },
  { inputs: [{ internalType: 'address', name: 'owner', type: 'address' }, { internalType: 'address', name: 'spender', type: 'address' }], name: 'allowance', outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }], stateMutability: 'view', type: 'function' },
  { inputs: [{ internalType: 'address', name: 'spender', type: 'address' }, { internalType: 'uint256', name: 'value', type: 'uint256' }], name: 'approve', outputs: [{ internalType: 'bool', name: '', type: 'bool' }], stateMutability: 'nonpayable', type: 'function' },
  { inputs: [{ internalType: 'address', name: 'account', type: 'address' }], name: 'balanceOf', outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }], stateMutability: 'view', type: 'function' },
] as const
