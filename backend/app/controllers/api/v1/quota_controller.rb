module Api
  module V1
    class QuotaController < ApplicationController
      include StudentScoped

      DEFAULT_TARGET = 30            # 目標未設定時のゆるいノルマ
      EST_POINTS_PER_PROBLEM = 15    # 目安の問題数を出すための概算

      # 今日のノルマと連続学習日数。
      # GET /api/v1/students/:id/quota
      def show
        student = Student.find(params[:id])
        today = Date.current

        # 目標ペースから1日あたり必要ポイント（残り日数で均等割り）
        goals = student.goals.includes(:stat_type)
        current = StudentStat.where(student: student).pluck(:stat_type_id, :value).to_h
        has_goal = goals.any?

        target_points =
          if has_goal
            goals.sum do |g|
              needed = [g.target_value - (current[g.stat_type_id] || 0), 0].max
              days = [(g.target_date - today).to_i, 1].max
              (needed.to_f / days).ceil
            end
          else
            DEFAULT_TARGET
          end

        earned_points = points_earned_on(student, today)

        # 今「満点」で解ける問題の合計。全部解き終わった直後は 0 になりうる。
        # 達成できないノルマを出し続けないよう、ここで上限を切る。
        capacity = full_point_capacity(student)
        target_points = [target_points, capacity].min
        exhausted = capacity.zero?

        approx_problems = target_points > 0 ? [(target_points.to_f / EST_POINTS_PER_PROBLEM).ceil, 1].max : 0

        render json: {
          target_points: target_points,
          earned_points: earned_points,
          approx_problems: approx_problems,
          studied_today: earned_points > 0 || answered_on?(student, today),
          streak: student.study_streak(today),
          has_goal: has_goal,
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

      # 未挑戦・要復習・回復済みの問題を満点換算した合計
      def full_point_capacity(student)
        ProblemScope.all_problems
          .full_point_problems_for(student)
          .sum { |p| AnswerRecord.full_points_for(p.difficulty) }
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
