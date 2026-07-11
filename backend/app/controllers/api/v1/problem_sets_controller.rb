module Api
  module V1
    class ProblemSetsController < ApplicationController
      # 範囲から動的に問題セットを返す。問題集モード・テストモード共通の出題取得。
      # GET /api/v1/problem_sets?scope_type=grade&scope_id=1&count=10
      def show
        scope = ProblemScope.new(scope_type: params[:scope_type], scope_id: params[:scope_id])
        unless scope.valid?
          return render json: { error: "指定された範囲に問題がありません" }, status: :unprocessable_entity
        end

        problems = scope.sample_problems(params[:count])
        render json: {
          scope_type: scope.scope_type,
          scope_id: scope.scope_id,
          scope_label: scope.label,
          available_count: scope.available_count,
          problems: serialize_problems(problems)
        }
      end
    end
  end
end
