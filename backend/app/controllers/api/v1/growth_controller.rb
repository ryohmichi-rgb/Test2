module Api
  module V1
    class GrowthController < ApplicationController
      include StudentScoped
      allow_guardian_read! :show

      # 成長曲線。
      # - 実績: AnswerRecord から累積ポイントの時系列を再構築（過去→現在）
      # - 目標: 目標が設定されたステータスについて「現在→目標」を将来に向けて線形補間
      # GET /api/v1/students/:id/growth
      def show
        student = Student.find(params[:id])
        stat_types = StatType.all.to_a
        current = StudentStat.where(student: student).pluck(:stat_type_id, :value).to_h

        # ===== 実績（過去→現在） =====
        # ポイントの出どころは3系統ある。どれかを落とすと折れ線が実際より低くなり、
        # 最後の「現在」（＝student_stats）だけが跳ね上がってしまうので、すべて集める。
        #   1. 問題の正解 … answer_records.points_awarded（回答時に確定済み）
        #   2. テストの高得点ボーナス … test_results.bonus_points
        #   3. 教材の初回読了 … lesson_reads（1件 = LESSON_POINTS）
        daily = Hash.new { |h, k| h[k] = Hash.new(0) } # date => { stat_type_id => 加点 }

        student.answer_records
          .where(is_correct: true)
          .includes(problem: :unit)
          .find_each do |r|
            sid = r.problem.unit&.stat_type_id
            next unless sid
            daily[r.created_at.to_date][sid] += r.points_awarded.to_i
          end

        student.test_results.where("bonus_points > 0").find_each do |t|
          stat_ids = bonus_stat_type_ids(t)
          next if stat_ids.empty?
          per_stat = (t.bonus_points.to_f / stat_ids.size).round
          stat_ids.each { |sid| daily[t.created_at.to_date][sid] += per_stat }
        end

        student.lesson_reads.includes(:unit).find_each do |lr|
          sid = lr.unit&.stat_type_id
          next unless sid
          daily[lr.created_at.to_date][sid] += LessonRead::POINTS
        end

        cumulative = Hash.new(0)
        points = [] # [{ label:, per_stat: {id=>val} }]
        daily.keys.sort.each do |date|
          daily[date].each { |sid, pts| cumulative[sid] += pts }
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

      # テストのボーナスをどのステータスに配分したかを復元する。
      # 出題した問題そのものは保存していないので、テストの範囲が持つステータスから求める
      # （加点時の apply_bonus と同じ「範囲内のステータスへ均等配分」の考え方）。
      def bonus_stat_type_ids(test_result)
        ProblemScope
          .new(scope_type: test_result.scope_type, scope_id: test_result.scope_id, subject_id: test_result.subject_id)
          .units.pluck(:stat_type_id).compact.uniq
      end

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
