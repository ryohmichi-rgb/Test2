module Api
  module V1
    class StatsController < ApplicationController
      def index
        student = Student.find(params[:id])
        stats = StudentStat.where(student: student).includes(:stat_type)
        stat_map = stats.index_by(&:stat_type_id)

        result = StatType.all.map do |st|
          current = stat_map[st.id]&.value || 0
          goal = student.goals.find_by(stat_type: st)
          {
            stat_type_id: st.id,
            name: st.name,
            description: st.description,
            display_order: st.display_order,
            value: current,
            goal: goal ? { target_value: goal.target_value, target_date: goal.target_date } : nil
          }
        end

        render json: result
      end
    end
  end
end
