module Api
  module V1
    class GoalsController < ApplicationController
      def upsert
        student = Student.find(params[:id])
        goal = Goal.find_or_initialize_by(student: student, stat_type_id: goal_params[:stat_type_id])
        goal.assign_attributes(goal_params)

        if goal.save
          render json: goal, status: :ok
        else
          render json: { errors: goal.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def goal_params
        params.require(:goal).permit(:stat_type_id, :target_value, :target_date)
      end
    end
  end
end
