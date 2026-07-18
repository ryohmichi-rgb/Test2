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
        approx_problems = target_points > 0 ? [(target_points.to_f / EST_POINTS_PER_PROBLEM).ceil, 1].max : 0

        render json: {
          target_points: target_points,
          earned_points: earned_points,
          approx_problems: approx_problems,
          studied_today: earned_points > 0 || answered_on?(student, today),
          streak: streak(student, today),
          has_goal: has_goal
        }
      end

      private

      def points_earned_on(student, date)
        student.answer_records
          .where(is_correct: true, created_at: date.all_day)
          .includes(problem: :unit)
          .sum { |r| AnswerRecord::POINTS_BY_DIFFICULTY[r.problem.difficulty] || 10 }
      end

      def answered_on?(student, date)
        student.answer_records.where(created_at: date.all_day).exists?
      end

      # 学習した日の連続数（今日やっていれば今日から、まだなら昨日から数える）
      def streak(student, today)
        dates = student.answer_records.pluck(:created_at).map(&:to_date).uniq.to_set
        start = dates.include?(today) ? today : today - 1
        count = 0
        d = start
        while dates.include?(d)
          count += 1
          d -= 1
        end
        count
      end
    end
  end
end
