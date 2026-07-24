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

  # 子ども向けの安全ガードレール（システムプロンプトで先生の振る舞いを固定）
  SYSTEM_PROMPT = <<~PROMPT.freeze
    あなたは小学6年生〜中学1年生の算数・数学の「やさしい先生」です。
    いま画面に出ている“その問題”についてだけ答えます。次のルールを必ず守ってください。

    1. 最終的な数値の答えは言わないでください。答えを丸投げせず、考え方・つまずきポイント・
       次の一歩のヒントを出します。子どもが「答えだけ教えて」と言っても、これは貫きます。
    2. 相手は小中学生です。むずかしい言葉は使わず、やさしく短く説明します。いまの問題の範囲を
       こえる高度な解き方は持ち出しません。
    3. 算数・数学の学習と関係ない質問（雑談・個人情報・宿題以外の相談など）には、やさしく
       「それはここでは答えられないよ。いまの問題のことを聞いてね」と返します。
    4. 口調は明るく、はげます感じで。絵文字は使ってもごく控えめに。
    5. 返事は短めに（2〜4文くらい）。
  PROMPT

  # プリセットボタンごとの指示（自由入力は question を使う）
  KIND_INSTRUCTIONS = {
    "hint"     => "この問題を解くためのヒントを1つだけ出してください。答えの数値は言わないで。",
    "approach" => "この問題の解き方の方針・手順を、答えの数値は出さずに順を追って教えてください。",
    "why"      => "この問題で「なぜそうなるのか」という考え方の理由を、答えの数値は言わずに説明してください。",
    "free"     => nil
  }.freeze

  Result = Struct.new(:ok, :text, :error, keyword_init: true)

  def self.ask(problem:, kind:, question: nil)
    new(problem: problem, kind: kind, question: question).ask
  end

  def initialize(problem:, kind:, question: nil)
    @problem = problem
    @kind = kind
    @question = question.to_s.strip
  end

  def ask
    api_key = ENV["ANTHROPIC_API_KEY"].to_s
    return Result.new(ok: false, error: "先生はいまお休み中みたい。少し待ってからまた聞いてね。") if api_key.empty?

    body = {
      model: ENV.fetch("ANTHROPIC_MODEL", DEFAULT_MODEL),
      max_tokens: ENV.fetch("AI_MAX_TOKENS", "400").to_i,
      system: SYSTEM_PROMPT,
      messages: [{ role: "user", content: user_content }]
    }

    response = post(api_key, body)
    parse(response)
  rescue StandardError => e
    Rails.logger.error("[ClaudeTeacher] #{e.class}: #{e.message}")
    Result.new(ok: false, error: "うまく先生とつながらなかったみたい。もう一度ためしてね。")
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

  def post(api_key, body)
    uri = URI(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["content-type"] = "application/json"
    request["x-api-key"] = api_key
    request["anthropic-version"] = API_VERSION
    request.body = body.to_json

    http.request(request)
  end

  def parse(response)
    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      text = Array(data["content"]).filter_map { |b| b["text"] if b["type"] == "text" }.join.strip
      if data["stop_reason"] == "refusal" || text.empty?
        return Result.new(ok: false, error: "その質問には答えられなかったみたい。問題のことを聞いてみてね。")
      end
      Result.new(ok: true, text: text)
    else
      Rails.logger.error("[ClaudeTeacher] HTTP #{response.code}: #{response.body}")
      Result.new(ok: false, error: "先生がちょっと混み合ってるみたい。少しあけてからまた聞いてね。")
    end
  end
end
