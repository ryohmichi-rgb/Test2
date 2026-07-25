import katex from "katex";
import "katex/dist/katex.min.css";

// 問題文などの短いテキスト内の数式を描画する軽量コンポーネント。
// $...$ で囲んだ部分だけ KaTeX で組版し、それ以外は素のテキストのまま出す。
//
// 教材ページの MarkdownView とちがい、Markdown は解釈しない（react-markdown を読まない）。
// 問題文に見出しや箇条書きは要らないので、そのぶん軽く済ませている。
//
// 注意: seeds.rb で LaTeX を書くときは Ruby の**シングルクォート**を使うこと。
//   OK : question: '$\frac{2}{3}$ を計算しなさい。'
//   NG : question: "$\frac{2}{3}$ ..."  ← \f が改ページ文字に化ける
export default function MathText({ children }: { children: string }) {
  if (!children.includes("$")) return <>{children}</>;

  // $...$ を区切りとして分割（区切り自体も配列に残す）
  const parts = children.split(/(\$[^$]+\$)/g);

  return (
    <>
      {parts.map((part, i) => {
        if (part.length > 2 && part.startsWith("$") && part.endsWith("$")) {
          const html = katex.renderToString(part.slice(1, -1), {
            throwOnError: false, // 数式が壊れていても画面は落とさない（赤字で出る）
            trust: false,        // \href などの危険なコマンドを禁止
            output: "html",
          });
          return <span key={i} dangerouslySetInnerHTML={{ __html: html }} />;
        }
        return <span key={i}>{part}</span>;
      })}
    </>
  );
}
