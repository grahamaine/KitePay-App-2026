/// <reference types="vite/client" />

interface Window {
  __kitepay_err?: (msg: string, src: string, line: number, col: number, err: Error) => void
}

// Reown AppKit web components
declare namespace React {
  namespace JSX {
    interface IntrinsicElements {
      'appkit-button': React.HTMLAttributes<HTMLElement> & {
        size?: 'sm' | 'md'
        balance?: 'show' | 'hide'
        disabled?: boolean
        label?: string
      }
      'appkit-network-button': React.HTMLAttributes<HTMLElement>
    }
  }
}
