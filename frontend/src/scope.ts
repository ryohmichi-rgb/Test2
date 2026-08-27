// 出題範囲（教科・学年・ステータス・単元）の選択肢を組み立てる。
// テストと問題集で同じ考え方を使うのでここに置く。
import type { Grade, Subject, Unit } from "./types";

/** 学年の一覧から、いま問題がある教科を取り出す（教科だけを返すAPIは持っていない） */
export function subjectsOf(grades: Grade[]): Subject[] {
  const found = new Map<number, Subject>();
  grades.forEach((g) =>
    (g.units || []).forEach((u) => {
      if (u.subject && !found.has(u.subject.id)) found.set(u.subject.id, u.subject);
    })
  );
  // 並びは教科IDの順に固定する（単元の display_order 任せだと単元を足すたびに順が変わる）
  return [...found.values()].sort((a, b) => a.id - b.id);
}

/**
 * 教科の選択を出すかどうか。
 *
 * 「教科が2つ以上ある」では判定しない。いまの教科は算数（小6）と数学（中1）で
 * **学年と1対1**なので、それだけで出すと「小6→算数」と押させるだけの無駄な一手になる。
 * 出すべきなのは**同じ学年に2教科以上ある**とき＝学年を選ぶと混ざるときだけ。
 */
export function subjectPickerNeeded(grades: Grade[]): boolean {
  return grades.some((g) => new Set((g.units || []).map((u) => u.subject?.id)).size > 1);
}

/** 教科でしぼった単元（subjectId が null なら全部） */
export function unitsOf(grades: Grade[], subjectId: number | null): (Unit & { gradeId: number; gradeName: string })[] {
  return grades.flatMap((g) =>
    (g.units || [])
      .filter((u) => subjectId === null || u.subject?.id === subjectId)
      .map((u) => ({ ...u, gradeId: g.id, gradeName: g.name }))
  );
}

/** その教科の問題がある学年だけ */
export function gradesOf(grades: Grade[], subjectId: number | null): Grade[] {
  if (subjectId === null) return grades;
  return grades.filter((g) => (g.units || []).some((u) => u.subject?.id === subjectId));
}

/**
 * その教科の単元に付いているステータスのID（1単元に複数付く）。
 * 旧バックエンドは stat_type_ids を返さない（＝全部から）ので、そのときは
 * 「分からない」とみなして null を返し、呼び出し側でしぼり込みを止める。
 */
export function statTypeIdsOf(grades: Grade[], subjectId: number | null): number[] | null {
  const all = grades.flatMap((g) => g.units || []);
  if (!all.some((u) => (u.stat_type_ids || []).length > 0)) return null;
  const ids = all
    .filter((u) => subjectId === null || u.subject?.id === subjectId)
    .flatMap((u) => u.stat_type_ids || []);
  return [...new Set(ids)];
}
