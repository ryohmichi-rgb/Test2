module Api
  module V1
    class StudentsController < ApplicationController
      def create
        student = Student.new(student_params)
        if student.save
          render json: student, status: :created
        else
          render json: { errors: student.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def show
        student = Student.find(params[:id])
        render json: student
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

      private

      def student_params
        params.require(:student).permit(:name)
      end
    end
  end
end
