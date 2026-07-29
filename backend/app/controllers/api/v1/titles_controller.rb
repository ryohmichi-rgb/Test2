module Api
  module V1
    # 称号の付け替え。名乗れるのは「称号つきバッジを獲得ずみ」のものだけ。
    class TitlesController < ApplicationController
      include StudentScoped

      # PUT /api/v1/students/:id/title  { title_key: "unit_master" }
      # title_key に null / 空文字を渡すと称号を外す。
      def update
        student = Student.find(params[:id])
        key = params[:title_key].presence

        if key.nil?
          student.update!(title_key: nil)
          return render json: { title_key: nil, title: nil }
        end

        badge = BadgeCatalog.find(key)
        if badge.nil? || badge.title.nil?
          return render json: { error: "その称号はありません。" }, status: :unprocessable_entity
        end
        unless student.student_badges.exists?(badge_key: key)
          return render json: { error: "まだ手に入れていない称号だよ。" }, status: :unprocessable_entity
        end

        student.update!(title_key: key)
        render json: { title_key: student.title_key, title: student.title }
      end
    end
  end
end
