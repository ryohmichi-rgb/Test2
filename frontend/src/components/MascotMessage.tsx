import type { DailyQuota } from "../types";
import Mascot from "./Mascot";

function buildMessage(name: string, quota: DailyQuota | null): string {
  const hour = new Date().getHours();
  const greeting = hour < 11 ? "おはよう" : hour < 18 ? "こんにちは" : "こんばんは";

  if (!quota) return `${greeting}、${name}さん！`;

  const remaining = Math.max(quota.target_points - quota.earned_points, 0);
  const done = quota.target_points > 0 && quota.earned_points >= quota.target_points;

  if (done) return `今日のノルマ達成！${name}さん、すごい！🎉`;
  if (quota.studied_today) return `いいちょうし！あと${remaining}ptでノルマ達成だよ。`;
  if (quota.streak >= 3) return `${greeting}！${quota.streak}日れんぞく中。今日も続けよう！🔥`;
  return `${greeting}、${name}さん！今日もいっしょにがんばろう！`;
}

export default function MascotMessage({ name, quota }: { name: string; quota: DailyQuota | null }) {
  return (
    <div className="mascot-row">
      <Mascot />
      <div className="mascot-bubble">{buildMessage(name, quota)}</div>
    </div>
  );
}
