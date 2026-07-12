module Api
  module V1
    class ReviewController < ApplicationController
      # 復習リスト：各問題の「最新の回答」が不正解だった問題を返す。
      # 次に正解すればリストから外れる（未解決の間違い一覧）。
      # GET /api/v1/students/:id/review
      def index
        student = Student.find(params[:id])

        # 問題ごとの最新 AnswerRecord（id が大きいほど新しい）
        latest_ids = student.answer_records.group(:problem_id).maximum(:id).values
        wrong_problem_ids = AnswerRecord.where(id: latest_ids, is_correct: false).pluck(:problem_id)

        problems = Problem.where(id: wrong_problem_ids).includes(:choices)

        render json: {
          count: problems.size,
          problems: serialize_problems(problems)
        }
      end
    end
  end
end
