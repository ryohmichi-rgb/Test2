module Api
  module V1
    class QuotaController < ApplicationController
      include StudentScoped
      allow_guardian_read! :show

      # 今日のノルマと連続日数。
      # GET /api/v1/students/:id/quota
      def show
        student = Student.find(params[:id])
        today = Date.current

        # ノルマの計算そのものは DailyQuota に持たせている。
        # その日はじめて計算したときに決まり、以後その日は変わらない（達成判定の基準になるため）。
        # 保護者が見ただけでその日のノルマを決めてしまわないようにする。
        # まだ決まっていなければ「まだ今日は始まっていない」として 0 で見せる。
        quota = guardian_viewing? ? DailyQuota.find_by(student_id: student.id, on_date: today)
                                  : DailyQuota.for(student, today)
        quota ||= DailyQuota.new(target_points: 0)
        earned_points = points_earned_on(student, today)

        # 「いま満点で解ける問題」は解くたびに減るので、こちらは毎回その場で見る。
        # 決めたノルマと、やりきったかどうか（いまの状態）は別物。
        exhausted = DailyQuota.full_point_capacity(student).zero?

        render json: {
          target_points: quota.target_points,
          earned_points: earned_points,
          approx_problems: quota.approx_problems,
          studied_today: earned_points > 0 || answered_on?(student, today),
          streak: student.study_streak(today),
          # ノルマを達成した日の連続。学習日の連続とは別枠（Student#quota_streak 参照）
          quota_streak: student.quota_streak(today),
          has_goal: student.goals.exists?,
          # 満点で解ける問題が尽きた状態。フロントは「やりきった」表示に切り替える。
          exhausted: exhausted,
          returning_count: exhausted ? returning_soon(student) : 0
        }
      end

      private

      # 回答時に確定したポイントを合計するだけ（ルールは AnswerRecord 側に集約）
      def points_earned_on(student, date)
        student.answer_records.where(created_at: date.all_day).sum(:points_awarded)
      end

      # 明日以降に満点へ復帰する問題数（「あと○問もどってくるよ」の表示用）
      def returning_soon(student)
        threshold = AnswerRecord::RECOVERY_DAYS.days.ago
        student.answer_records
          .where(is_correct: true)
          .where(created_at: threshold..)
          .distinct
          .count(:problem_id)
      end

      def answered_on?(student, date)
        student.answer_records.where(created_at: date.all_day).exists?
      end
    end
  end
end
