module Api
  module V1
    module Admin
      class UnitsController < BaseController
        def index
          units = Unit.includes(:grade, :subject, :stat_type, :problems).order(:grade_id, :display_order)
          render json: units.map { |u| unit_json(u) }
        end

        def create
          unit = Unit.new(unit_params)
          if unit.save
            render json: unit_json(unit), status: :created
          else
            render json: { errors: unit.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          unit = Unit.find(params[:id])
          if unit.update(unit_params)
            render json: unit_json(unit)
          else
            render json: { errors: unit.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          unit = Unit.find(params[:id])
          if used?(unit)
            render json: { error: "この単元は回答履歴があるため削除できません。無効化してください。" }, status: :unprocessable_entity
          else
            unit.destroy
            head :no_content
          end
        end

        private

        def used?(unit)
          AnswerRecord.where(problem_id: unit.problem_ids).exists?
        end

        def unit_params
          params.require(:unit).permit(:title, :description, :lesson_body, :display_order, :grade_id, :subject_id, :stat_type_id, :active)
        end

        def unit_json(u)
          {
            id: u.id, title: u.title, description: u.description, lesson_body: u.lesson_body,
            display_order: u.display_order, active: u.active,
            grade_id: u.grade_id, grade: u.grade&.name,
            subject_id: u.subject_id, subject: u.subject&.name,
            stat_type_id: u.stat_type_id, stat_type: u.stat_type&.name,
            problem_count: u.problems.size,
            used: used?(u)
          }
        end
      end
    end
  end
end
