module Api
  module V1
    class UnitsController < ApplicationController
      def show
        unit = Unit.includes(:grade, :subject, problems: :choices).find(params[:id])
        render json: unit.as_json(
          include: {
            grade: { only: [:id, :name] },
            subject: { only: [:id, :name] },
            problems: {
              only: [:id, :question, :hint, :difficulty, :problem_type],
              include: { choices: { only: [:id, :text] } }
            }
          }
        )
      end
    end
  end
end
