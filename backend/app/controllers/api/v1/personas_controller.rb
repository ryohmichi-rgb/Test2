module Api
  module V1
    # 「この人に聞く」— 職業の人に勉強する意味を相談する（本人のみ）。
    # 「先生に聞く」（AiTeacherController）とは回数の枠も役目も分けている。
    class PersonasController < ApplicationController
      include StudentScoped

      # GET /api/v1/students/:id/persona_usage
      def usage
        render json: usage_json
      end

      # POST /api/v1/students/:id/ask_persona
      # params: character_key, kind(why_study/how_used/childhood/free), question(自由入力時)
      def ask
        persona = PersonaCatalog.find(params[:character_key].to_s)
        return render json: { error: "その人は見つかりません" }, status: :not_found if persona.nil?

        kind = params[:kind].to_s
        unless PersonaCatalog::KINDS.key?(kind)
          return render json: { error: "質問の種類が正しくありません" }, status: :unprocessable_entity
        end

        if current_student.persona_remaining_today <= 0
          return render json: usage_json.merge(answer: nil, exhausted: true, error: "今日はここまで！また明日ね。")
        end

        result = ClaudePersona.ask(persona: persona, kind: kind, question: params[:question])

        if result.ok
          # 成功したときだけ回数を消費する（エラーで無駄に減らさない）。
          # 質問文と返答は保存しない（子どもの書いたものを残さない）。
          current_student.ai_usages.create!(kind: kind, character_key: persona.key)
          render json: usage_json.merge(answer: result.text)
        else
          render json: usage_json.merge(answer: nil, error: result.error)
        end
      end

      private

      def usage_json
        {
          used: current_student.persona_used_today,
          limit: Student.persona_daily_limit,
          remaining: current_student.persona_remaining_today
        }
      end
    end
  end
end
