module Api
  module V1
    class LessonReadsController < ApplicationController
      include StudentScoped

      LESSON_POINTS = 5

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

      def award_points(student, unit)
        stat_type_id = unit.stat_type_id
        return 0 unless stat_type_id

        stat = StudentStat.find_or_initialize_by(student: student, stat_type_id: stat_type_id)
        stat.value = (stat.value || 0) + LESSON_POINTS
        stat.save!
        LESSON_POINTS
      end
    end
  end
end
