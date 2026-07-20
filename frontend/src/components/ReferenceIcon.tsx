// 参考ステータス用の手描き風SVGアイコン。
// feTurbulence + feDisplacementMap で線を揺らし、色を輪郭から少しはみ出させて手描き感を出している。

function TeacherIcon({ filterId }: { filterId: string }) {
  return (
    <g filter={`url(#${filterId})`} fill="none" strokeLinecap="round" strokeLinejoin="round">
      <g opacity="0.9">
        <rect x="7" y="9" width="52" height="40" rx="7" fill="#38a169" />
        <path d="M65 61 q1 -27 18 -29 q18 2 19 30 z" fill="#4c51bf" />
        <circle cx="82" cy="33" r="15" fill="#ffe0c2" />
        <path d="M69 30 q13 -15 25 -1 l-1 -9 q-12 -8 -23 0 z" fill="#4c51bf" />
      </g>
      <rect x="8" y="10" width="52" height="40" rx="6" stroke="#2d3748" strokeWidth="3" />
      <path d="M16 23 h27 M16 31 h19 M16 39 h23" stroke="#e6fffa" strokeWidth="2.5" />
      <circle cx="82" cy="34" r="15" stroke="#2d3748" strokeWidth="3" />
      <path d="M70 31 q12 -15 24 -1" stroke="#2d3748" strokeWidth="3" />
      <circle cx="76" cy="34" r="4.5" fill="#fff" stroke="#2d3748" strokeWidth="2.5" />
      <circle cx="89" cy="34" r="4.5" fill="#fff" stroke="#2d3748" strokeWidth="2.5" />
      <path d="M80.5 34 h4" stroke="#2d3748" strokeWidth="2.5" />
      <path d="M77 43 q5 4 10 0" stroke="#2d3748" strokeWidth="2.5" />
      <path d="M64 92 q1 -29 18 -30 q18 1 18 30" stroke="#2d3748" strokeWidth="3" />
      <path d="M97 68 l15 -20" stroke="#a0aec0" strokeWidth="4" />
      <circle cx="112" cy="47" r="3.5" fill="#f6ad55" stroke="#2d3748" strokeWidth="2.5" />
    </g>
  );
}

function ExamIcon({ filterId }: { filterId: string }) {
  return (
    <g filter={`url(#${filterId})`} fill="none" strokeLinecap="round" strokeLinejoin="round">
      <g opacity="0.9">
        <rect x="23" y="13" width="56" height="72" rx="7" fill="#ffffff" transform="rotate(-4 51 49)" />
      </g>
      <rect x="24" y="14" width="56" height="72" rx="6" stroke="#2d3748" strokeWidth="3" transform="rotate(-4 52 50)" />
      <path d="M32 36 h34 M32 46 h30 M32 56 h34 M32 66 h22" stroke="#cbd5e0" strokeWidth="2.5" transform="rotate(-4 52 50)" />
      <circle cx="69" cy="31" r="12" stroke="#e53e3e" strokeWidth="3" />
      <path d="M63 31 l4 5 l9 -11" stroke="#e53e3e" strokeWidth="3" />
      <g transform="rotate(38 86 78)">
        <g opacity="0.9"><rect x="77" y="39" width="17" height="53" rx="3" fill="#f6ad55" /></g>
        <rect x="78" y="40" width="16" height="52" rx="3" stroke="#2d3748" strokeWidth="3" />
        <path d="M78 40 l8 -14 l8 14" stroke="#2d3748" strokeWidth="3" />
        <path d="M82 30 l4 -7 l4 7 z" fill="#2d3748" />
        <path d="M78 84 h16" stroke="#2d3748" strokeWidth="3" />
        <rect x="78" y="84" width="16" height="8" rx="2" fill="#fc8181" stroke="#2d3748" strokeWidth="3" />
      </g>
    </g>
  );
}

function GraduateIcon({ filterId }: { filterId: string }) {
  return (
    <g filter={`url(#${filterId})`} fill="none" strokeLinecap="round" strokeLinejoin="round">
      <g opacity="0.9">
        <circle cx="60" cy="61" r="16" fill="#ffe0c2" />
        <path d="M35 104 q0 -25 25 -27 q25 2 25 27 z" fill="#38a169" />
        <path d="M27 44 l33 -15 l33 15 l-33 15 z" fill="#4c51bf" />
      </g>
      <circle cx="60" cy="60" r="16" stroke="#2d3748" strokeWidth="3" />
      <circle cx="54" cy="60" r="3.5" fill="#2d3748" />
      <circle cx="66" cy="60" r="3.5" fill="#2d3748" />
      <path d="M54 68 q6 5 12 0" stroke="#2d3748" strokeWidth="2.5" />
      <path d="M36 104 q0 -24 24 -26 q24 2 24 26" stroke="#2d3748" strokeWidth="3" />
      <path d="M28 44 l32 -14 l32 14 l-32 14 z" stroke="#2d3748" strokeWidth="3" />
      <path d="M60 58 v10 q0 4 12 4 q12 0 12 -4 v-10" stroke="#2d3748" strokeWidth="3" />
      <path d="M60 44 v-9" stroke="#f6ad55" strokeWidth="2.5" />
      <circle cx="60" cy="33" r="3.5" fill="#f6ad55" stroke="#2d3748" strokeWidth="2" />
    </g>
  );
}

const ICON_MAP: Record<string, (props: { filterId: string }) => React.ReactElement> = {
  "数学の先生": TeacherIcon,
  "高校受験（公立）": ExamIcon,
  "中学卒業レベル": GraduateIcon,
};

// ラベルにSVGキャラがあるかどうか
export const hasReferenceIcon = (label: string) => label in ICON_MAP;

// SVGキャラがないラベルの絵文字フォールバック
const EMOJI_FALLBACK: Record<string, string> = {
  "難関高校受験": "🏆",
  "エンジニア": "💻",
  "研究者": "🔬",
  "ゲームクリエイター": "🎮",
};

export default function ReferenceIcon({ label, size = 60 }: { label: string; size?: number }) {
  const Icon = ICON_MAP[label];
  if (!Icon) return <span style={{ fontSize: size * 0.55 }}>{EMOJI_FALLBACK[label] ?? "🎯"}</span>;

  // ラベルからASCII安全なハッシュを作り、フィルタIDと揺れのseedに使う
  // （日本語や括弧を含むIDだと url() 参照が壊れる端末があるため）
  let hash = 0;
  for (let i = 0; i < label.length; i++) {
    hash = (hash * 31 + label.charCodeAt(i)) % 100000;
  }
  const filterId = `rough-${hash}`;
  const seed = hash % 50;

  return (
    <svg width={size} height={size} viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <filter id={filterId} x="-25%" y="-25%" width="150%" height="150%">
          <feTurbulence type="fractalNoise" baseFrequency="0.03" numOctaves="2" seed={seed} result="n" />
          <feDisplacementMap in="SourceGraphic" in2="n" scale="4.5" xChannelSelector="R" yChannelSelector="G" />
        </filter>
      </defs>
      <Icon filterId={filterId} />
    </svg>
  );
}
