# CLAUDE.md

このリポジトリで作業するAI（Claude Code）への指示。

## プロジェクト概要

「まなびの広場」— 小6〜中1向けの算数・数学学習サービス。RPG風のステータス成長で
継続学習を促す。詳細は [README.md](./README.md)（使う人向け）と
[DESIGN.md](./DESIGN.md)（設計）を参照。

- バックエンド: Ruby on Rails 8 (API mode) + PostgreSQL（`backend/`）
- フロントエンド: React + TypeScript + Vite（`frontend/`）
- デプロイ: バックエンド=Railway / フロントエンド=Vercel

## ドキュメント更新ルール（重要）

**機能・データモデル・API・主要ロジックを変更したら、同じコミットで
[DESIGN.md](./DESIGN.md) を必ず更新する。** 実装とドキュメントを乖離させない。

具体的には、以下を変更したら DESIGN.md の該当セクションも直す:

- テーブル/カラムの追加・変更 → 「2. データモデル」（ER図含む）
- ポイント/ボーナス/ノルマ/成長曲線などの計算ロジック → 「3. 主要ロジック」
- APIエンドポイントの追加・変更 → 「4. API一覧」
- 画面/ルートの追加・変更 → 「5. 画面遷移」「6. フロント構成」

セットアップ手順や環境変数を変えたら README.md も更新する。

## 開発フロー

- 変更後は必ずフロントの型チェック＆ビルドを通す: `cd frontend && npm run build`
- バックエンドはローカルにDBがない前提。構文チェックとルート確認で代替:
  `cd backend && ruby -c <file>` / `bundle exec bin/rails routes`
- コミットは意味のある単位で。変更が完了したら main にプッシュ（Railway/Vercelが自動デプロイ）。
- DBマイグレーションはデプロイ時に自動実行される（`bin/docker-entrypoint`）。

## 設計上の約束

- ステータスは `stat_types` テーブルで管理し、後から追加できる構造を保つ。
- 演習・問題集・テスト・復習はすべて `AnswerRecord` 経由でポイント加算する（経路を分けない）。
- 問題セットの抽出は `ProblemScope`（範囲→問題）に集約する。両モードで共用。
- テストのfarming対策は「自己ベスト更新時のみボーナス」で行う。通常ポイントは再挑戦でも加算。
- 成長曲線の過去分は `answer_records` から再構築する（`student_stats` は現在値のみ）。

## コードスタイル

- 周囲のコードに合わせる（コメント量・命名・書き方）。UI文言は日本語（対象が小中学生）。
- フロントの共通表示は `components/`（例: `ProblemView`, `GrowthChart`）に切り出して再利用する。
