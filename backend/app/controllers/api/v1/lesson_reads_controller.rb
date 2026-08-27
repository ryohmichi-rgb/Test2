module Api
  module V1
    class LessonReadsController < ApplicationController
      include StudentScoped

      LESSON_POINTS = LessonRead::POINTS

      # GET /api/v1/students/:id/lesson_reads → 既読の unit_id 一覧
      def index
        student = Student.find(params[:id])
        render json: { unit_ids: student.lesson_reads.pluck(:unit_id) }
      end

      # POST /api/v1/students/:id/lesson_reads { unit_id }
      # 初回読了なら単元のステータスへ +5pt（1回きり）
      def create
        student = Student.find(params[:id])
        unit = Unit.find(params[:unit_id])
        read = LessonRead.find_or_initialize_by(student: student, unit: unit)

        if read.persisted?
          return render json: { awarded: false, points: 0 }
        end

        read.save!
        points = award_points(student, unit)
        render json: { awarded: true, points: points }, status: :created
      end

      private

      # 単元が複数のステータスを伸ばすなら均等に分ける（合計は LESSON_POINTS のまま）
      def award_points(student, unit)
        shares = StatPoints.split(LESSON_POINTS, unit.stat_type_ids)
        return 0 if shares.empty?

        shares.each do |stat_type_id, pts|
          stat = StudentStat.find_or_initialize_by(student: student, stat_type_id: stat_type_id)
          stat.value = (stat.value || 0) + pts
          stat.save!
        end
        LESSON_POINTS
      end
    end
  end
end
