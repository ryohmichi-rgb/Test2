module Api
  module V1
    module Admin
      class StudentsController < BaseController
        def index
          students = Student.order(created_at: :desc)
          # 学習状況の集計（正解数・最終学習日）をまとめて取得
          correct_counts = AnswerRecord.where(is_correct: true).group(:student_id).count
          last_dates = AnswerRecord.group(:student_id).maximum(:created_at)

          # 注意: `render json: students.map do |s| ... end` と書くと do...end が map ではなく
          # render に結合し、整形されていない生のレコード（password_digest を含む）が
          # そのまま返ってしまう。必ず変数に受けてから render すること。
          payload = students.map do |s|
            {
              id: s.id, name: s.name, username: s.username,
              admin: s.admin, onboarded: s.onboarded,
              created_at: s.created_at,
              correct_count: correct_counts[s.id] || 0,
              last_studied_on: last_dates[s.id]&.to_date
            }
          end

          render json: payload
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

        # POST /api/v1/admin/students/:id/reset_password
        # パスワードを忘れた生徒の救済。新しいパスワードを生成して**この応答でだけ**返す
        # （保存はハッシュのみなので、あとから取り出すことはできない）。
        # パスワードが変わると認証トークンも失効するので、その生徒は自動的にログアウトされる。
        def reset_password
          student = Student.find(params[:id])
          new_password = Student.generate_password
          student.update!(password: new_password)
          render json: { password: new_password }
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
