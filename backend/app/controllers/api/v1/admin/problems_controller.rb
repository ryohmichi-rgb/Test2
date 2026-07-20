module Api
  module V1
    module Admin
      class ProblemsController < BaseController
        # GET /api/v1/admin/problems?unit_id=1
        def index
          problems = Problem.where(unit_id: params[:unit_id]).includes(:choices).order(:id)
          render json: problems.map { |p| problem_json(p) }
        end

        def create
          problem = Problem.new(problem_params)
          if problem.save
            replace_choices(problem)
            render json: problem_json(problem.reload), status: :created
          else
            render json: { errors: problem.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          problem = Problem.find(params[:id])
          if problem.update(problem_params)
            replace_choices(problem)
            render json: problem_json(problem.reload)
          else
            render json: { errors: problem.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          problem = Problem.find(params[:id])
          if problem.answer_records.exists?
            render json: { error: "この問題は回答履歴があるため削除できません。無効化してください。" }, status: :unprocessable_entity
          else
            problem.destroy
            head :no_content
          end
        end

        private

        # 選択肢が渡されたら丸ごと入れ替える（choices は回答履歴に参照されないので安全）
        def replace_choices(problem)
          return if params[:choices].nil?
          problem.choices.destroy_all
          Array(params[:choices]).each do |c|
            next if c[:text].blank?
            problem.choices.create!(text: c[:text], is_correct: !!c[:is_correct])
          end
        end

        def problem_params
          params.require(:problem).permit(:unit_id, :question, :answer, :hint, :difficulty, :problem_type, :active)
        end

        def problem_json(p)
          {
            id: p.id, unit_id: p.unit_id, question: p.question, answer: p.answer, hint: p.hint,
            difficulty: p.difficulty, problem_type: p.problem_type, active: p.active,
            used: p.answer_records.exists?,
            choices: p.choices.as_json(only: [:id, :text, :is_correct])
          }
        end
      end
    end
  end
end
