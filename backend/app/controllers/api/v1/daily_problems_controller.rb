module Api
  module V1
    class DailyProblemsController < ApplicationController
      include StudentScoped

      # 「今日の一問」用にランダムな1問を返す。
      # GET /api/v1/students/:id/daily_problem
      def show
        problem = Problem.active_only.includes(:choices).order(Arel.sql("RANDOM()")).first
        return render json: { problem: nil } if problem.nil?

        render json: { problem: serialize_problems([problem]).first }
      end
    end
  end
end
