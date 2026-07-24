module Api
  module V1
    # 「先生に聞く」— その問題の文脈つきで Claude に質問する（本人のみ）。
    class AiTeacherController < ApplicationController
      include StudentScoped

      # GET /api/v1/students/:id/ai_usage
      # 今日あと何回聞けるかを返す（パネルの「今日はあと○回」表示用）
      def usage
        render json: usage_json
      end

      # POST /api/v1/students/:id/ask_teacher
      # params: problem_id, kind(hint/approach/why/free), question(自由入力時)
      def ask
        kind = params[:kind].to_s
        return render json: { error: "質問の種類が正しくありません" }, status: :unprocessable_entity unless AiUsage::KINDS.include?(kind)

        # 1日の上限に達していたら消費せずに知らせる
        if current_student.ai_remaining_today <= 0
          return render json: usage_json.merge(answer: nil, exhausted: true, error: "今日はここまで！また明日ね。")
        end

        problem = Problem.includes(:choices).find_by(id: params[:problem_id])
        return render json: { error: "問題が見つかりません" }, status: :not_found if problem.nil?

        result = ClaudeTeacher.ask(problem: problem, kind: kind, question: params[:question])

        if result.ok
          # 成功したときだけ回数を消費する（エラーで無駄に減らさない）
          current_student.ai_usages.create!(problem_id: problem.id, kind: kind)
          render json: usage_json.merge(answer: result.text)
        else
          render json: usage_json.merge(answer: nil, error: result.error)
        end
      end

      private

      def usage_json
        {
          used: current_student.ai_used_today,
          limit: Student.ai_daily_limit,
          remaining: current_student.ai_remaining_today
        }
      end
    end
  end
end
