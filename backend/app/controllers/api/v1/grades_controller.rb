module Api
  module V1
    class GradesController < ApplicationController
      def index
        grades = Grade.ordered.includes(units: :subject)
        render json: grades.map { |g| grade_json(g) }
      end

      def show
        grade = Grade.find(params[:id])
        render json: grade_json(grade)
      end

      private

      # 無効化された単元は出さない
      def grade_json(grade)
        units = grade.units.select(&:active).sort_by(&:display_order)
        {
          id: grade.id,
          name: grade.name,
          display_order: grade.display_order,
          units: units.map { |u| { id: u.id, title: u.title, description: u.description, display_order: u.display_order, subject: u.subject.as_json(only: [:id, :name]) } }
        }
      end
    end
  end
end
