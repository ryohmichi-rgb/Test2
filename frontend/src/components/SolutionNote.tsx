import MathText from "./MathText";

// 間違えたときに出す「解き方」。答えを見せたうえで、なぜそうなるかを読ませる。
//
// 正解したときは出さない（読む必要がないし、テンポが落ちる）。API 側でも
// 正解時は solution を返していないので、ここは念のための二重の守り。
// 解説が未登録の問題（管理画面で足した問題など）でも落ちないよう、無ければ何も出さない。
export default function SolutionNote({ solution }: { solution: string | null }) {
  if (!solution) return null;

  return (
    <div className="solution-note">
      <p className="solution-title">解き方</p>
      <p className="solution-body"><MathText>{solution}</MathText></p>
    </div>
  );
}
