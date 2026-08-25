module Api
  module V1
    class ProblemSetsController < ApplicationController
      # 範囲から動的に問題セットを返す。問題集モード・テストモード共通の出題取得。
      # GET /api/v1/problem_sets?scope_type=grade&scope_id=1&subject_id=1&count=10&mode=practice
      #
      # subject_id は範囲とは別軸のしぼり込み（省略可）。教科が1つしか無いうちは送られてこない。
      #
      # mode=practice … 練習。同じ問題ばかり出ないよう優先度をつけて選ぶ（問題集）
      # それ以外      … 範囲全体からランダム（テスト。実力測定なので解ける問題も含める）
      def show
        scope = ProblemScope.new(scope_type: params[:scope_type], scope_id: params[:scope_id], subject_id: params[:subject_id])
        unless scope.valid?
          return render json: { error: "指定された範囲に問題がありません" }, status: :unprocessable_entity
        end

        problems =
          if params[:mode] == "practice"
            scope.sample_problems_for(current_student, params[:count])
          else
            scope.sample_problems(params[:count])
          end
        render json: {
          scope_type: scope.scope_type,
          scope_id: scope.scope_id,
          subject_id: scope.subject_id,
          scope_label: scope.label,
          available_count: scope.available_count,
          problems: serialize_problems(problems)
        }
      end
    end
  end
end
