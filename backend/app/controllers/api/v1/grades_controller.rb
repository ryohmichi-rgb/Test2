module Api
  module V1
    class GradesController < ApplicationController
      def index
        grades = Grade.ordered.includes(units: :subject)
        render json: grades.as_json(include: { units: { include: :subject, only: [:id, :title, :description, :display_order] } })
      end

      def show
        grade = Grade.find(params[:id])
        render json: grade.as_json(include: { units: { include: :subject, only: [:id, :title, :description, :display_order] } })
      end
    end
  end
end
