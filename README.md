# まなびの広場

小学6年生〜中学1年生向けの算数・数学学習サービス。
RPG風のステータス成長システムでモチベーションを維持しながら学習を続けられる。

> BGM音源: いずれも **Alex Morgan** — [Pixabay](https://pixabay.com/)（Pixabay Content License）。
> かっこ内は Pixabay の曲ID（ファイル名の末尾と同じ）。
>
> - [Study Jazz / study music](https://pixabay.com/ja/music/%E3%83%A2%E3%83%80%E3%83%B3%E3%82%B8%E3%83%A3%E3%82%BA-study-jazz-study-music-564277/)（564277）… 「スタディジャズ」
> - Motivational Rise / inspiring push（575881）… 「やるきアップ」
> - Waiting Room / calm hold loop（575878）… 「しずかな時間」
> - Documentary Discovery / wide horizon（573939）… 「ひろい世界」
>
> BGMの曲を足すには、mp3 を `frontend/public/bgm/` に置いて
> `frontend/src/sound.ts` の `BGM_TRACKS` に1行足す（配列に無いファイルは読み込まれない）。
> 追加したら上のクレジットにも追記すること。
>
> 配信しているファイルは **128kbps** に落としてある（Pixabay の配布は256kbps）。
> 新しい曲も同じように揃える:
>
> ```sh
> lame --decode もとの.mp3 tmp.wav && lame -b 128 -m j -q 2 tmp.wav 置くファイル.mp3
> ```

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
| `SECRET_KEY_BASE` | 署名用の秘密（`RAILS_MASTER_KEY` の代わりにこちらを推奨。下の「master.key について」参照） |
| `RAILS_MASTER_KEY` | `config/master.key` の値。`SECRET_KEY_BASE` を設定するなら不要 |
| `FRONTEND_URL` | VercelのURL（CORS設定用）例: `https://xxxx.vercel.app` |
| `ADMIN_USERNAME` | 管理者にするユーザーID（省略可）。そのIDでサインアップ→デプロイで管理者になる |
| `ANTHROPIC_API_KEY` | 「先生に聞く」（生成AI）用のClaude APIキー。未設定なら機能はやさしくお休み表示になる |
| `ANTHROPIC_MODEL` | 使うモデル（省略可、デフォルト: `claude-haiku-4-5`）。物足りなければ差し替え |
| `AI_DAILY_LIMIT` | 1人あたり「先生に聞く」の1日上限回数（省略可、デフォルト: `20`） |
| `AI_PERSONA_DAILY_LIMIT` | 「この人に聞く」の1日あたり上限（既定5・先生とは別枠） |
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

## 開発をしばらく止めるとき / 再開するとき

Railway を消すと **DB もいっしょに消えます。** アプリは作り直せますが、生徒が作ったデータは戻りません。

| seed が入れ直すもの | 戻らないもの |
|---------------------|--------------|
| 学年・教科・教科のまとまり | 生徒アカウント（`students`） |
| 単元・教材・問題・選択肢 | 回答履歴（`answer_records`）← 成長曲線とポイントの根拠 |
| ステータス種別・ランク・参考ステータス | ステータス値・ランク・バッジ・目標・テスト履歴・既読 |

とくに注意する2つ:

- **`daily_quotas` は原理的に復元できない。** ノルマは `goals` と当時のステータス値から計算するが
  `goals` は履歴を持たないので、その日のうちに記録するしかない。消すとノルマ達成の連続は二度と戻らない。
- **管理画面で直した値は DB にしかない。** ランクのしきい値・合格ライン・問題数は
  seed が初回作成のときだけ入れる形なので、画面で調整した値は seed に書かれていない。
  追加した教科・単元・問題、問題の修正・無効化も同じ。

### 止める前：バックアップを取る

Railway の PostgreSQL サービスの接続情報（`DATABASE_URL`）を使う。

```bash
# リポジトリの外に出す（ダンプは個人データなので絶対にコミットしない）
pg_dump "$DATABASE_URL" -Fc -f ~/manabi-$(date +%Y%m%d).dump
```

⚠️ このダンプには**子どもの名前とパスワードハッシュ**が入る。このリポジトリは公開なので、
うっかり入れないよう `*.dump` / `*.sql` は `.gitignore` に入れてあるが、置き場所は repo の外にする。

### 再開するとき

1. **鍵を作り直す**（下の「master.key について」を必ず読む）
2. Railway に PostgreSQL + バックエンドを作り、環境変数を入れる（「環境変数」の節を参照）
3. **空のDBにダンプを戻してから**デプロイする。`bin/docker-entrypoint` が `db:prepare` を走らせるので、
   未適用のマイグレーションだけが上に乗る（先にデプロイしてから戻すと衝突する）

   ```bash
   pg_restore -d "$NEW_DATABASE_URL" --no-owner --no-privileges ~/manabi-YYYYMMDD.dump
   ```
4. URLが変わるので差し替える: `FRONTEND_URL`（Railway側）と `VITE_API_URL`（Vercel側）

### master.key について

**`config/master.key` は過去に一度このリポジトリ（公開）にコミットされた。** `.gitignore` に入れて
追跡からは外したが、**git の履歴には残るので、あの鍵はもう秘密ではない。**

いまのところ悪用はできない（認証トークンは `password_salt` を署名に含めるので、鍵だけでは偽造できず、
`credentials.yml.enc` の中身も Rails 既定の `secret_key_base` だけ）。
ただし credentials に本物の秘密を入れた瞬間に漏れるので、**再開するときに手を打つ。**

#### 推奨：`RAILS_MASTER_KEY` をやめて `SECRET_KEY_BASE` を直接渡す

このアプリは credentials を `secret_key_base` にしか使っていない（`Rails.application.credentials` を
読むコードは1行も無い）。なので本番には**鍵そのものを置かず、値を直接渡せばよい**。
`ENV["SECRET_KEY_BASE"]` は credentials より優先されるので、`config/master.key` も
`RAILS_MASTER_KEY` も本番では不要になり、「鍵が漏れる」問題の根が消える。

```bash
# 新しい値を作る（出た文字列を Railway の SECRET_KEY_BASE に入れる）
cd backend
bundle exec ruby -rsecurerandom -e 'puts SecureRandom.hex(64)'
```

Railway の環境変数から **`RAILS_MASTER_KEY` を消して** `SECRET_KEY_BASE` を入れる。
`config/master.key` はローカル開発用に手元へ残すだけ（git には入らない）。

> 検証ずみ: 鍵ファイルも `RAILS_MASTER_KEY` も無い状態で `SECRET_KEY_BASE` だけ渡すと、
> 本番モードでその値が使われる。

#### 代わりに鍵を作り直す場合

```bash
cd backend
rm config/master.key config/credentials.yml.enc
EDITOR=true bundle exec bin/rails credentials:edit   # 新しい鍵と credentials ができる
```

できた `config/master.key` の中身を Railway の `RAILS_MASTER_KEY` に入れる。

> ⚠️ **`RAILS_MASTER_KEY` が credentials と食い違うと、本番は起動時に落ちる**
> （`ActiveSupport::MessageEncryptor::InvalidMessage`）。鍵を作り直したら必ず環境変数も更新する。
> `EDITOR` を指定しないと「エディタを指定せよ」という案内が出るが、ファイル自体は作られる。

どちらの方法でも、**`secret_key_base` が変わると発行済みのログイントークンは全部失効する**ので、
全員が1回ログインし直しになる。
