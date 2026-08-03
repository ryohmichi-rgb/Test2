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

// ===== BGM（音楽トラック） =====
//
// 曲は複数持てる。既定は「ランダム」で、1曲終わるたびに別の曲に移る（同じ曲は続けて引かない）。
// せってい画面で曲を固定でき、そのときはその曲だけをループする。
//
// 曲を足すときは frontend/public/bgm/ に mp3 を置いて、この配列に1行足すだけ。
// public/ はViteのバンドル対象外なので、**配列に無いファイルは誰も取りに行かない**。
// 音源はライセンスを確認し、README にクレジットを書くこと。
export type BgmTrack = { id: string; label: string; file: string };

export const BGM_TRACKS: BgmTrack[] = [
  { id: "study-jazz", label: "スタディジャズ", file: "/bgm/study-jazz.mp3" },
];

export const BGM_RANDOM = "random";

const DEFAULT_BGM_VOLUME = 0.3;
let bgm: HTMLAudioElement | null = null;
let currentTrackId: string | null = null; // いま鳴っている曲

// 次にかける曲を決める。「ランダム」のときだけ抽選し、直前と同じ曲は避ける
// （曲が1つしかなければ避けようがないのでそのまま返す）。
// 副作用を持たせないのは、抽選のルールだけを単体で確かめられるようにするため。
export function nextTrackId(
  selected: string,
  playing: string | null,
  tracks: BgmTrack[] = BGM_TRACKS
): string | null {
  if (tracks.length === 0) return null;
  if (selected !== BGM_RANDOM && tracks.some((t) => t.id === selected)) return selected;
  const others = tracks.filter((t) => t.id !== playing);
  const pool = others.length > 0 ? others : tracks;
  return pool[Math.floor(Math.random() * pool.length)].id;
}

function bgmEl(): HTMLAudioElement {
  if (!bgm) {
    bgm = new Audio();
    bgm.preload = "none"; // src を入れるまで通信しない（全曲を先読みしない）
    bgm.volume = bgmVolume();
    // 曲が終わったら次へ。曲を固定しているときは loop=true なのでここには来ない。
    bgm.addEventListener("ended", () => { if (isBgmOn()) playTrack(); });
  }
  return bgm;
}

// 選択に従って1曲かける。鳴っている曲と違うときだけ src を差し替える。
function playTrack(): void {
  const id = nextTrackId(bgmTrack(), currentTrackId);
  const track = BGM_TRACKS.find((t) => t.id === id);
  if (!track) return;

  const el = bgmEl();
  // 曲を固定しているとき・そもそも1曲しかないときはブラウザ標準のループに任せる。
  // ended を挟まないぶん確実で、曲が1つだけなら今までとまったく同じ動きになる。
  el.loop = BGM_TRACKS.length <= 1 || bgmTrack() !== BGM_RANDOM;
  if (currentTrackId !== track.id) {
    currentTrackId = track.id;
    el.src = track.file;
  }
  el.play().catch(() => { /* 自動再生制限などは無視 */ });
}

export function isBgmOn(): boolean {
  return localStorage.getItem("bgm") === "on"; // 既定オフ（勝手に鳴らさない）
}
export function bgmVolume(): number {
  const v = Number(localStorage.getItem("bgmVolume"));
  return Number.isFinite(v) && v > 0 ? v : DEFAULT_BGM_VOLUME;
}
export function setBgmVolume(v: number): void {
  localStorage.setItem("bgmVolume", String(v));
  if (bgm) bgm.volume = v;
}
export function bgmTrack(): string {
  const id = localStorage.getItem("bgmTrack");
  // 知らないIDならランダム扱い。曲を差し替えても設定が壊れない。
  return id && BGM_TRACKS.some((t) => t.id === id) ? id : BGM_RANDOM;
}
export function setBgmTrack(id: string): void {
  localStorage.setItem("bgmTrack", id);
  if (!isBgmOn()) return;
  // 「ランダム」に戻したときは、いまの曲を最後まで流してから次に移る（急に曲が切れない）
  if (id === BGM_RANDOM && currentTrackId) { bgmEl().loop = false; return; }
  playTrack();
}
export function startBgm(): void {
  localStorage.setItem("bgm", "on");
  playTrack();
}
export function stopBgm(): void {
  localStorage.setItem("bgm", "off");
  bgmEl().pause();
}
export function toggleBgm(): boolean {
  if (isBgmOn()) { stopBgm(); return false; }
  startBgm();
  return true;
}

// リロード後、BGMがオンなら最初の操作で自動再開（ブラウザの自動再生制限対策）
if (typeof window !== "undefined" && isBgmOn()) {
  const resume = () => { playTrack(); window.removeEventListener("pointerdown", resume); };
  window.addEventListener("pointerdown", resume, { once: true });
}
