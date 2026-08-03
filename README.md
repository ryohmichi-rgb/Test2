# まなびの広場

小学6年生〜中学1年生向けの算数・数学学習サービス。
RPG風のステータス成長システムでモチベーションを維持しながら学習を続けられる。

> BGM音源: [Study Jazz / study music](https://pixabay.com/ja/music/%E3%83%A2%E3%83%80%E3%83%B3%E3%82%B8%E3%83%A3%E3%82%BA-study-jazz-study-music-564277/) — [Pixabay](https://pixabay.com/)（Pixabay Content License）
>
> BGMの曲を足すには、mp3 を `frontend/public/bgm/` に置いて
> `frontend/src/sound.ts` の `BGM_TRACKS` に1行足す（配列に無いファイルは読み込まれない）。
> 128kbps 程度で書き出せば1曲2〜3MBに収まる。追加したら上のクレジットにも追記すること。

## 技術スタック

| 項目 | 技術 |
|------|------|
| バックエンド | Ruby on Rails 8 (API mode) + PostgreSQL |
| フロントエンド | React + TypeScript + Vite |
| バックエンドホスティング | Railway |
| フロントエンドホスティング | Vercel |

## 機能

- 名前を入力してすぐ学習開始（アカウント登録不要）
- 学年・単元ごとの問題演習（記述式・選択式）
- 正解時にヒントと解説表示
- ステータス画面（計算力・数的センス・図形力・文章読解力・論理力）
- 問題正解でステータスポイント加算
- ステータスごとに目標値・目標日付を設定
- 参考ステータス（高校受験・数学の先生など）との比較
- 学習進捗ページ（単元ごとの正答率）
- 単元ごとの教材（Markdown＋KaTeXで分数・数式をきれいに表示、図も貼れる）
- 「先生に聞く」（生成AI）— その問題のヒント・解き方・理由をClaudeが返す（答えは丸投げしない・1日上限つき）

## 環境変数

### Railway（バックエンド）

| 変数名 | 説明 |
|--------|------|
| `DATABASE_URL` | PostgreSQL接続URL（Railway PostgreSQLサービスから自動設定） |
| `RAILS_MASTER_KEY` | `config/master.key` の値 |
| `FRONTEND_URL` | VercelのURL（CORS設定用）例: `https://xxxx.vercel.app` |
| `ADMIN_USERNAME` | 管理者にするユーザーID（省略可）。そのIDでサインアップ→デプロイで管理者になる |
| `ANTHROPIC_API_KEY` | 「先生に聞く」（生成AI）用のClaude APIキー。未設定なら機能はやさしくお休み表示になる |
| `ANTHROPIC_MODEL` | 使うモデル（省略可、デフォルト: `claude-haiku-4-5`）。物足りなければ差し替え |
| `AI_DAILY_LIMIT` | 1人あたり「先生に聞く」の1日上限回数（省略可、デフォルト: `20`） |
| `AI_MAX_TOKENS` | 返答の長さ上限（省略可、デフォルト: `400`≒日本語200〜300字） |
| `RAILS_LOG_LEVEL` | ログレベル（省略可、デフォルト: `info`） |

### Vercel（フロントエンド）

| 変数名 | 説明 |
|--------|------|
| `VITE_API_URL` | RailwayのバックエンドURL 例: `https://xxxx.up.railway.app/api/v1` |

## ローカル開発

### バックエンド

```bash
cd backend
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
```

### フロントエンド

```bash
cd frontend
npm install
npm run dev
```

フロントエンドは `http://localhost:5173`、バックエンドは `http://localhost:3000` で起動。

## API エンドポイント

| メソッド | パス | 説明 |
|----------|------|------|
| POST | `/api/v1/students` | 生徒作成 |
| GET | `/api/v1/students/:id` | 生徒情報取得 |
| GET | `/api/v1/students/:id/stats` | ステータス取得 |
| PUT | `/api/v1/students/:id/goals` | 目標設定 |
| GET | `/api/v1/students/:id/progress` | 学習進捗取得 |
| GET | `/api/v1/grades` | 学年一覧 |
| GET | `/api/v1/units/:id` | 単元詳細 |
| POST | `/api/v1/answer_records` | 回答送信 |
| GET | `/api/v1/reference_stats` | 参考ステータス取得 |
