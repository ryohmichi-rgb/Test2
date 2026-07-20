module Api
  module V1
    class ConditionController < ApplicationController
      include StudentScoped

      # ステータスの「さびつき」状態。earned値は変えず、表示のナッジに使う。
      # GET /api/v1/students/:id/condition
      def show
        student = Student.find(params[:id])
        render json: {
          rust_percent: student.rust_percent,
          idle_days: student.idle_days,
          last_studied_on: student.last_studied_on
        }
      end
    end
  end
end
