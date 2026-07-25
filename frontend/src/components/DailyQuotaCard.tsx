import type { DailyQuota } from "../types";

export default function DailyQuotaCard({ quota, onStart }: { quota: DailyQuota; onStart: () => void }) {
  const done = quota.target_points > 0 && quota.earned_points >= quota.target_points;
  const pct = quota.target_points > 0 ? Math.min((quota.earned_points / quota.target_points) * 100, 100) : 0;

  return (
    <div className="quota-card">
      <div className="quota-head">
        <span className="quota-title">今日のノルマ</span>
        {quota.streak > 0 && (
          <span className="quota-streak">🔥 {quota.streak}日れんぞく</span>
        )}
      </div>

      {quota.exhausted ? (
        // 満点で解ける問題を今のところ全部やりきった状態。
        // 達成できないノルマを出し続けても意味がないので、ねぎらいと次の見通しを出す。
        <p className="quota-done">
          🎉 いまの問題はぜんぶクリア！
          {quota.returning_count > 0 && (
            <span className="quota-returning">
              少し時間がたつと {quota.returning_count}問 が復習としてもどってくるよ
            </span>
          )}
        </p>
      ) : done ? (
        <p className="quota-done">✓ 今日のノルマ達成！このちょうしで続けよう</p>
      ) : (
        <>
          <div className="quota-bar-row">
            <div className="quota-bar-track">
              <div className="quota-bar-fill" style={{ width: `${pct}%` }} />
            </div>
            <span className="quota-bar-num">{quota.earned_points} / {quota.target_points}pt</span>
          </div>
          <div className="quota-foot">
            <span className="quota-hint">
              目安 約{quota.approx_problems}問
              {!quota.has_goal && "（目標を決めるとノルマが最適化されます）"}
            </span>
            <button className="btn-primary quota-btn" onClick={onStart}>今日の学習へ</button>
          </div>
        </>
      )}
    </div>
  );
}
