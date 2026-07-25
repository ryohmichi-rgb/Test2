module Api
  module V1
    class DailyProblemsController < ApplicationController
      include StudentScoped

      # 「今日の一問」を1問返す。
      # 毎日同じ問題が出ないよう、問題集と同じ優先度で選ぶ
      # （未挑戦 → 要復習 → 回復済み → 最近正解）。
      # GET /api/v1/students/:id/daily_problem
      def show
        problem = ProblemScope.all_problems.sample_problems_for(current_student, 1).first
        return render json: { problem: nil } if problem.nil?

        render json: { problem: serialize_problems([problem]).first }
      end
    end
  end
end
