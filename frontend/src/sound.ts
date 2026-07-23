// 効果音。Web Audio API で合成するので音源ファイルは不要。
// ブラウザの制限により、ユーザー操作（クリック等）のハンドラ内から呼ぶこと。

let ctx: AudioContext | null = null;

function context(): AudioContext | null {
  if (typeof window === "undefined") return null;
  const AC = window.AudioContext || (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
  if (!AC) return null;
  if (!ctx) ctx = new AC();
  return ctx;
}

export function isSoundOn(): boolean {
  return localStorage.getItem("sound") !== "off"; // 既定オン
}
export function setSoundOn(on: boolean): void {
  localStorage.setItem("sound", on ? "on" : "off");
}

// 単音を鳴らす
function blip(freq: number, startAt: number, dur: number, type: OscillatorType, peak: number) {
  const ac = context();
  if (!ac) return;
  const t0 = ac.currentTime + startAt;
  const osc = ac.createOscillator();
  const gain = ac.createGain();
  osc.type = type;
  osc.frequency.value = freq;
  gain.gain.setValueAtTime(0.0001, t0);
  gain.gain.linearRampToValueAtTime(peak, t0 + 0.01);
  gain.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
  osc.connect(gain).connect(ac.destination);
  osc.start(t0);
  osc.stop(t0 + dur);
}

function play(fn: () => void) {
  if (!isSoundOn()) return;
  const ac = context();
  if (!ac) return;
  if (ac.state === "suspended") ac.resume();
  fn();
}

// 正解：明るい2音
export function playCorrect(): void {
  play(() => { blip(660, 0, 0.12, "sine", 0.25); blip(990, 0.09, 0.16, "sine", 0.22); });
}
// 不正解：やわらかい低音（きつくしない）
export function playIncorrect(): void {
  play(() => { blip(200, 0, 0.18, "triangle", 0.16); blip(150, 0.12, 0.2, "triangle", 0.14); });
}
// 完了・達成：上昇アルペジオ（ファンファーレ風）
export function playFinish(): void {
  play(() => { [523, 659, 784, 1046].forEach((f, i) => blip(f, i * 0.1, 0.22, "sine", 0.2)); });
}
