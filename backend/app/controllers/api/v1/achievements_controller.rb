module Api
  module V1
    class AchievementsController < ApplicationController
      include StudentScoped

      # 実績バッジ。獲得済みかどうかのフラグつきで返す。
      # GET /api/v1/students/:id/achievements
      def index
        student = Student.find(params[:id])

        total_correct = student.answer_records.where(is_correct: true).count
        streak = student.study_streak
        best_test = student.test_results.maximum(:score_percent) || 0
        lessons_read = student.lesson_reads.count

        badges = [
          { key: "first_step",     label: "はじめの一歩", emoji: "🌱", earned: total_correct >= 1 },
          { key: "ten_problems",   label: "10問クリア",   emoji: "✏️", earned: total_correct >= 10 },
          { key: "fifty_problems", label: "50問クリア",   emoji: "📚", earned: total_correct >= 50 },
          { key: "streak3",        label: "3日れんぞく",  emoji: "🔥", earned: streak >= 3 },
          { key: "streak7",        label: "1週間れんぞく", emoji: "⭐", earned: streak >= 7 },
          { key: "perfect_test",   label: "テスト満点",   emoji: "💯", earned: best_test >= 100 },
          { key: "scholar",        label: "学びの人",     emoji: "🎓", earned: lessons_read >= 3 }
        ]

        render json: { badges: badges }
      end
    end
  end
end
