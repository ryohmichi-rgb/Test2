# まなびの広場

小学6年生〜中学1年生向けの算数・数学学習サービス。
RPG風のステータス成長システムでモチベーションを維持しながら学習を続けられる。

> BGM音源: [Study Jazz / study music](https://pixabay.com/ja/music/%E3%83%A2%E3%83%80%E3%83%B3%E3%82%B8%E3%83%A3%E3%82%BA-study-jazz-study-music-564277/) — [Pixabay](https://pixabay.com/)（Pixabay Content License）

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

## 環境変数

### Railway（バックエンド）

| 変数名 | 説明 |
|--------|------|
| `DATABASE_URL` | PostgreSQL接続URL（Railway PostgreSQLサービスから自動設定） |
| `RAILS_MASTER_KEY` | `config/master.key` の値 |
| `FRONTEND_URL` | VercelのURL（CORS設定用）例: `https://xxxx.vercel.app` |
| `ADMIN_USERNAME` | 管理者にするユーザーID（省略可）。そのIDでサインアップ→デプロイで管理者になる |
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
