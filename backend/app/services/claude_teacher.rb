require "net/http"
require "json"

# 「先生に聞く」— Claude API を Rails バックエンド経由で呼ぶ。
# APIキーは環境変数のみ（絶対にフロントへ出さない）。
#
# 環境変数:
#   ANTHROPIC_API_KEY  … 必須。Anthropic Console のAPIキー
#   ANTHROPIC_MODEL    … 任意。既定 claude-haiku-4-5（速い・安い）。物足りなければ差し替え
#   AI_MAX_TOKENS      … 任意。返答の長さ上限。既定 400（＝日本語で約200〜300字）
class ClaudeTeacher
  API_URL       = "https://api.anthropic.com/v1/messages".freeze
  API_VERSION   = "2023-06-01".freeze
  DEFAULT_MODEL = "claude-haiku-4-5".freeze

  # 「先生」としての役目。守るべき線（AiSafety.common_rules）は全キャラ共通なので、
  # ここにはこの役目に固有のことだけ書く。教科名は解いている問題から差し込む。
  #
  # 注意: LaTeX を書くのでヒアドキュメントは必ず `<<~'ROLE'`（補間なし）にする。
  ROLE_TEMPLATE = <<~'ROLE'.freeze
    あなたは小学6年生〜中学1年生の%{subject}の「やさしい先生」です。
    いま画面に出ている“その問題”についてだけ答えます。

    【この役目で特に守ること】
    ・最終的な数値の答えは言いません。答えを丸投げせず、考え方・つまずきポイント・
      次の一歩のヒントを出します。子どもが「答えだけ教えて」と言っても、これは貫きます。
    ・いまの問題の範囲をこえる高度な解き方は持ち出しません。
    ・口調は明るく、はげます感じで。絵文字は使ってもごく控えめに。
  ROLE

  def self.system_prompt(subject)
    "#{ROLE_TEMPLATE % { subject: subject }}\n#{AiSafety.common_rules(subject)}"
  end

  # プリセットボタンごとの指示（自由入力は question を使う）
  KIND_INSTRUCTIONS = {
    "hint"     => "この問題を解くためのヒントを1つだけ出してください。答えの数値は言わないで。",
    "approach" => "この問題の解き方の方針・手順を、答えの数値は出さずに順を追って教えてください。",
    "why"      => "この問題で「なぜそうなるのか」という考え方の理由を、答えの数値は言わずに説明してください。",
    "free"     => nil
  }.freeze

  Result = ClaudeClient::Result

  def self.ask(problem:, kind:, question: nil)
    new(problem: problem, kind: kind, question: question).ask
  end

  def initialize(problem:, kind:, question: nil)
    @problem = problem
    @kind = kind
    @question = AiSafety.trim_question(question)
  end

  def ask
    ClaudeClient.ask(
      system: self.class.system_prompt(AiSafety.subject_label_for(@problem)),
      user: user_content,
      on_refusal: "その質問には答えられなかったみたい。問題のことを聞いてみてね。"
    )
  end

  private

  # 「その問題」の文脈＋子どもの要望を1つのメッセージにまとめる
  def user_content
    lines = ["【いま解いている問題】", @problem.question]

    if @problem.problem_type == "multiple_choice" && @problem.choices.present?
      lines << "（選択肢）#{@problem.choices.map(&:text).join(' / ')}"
    end

    lines << ""
    ask_text = KIND_INSTRUCTIONS[@kind]
    if ask_text
      lines << ask_text
    else
      lines << "【質問】#{@question.presence || 'この問題について教えて'}"
    end

    lines.join("\n")
  end

end
