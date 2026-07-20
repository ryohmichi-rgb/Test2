module Api
  module V1
    class PlanController < ApplicationController
      include StudentScoped

      ESTIMATED_POINTS_PER_UNIT = 40
      MAX_UNITS_PER_STAT = 3

      def show
        student = Student.find(params[:id])
        today = Date.today

        goals = student.goals.includes(:stat_type)
        stat_map = StudentStat.where(student: student).index_by(&:stat_type_id)

        goals_summary = build_goals_summary(goals, stat_map, today)
        today_plan = build_today_plan(student, goals_summary)

        render json: { goals_summary: goals_summary, today_plan: today_plan }
      end

      private

      def build_goals_summary(goals, stat_map, today)
        goals.map do |goal|
          current = stat_map[goal.stat_type_id]&.value || 0
          days_remaining = [(goal.target_date - today).to_i, 1].max
          points_needed = [goal.target_value - current, 0].max
          points_per_day = points_needed.to_f / days_remaining

          {
            stat_type_id: goal.stat_type_id,
            stat_name: goal.stat_type.name,
            current: current,
            target: goal.target_value,
            target_date: goal.target_date,
            days_remaining: days_remaining,
            points_needed: points_needed,
            points_per_day: points_per_day.round(1),
            achieved: points_needed == 0
          }
        end.sort_by { |g| -g[:points_per_day] }
      end

      def build_today_plan(student, goals_summary)
        plan = []
        read_unit_ids = student.lesson_reads.pluck(:unit_id).to_set

        goals_summary.each do |goal|
          next if goal[:achieved]

          units = Unit.where(stat_type_id: goal[:stat_type_id]).includes(:problems)
          scored_units = score_units(student, units, goal, read_unit_ids)

          units_needed = [[(goal[:points_per_day] / ESTIMATED_POINTS_PER_UNIT).ceil, 1].max, MAX_UNITS_PER_STAT].min

          scored_units.first(units_needed).each do |rec|
            plan << rec.merge(priority: plan.size + 1)
          end
        end

        plan
      end

      def score_units(student, units, goal, read_unit_ids)
        units.map do |unit|
          next if unit.problems.empty?

          problem_ids = unit.problem_ids
          records = AnswerRecord.where(student: student, problem_id: problem_ids)
          total = records.count
          correct = records.where(is_correct: true).count
          accuracy = total > 0 ? (correct.to_f / total) : nil

          avg_difficulty = unit.problems.average(:difficulty).to_f
          estimated_points = (avg_difficulty * 10 * 0.7 * unit.problems.count).round

          {
            unit_id: unit.id,
            unit_title: unit.title,
            stat_name: goal[:stat_name],
            stat_type_id: goal[:stat_type_id],
            accuracy: accuracy&.round(2),
            total_answered: total,
            estimated_points: estimated_points,
            is_new: total == 0,
            lesson_read: read_unit_ids.include?(unit.id)
          }
        # 未読の解説を先に（学ぶ→やる）、次に正答率が低い順
        end.compact.sort_by { |u| [u[:lesson_read] ? 1 : 0, u[:accuracy].nil? ? -1 : u[:accuracy]] }
      end
    end
  end
end
