import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
})

// メモ: KaTeX を manualChunks で共有チャンクに切り出すことも試したが、逆効果だったので採用していない。
// 各チャンクは自分が使う分だけ tree-shaking されており（教材/問題で各約260kB）、
// 共有化すると単一画面しか開かない利用者の転送量が増える（591→851kB など）。
// 教材と問題の両方を開く場合でも合計はほぼ同じ（982 vs 983kB）だった。
