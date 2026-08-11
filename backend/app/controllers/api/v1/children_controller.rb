module Api
  module V1
    # 保護者が見られる子どもの一覧。
    # 個々の学習状況は既存の /students/:id/* をそのまま使う（StudentScoped が保護者を通す）。
    class ChildrenController < ApplicationController
      def index
        return head :forbidden unless current_student.parent?

        payload = current_student.children.order(:name).map do |child|
          {
            id: child.id,
            name: child.name,
            username: child.username,
            total_points: child.total_points,
            rank: child.current_rank&.name,
            streak: child.study_streak,
            last_studied_on: child.last_studied_on
          }
        end
        render json: payload
      end
    end
  end
end
