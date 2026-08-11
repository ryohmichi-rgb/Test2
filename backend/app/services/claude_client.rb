require "net/http"
require "json"

# Claude API を叩く共通部分。キャラごとに違うのはプロンプトだけなので、
# 通信・エラー処理・返答の取り出しはここ1か所に置く。
#
# APIキーは環境変数のみ（絶対にフロントへ出さない）。
#   ANTHROPIC_API_KEY … 必須
#   ANTHROPIC_MODEL   … 任意。既定 claude-haiku-4-5（速い・安い）
#   AI_MAX_TOKENS     … 任意。返答の長さ上限。既定 400（日本語で約200〜300字）
class ClaudeClient
  API_URL       = "https://api.anthropic.com/v1/messages".freeze
  API_VERSION   = "2023-06-01".freeze
  DEFAULT_MODEL = "claude-haiku-4-5".freeze

  Result = Struct.new(:ok, :text, :error, keyword_init: true)

  def self.ask(system:, user:, on_refusal: nil)
    api_key = ENV["ANTHROPIC_API_KEY"].to_s
    return Result.new(ok: false, error: "いまお休み中みたい。少し待ってからまた聞いてね。") if api_key.empty?

    body = {
      model: ENV.fetch("ANTHROPIC_MODEL", DEFAULT_MODEL),
      max_tokens: ENV.fetch("AI_MAX_TOKENS", "400").to_i,
      system: system,
      messages: [{ role: "user", content: user }]
    }
    parse(post(api_key, body), on_refusal)
  rescue StandardError => e
    Rails.logger.error("[ClaudeClient] #{e.class}: #{e.message}")
    Result.new(ok: false, error: "うまくつながらなかったみたい。もう一度ためしてね。")
  end

  def self.post(api_key, body)
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
  private_class_method :post

  def self.parse(response, on_refusal)
    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      text = Array(data["content"]).filter_map { |b| b["text"] if b["type"] == "text" }.join.strip
      if data["stop_reason"] == "refusal" || text.empty?
        return Result.new(ok: false, error: on_refusal || "その質問には答えられなかったみたい。")
      end
      Result.new(ok: true, text: text)
    else
      Rails.logger.error("[ClaudeClient] HTTP #{response.code}: #{response.body}")
      Result.new(ok: false, error: "ちょっと混み合ってるみたい。少しあけてからまた聞いてね。")
    end
  end
  private_class_method :parse
end
