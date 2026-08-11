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
          # 紐づけ（保護者→子ども）をまとめて引く。一覧に出すのは名前だけ。
          links = Guardianship.includes(:guardian, :student).to_a

          payload = students.map do |s|
            {
              id: s.id, name: s.name, username: s.username,
              role: s.role,
              admin: s.admin, onboarded: s.onboarded,
              created_at: s.created_at,
              correct_count: correct_counts[s.id] || 0,
              last_studied_on: last_dates[s.id]&.to_date,
              # 保護者なら見ている子ども、生徒なら見ている保護者
              children: links.select { |l| l.guardian_id == s.id }
                             .map { |l| { id: l.student_id, name: l.student.name } },
              guardians: links.select { |l| l.student_id == s.id }
                              .map { |l| { id: l.guardian_id, name: l.guardian.name } }
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

        # POST /api/v1/admin/students { name:, username:, role: }
        # 主に保護者アカウントを作るための入口（生徒は自分で新規登録できる）。
        # パスワードは生成して**この応答でだけ**返す（再発行と同じ扱い）。
        def create
          password = Student.generate_password
          student = Student.new(
            name: params[:name], username: params[:username],
            role: params[:role].presence || "parent", password: password
          )
          if student.save
            render json: { id: student.id, name: student.name, username: student.username,
                           role: student.role, password: password }, status: :created
          else
            render json: { error: student.errors.full_messages.join("、") }, status: :unprocessable_entity
          end
        end

        # POST /api/v1/admin/students/:id/guardianships { student_id: }
        # 保護者（:id）に子どもを紐づける。招待コードの仕組みは持たず、ここからだけ作る。
        def create_guardianship
          guardian = Student.find(params[:id])
          link = Guardianship.new(guardian: guardian, student_id: params[:student_id])
          if link.save
            render json: { id: link.student_id, name: link.student.name }, status: :created
          else
            render json: { error: link.errors.full_messages.join("、") }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/admin/students/:id/guardianships/:student_id
        def destroy_guardianship
          link = Guardianship.find_by!(guardian_id: params[:id], student_id: params[:student_id])
          link.destroy
          head :no_content
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
