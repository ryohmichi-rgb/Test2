import ReactMarkdown from "react-markdown";
import remarkMath from "remark-math";
import rehypeKatex from "rehype-katex";
import "katex/dist/katex.min.css";

// Markdown＋数式（KaTeX）の共通表示。
//
// インライン: $\frac{2}{3} \times \frac{3}{4}$
// 別行立て（大きく中央寄せ）: $$ を「独立した行」に書くこと。
//   $$
//   \frac{2}{3} \times \frac{3}{4} = \frac{1}{2}
//   $$
//   ※ $$...$$ を1行に書くとインライン扱いになり、大きくならない。
//
// 教材本文は Rails の seeds.rb に置く。ヒアドキュメントは必ずリテラル（<<~'MD'）に。
//   <<~MD（補間あり）だと \frac が改ページ文字、\times がタブに化けて数式が壊れる。
//
// 画像も Markdown の ![説明](URL) でそのまま貼れる（幅は CSS で画面に合わせる）。
//
// react-markdown と KaTeX は重いので、このコンポーネントを使うページは
// App.tsx で遅延読み込み（React.lazy）にして初回のJSを軽く保つこと。
export default function MarkdownView({ children }: { children: string }) {
  return (
    <ReactMarkdown remarkPlugins={[remarkMath]} rehypePlugins={[rehypeKatex]}>
      {children}
    </ReactMarkdown>
  );
}
