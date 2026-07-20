module Api
  module V1
    class StudentsController < ApplicationController
      include StudentScoped

      def show
        student = Student.find(params[:id])
        render json: { id: student.id, name: student.name, username: student.username, onboarded: student.onboarded }
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

        render json: { student: student, progress: progress_data }
      end
    end
  end
end
