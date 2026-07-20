module Api
  module V1
    module Admin
      class StudentsController < BaseController
        def index
          students = Student.order(created_at: :desc)
          # 学習状況の集計（正解数・最終学習日）をまとめて取得
          correct_counts = AnswerRecord.where(is_correct: true).group(:student_id).count
          last_dates = AnswerRecord.group(:student_id).maximum(:created_at)

          render json: students.map do |s|
            {
              id: s.id, name: s.name, username: s.username,
              admin: s.admin, onboarded: s.onboarded,
              created_at: s.created_at,
              correct_count: correct_counts[s.id] || 0,
              last_studied_on: last_dates[s.id]&.to_date
            }
          end
        end

        def show
          student = Student.find(params[:id])
          stats = StudentStat.where(student: student).includes(:stat_type)
          render json: {
            id: student.id, name: student.name, username: student.username,
            admin: student.admin, onboarded: student.onboarded, created_at: student.created_at,
            streak: student.study_streak,
            correct_count: student.answer_records.where(is_correct: true).count,
            total_answered: student.answer_records.count,
            stats: stats.map { |st| { name: st.stat_type.name, value: st.value } },
            test_count: student.test_results.count
          }
        end

        def destroy
          student = Student.find(params[:id])
          if student.admin?
            render json: { error: "管理者アカウントは削除できません。" }, status: :unprocessable_entity
          else
            student.destroy
            head :no_content
          end
        end
      end
    end
  end
end
