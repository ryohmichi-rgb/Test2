import type { DailyQuota } from "../types";

// 応援メッセージを語る手描き風の子キャラ
function Mascot() {
  return (
    <svg width="60" height="60" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
      <defs>
        <filter id="mascot-rough" x="-25%" y="-25%" width="150%" height="150%">
          <feTurbulence type="fractalNoise" baseFrequency="0.03" numOctaves="2" seed="7" result="n" />
          <feDisplacementMap in="SourceGraphic" in2="n" scale="4" xChannelSelector="R" yChannelSelector="G" />
        </filter>
      </defs>
      <g filter="url(#mascot-rough)" fill="none" strokeLinecap="round" strokeLinejoin="round">
        <g opacity="0.9">
          <circle cx="60" cy="54" r="30" fill="#ffe0c2" />
          <path d="M30 54 q0 -34 30 -34 q30 0 30 34 q-30 -10 -60 0 z" fill="#4c51bf" />
          <path d="M40 100 q0 -20 20 -22 q20 2 20 22 z" fill="#38a169" />
        </g>
        <circle cx="60" cy="54" r="30" stroke="#2d3748" strokeWidth="3" />
        <path d="M31 52 q0 -32 29 -32 q29 0 29 32" stroke="#2d3748" strokeWidth="3" />
        <circle cx="50" cy="52" r="4" fill="#2d3748" />
        <circle cx="70" cy="52" r="4" fill="#2d3748" />
        <path d="M52 64 q8 7 16 0" stroke="#2d3748" strokeWidth="3" />
        <circle cx="44" cy="61" r="3.5" fill="#fc8181" opacity="0.6" />
        <circle cx="76" cy="61" r="3.5" fill="#fc8181" opacity="0.6" />
        <path d="M40 100 q0 -20 20 -22 q20 2 20 22" stroke="#2d3748" strokeWidth="3" />
      </g>
    </svg>
  );
}

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
