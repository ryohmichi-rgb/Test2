module Api
  module V1
    class AnswerRecordsController < ApplicationController
      def create
        record = AnswerRecord.new(answer_record_params.merge(student: current_student))
        if record.save
          render json: {
            is_correct: record.is_correct,
            correct_answer: record.problem.answer,
            explanation: record.is_correct ? "正解です！" : "惜しい！正解は「#{record.problem.answer}」です。"
          }, status: :created
        else
          render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def answer_record_params
        params.require(:answer_record).permit(:problem_id, :submitted_answer)
      end
    end
  end
end
