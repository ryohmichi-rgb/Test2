import { useNavigate } from "react-router";
import type { RankStatus } from "../types";

// ランク（そのまとまりで積んだポイント）の表示。ランクは教科のまとまりごとにある。
// 「到達したら自動で昇格」ではなく、昇格試験に合格して初めて上がるので、下段の見せ方を
// 3つに分ける：
//   1. まだ届いていない  → 次のランクまであと何pt
//   2. 届いた・挑戦できる → 昇格試験への導線（いちばん目立たせる）
//   3. 届いたが再挑戦待ち → あと何pt稼げば再挑戦できるか
// 上段（ランク章・称号・合計pt）はどの状態でも必ず出す。昇格直後は「次の試験に挑戦できる」
// 状態になるため、そこで称号が消えてしまわないようにする。
export default function RankCard({
  status,
  title = null,
  compact = false,
  showGroupName = false,
}: {
  status: RankStatus;
  /** 選択中の称号（あれば級位のとなりに出す） */
  title?: string | null;
  compact?: boolean;
  /** まとまりが2つ以上あるときだけ名前を出す（1つのうちは今までどおりの見た目） */
  showGroupName?: boolean;
}) {
  const navigate = useNavigate();
  const { current_rank, next_rank, total_points, points_to_next, available, retry_points_needed } = status;

  // 現ランク→次ランクの区間で今どこまで来たか
  const span = next_rank ? next_rank.threshold_points - current_rank.threshold_points : 0;
  const done = next_rank ? total_points - current_rank.threshold_points : 0;
  const percent = span > 0 ? Math.min(100, Math.round((done / span) * 100)) : 100;

  return (
    <div className={`rank-card ${compact ? "rank-card-compact" : ""}`}>
      <div className="rank-card-head">
        {showGroupName && <span className="rank-group">{status.subject_group?.name}</span>}
        <span className="rank-badge">{current_rank.name}</span>
        {title && <span className="rank-title">{title}</span>}
        <span className="rank-points">{total_points}pt</span>
      </div>

      {available ? (
        <div
          className="rank-ready"
          onClick={() => navigate(`/promotion-exam?group=${status.subject_group?.id ?? ""}`)}
        >
          <p className="rank-ready-title">⚔️ 昇格試験に ちょうせんできる！</p>
          <p className="rank-ready-text">
            {next_rank?.name} をめざそう（{status.question_count}問・{status.pass_percent}%で合格）
          </p>
          <button className="btn-primary" style={{ padding: "0.5rem 1.25rem", fontSize: "0.9rem" }}>
            受ける →
          </button>
        </div>
      ) : next_rank ? (
        <>
          <div className="rank-bar">
            <div className="rank-bar-fill" style={{ width: `${percent}%` }} />
          </div>
          {retry_points_needed > 0 ? (
            <p className="rank-note">
              もう一度 昇格試験を受けるには あと <strong>{retry_points_needed}pt</strong>
            </p>
          ) : (
            <p className="rank-note">
              {next_rank.name} まで あと <strong>{points_to_next}pt</strong>
            </p>
          )}
        </>
      ) : (
        <p className="rank-note">さいこうランクに とうたつ！🐉</p>
      )}
    </div>
  );
}
