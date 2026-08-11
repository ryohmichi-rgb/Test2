module Api
  module V1
    class StudentsController < ApplicationController
      include StudentScoped
      allow_guardian_read! :show

      def show
        student = Student.find(params[:id])
        render json: {
          id: student.id, name: student.name, username: student.username,
          role: student.role, onboarded: student.onboarded,
          # 自分を見ている保護者。黙って見られている状態にしないため、本人にも見えるようにする。
          guardians: student.guardians.order(:name).map { |g| { id: g.id, name: g.name } }
        }
      end

      # オンボーディング完了（またはスキップ）
      def complete_onboarding
        student = Student.find(params[:id])
        student.update!(onboarded: true)
        head :no_content
      end

      def progress
        student = Student.find(params[:id])
        units = Unit.includes(:problems, :grade, :subject).ordered

        progress_data = units.map do |unit|
          prog = student.progress_for(unit)
          {
            unit_id: unit.id,
            unit_title: unit.title,
            grade: unit.grade.name,
            subject: unit.subject.name,
            total_problems: unit.problems.count,
            answered: prog[:total],
            correct: prog[:correct],
            accuracy: prog[:accuracy]
          }
        end

        # student をそのまま渡すと password_digest まで JSON に出てしまう。
        # 必要な項目だけ選んで返すこと。
        render json: {
          student: { id: student.id, name: student.name, username: student.username },
          progress: progress_data
        }
      end
    end
  end
end
