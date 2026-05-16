/// <reference types="vite/client" />

interface Window {
  __kitepay_err?: (msg: string, src: string, line: number, col: number, err: Error) => void
}
