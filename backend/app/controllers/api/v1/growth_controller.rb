module Api
  module V1
    class GrowthController < ApplicationController
      # 成長曲線。AnswerRecord から累積ポイントの時系列を再構築する（新テーブル不要）。
      # GET /api/v1/students/:id/growth
      def show
        student = Student.find(params[:id])

        records = student.answer_records
          .where(is_correct: true)
          .includes(problem: { unit: :stat_type })
          .order(:created_at)

        stat_types = StatType.all.to_a
        cumulative = Hash.new(0)   # stat_type_id => 累積
        points = []                # [{ label:, total:, per_stat: {stat_type_id => val} }]

        records.group_by { |r| r.created_at.to_date }.each do |date, day_records|
          day_records.each do |r|
            stat_type_id = r.problem.unit&.stat_type_id
            next unless stat_type_id
            cumulative[stat_type_id] += AnswerRecord::POINTS_BY_DIFFICULTY[r.problem.difficulty] || 10
          end
          points << {
            label: format_date(date),
            total: cumulative.values.sum,
            per_stat: cumulative.dup
          }
        end

        # 最新点は実際の現在値（ボーナス込み）に合わせる
        current = StudentStat.where(student: student).pluck(:stat_type_id, :value).to_h
        points << {
          label: "現在",
          total: current.values.sum,
          per_stat: current
        }

        render json: {
          total: points.map { |p| { label: p[:label], value: p[:total] } },
          by_stat: stat_types.map do |st|
            {
              stat_name: st.name,
              series: points.map { |p| { label: p[:label], value: p[:per_stat][st.id] || 0 } }
            }
          end
        }
      end

      private

      def format_date(date)
        "#{date.month}/#{date.day}"
      end
    end
  end
end
