module Api
  module V1
    class GrowthController < ApplicationController
      include StudentScoped

      # 成長曲線。
      # - 実績: AnswerRecord から累積ポイントの時系列を再構築（過去→現在）
      # - 目標: 目標が設定されたステータスについて「現在→目標」を将来に向けて線形補間
      # GET /api/v1/students/:id/growth
      def show
        student = Student.find(params[:id])
        stat_types = StatType.all.to_a
        current = StudentStat.where(student: student).pluck(:stat_type_id, :value).to_h

        # ===== 実績（過去→現在） =====
        records = student.answer_records
          .where(is_correct: true)
          .includes(problem: { unit: :stat_type })
          .order(:created_at)

        cumulative = Hash.new(0)
        points = [] # [{ label:, per_stat: {id=>val} }]
        records.group_by { |r| r.created_at.to_date }.each do |date, day_records|
          day_records.each do |r|
            sid = r.problem.unit&.stat_type_id
            next unless sid
            cumulative[sid] += AnswerRecord::POINTS_BY_DIFFICULTY[r.problem.difficulty] || 10
          end
          points << { label: fmt(date), per_stat: cumulative.dup }
        end
        points << { label: "現在", per_stat: current }

        labels_actual = points.map { |p| p[:label] }

        # ===== 目標（現在→将来） =====
        today = Date.current
        goals = student.goals.index_by(&:stat_type_id)
        milestone_dates = goals.values.map(&:target_date).select { |d| d > today }.uniq.sort
        labels_target = milestone_dates.map { |d| fmt(d) }

        render json: {
          labels_actual: labels_actual,
          labels_target: labels_target,
          total: {
            actual: points.map { |p| p[:per_stat].values.sum },
            target: milestone_dates.map { |d| stat_types.sum { |st| expected(st.id, d, current, goals, today) } }
          },
          by_stat: stat_types.map do |st|
            has_goal = goals[st.id].present? && goals[st.id].target_date > today
            {
              stat_name: st.name,
              actual: points.map { |p| p[:per_stat][st.id] || 0 },
              target: has_goal ? milestone_dates.map { |d| expected(st.id, d, current, goals, today) } : []
            }
          end
        }
      end

      private

      # 日付 d におけるステータス st の期待値（線形補間、目標日以降は目標値、目標なしは現状維持）
      def expected(stat_type_id, date, current, goals, today)
        cur = current[stat_type_id] || 0
        goal = goals[stat_type_id]
        return cur unless goal && goal.target_date > today

        total_days = (goal.target_date - today).to_i
        elapsed = (date - today).to_i
        return goal.target_value if elapsed >= total_days
        (cur + (goal.target_value - cur) * (elapsed.to_f / total_days)).round
      end

      def fmt(date)
        "#{date.month}/#{date.day}"
      end
    end
  end
end
