module Api
  module V1
    class TestResultsController < ApplicationController
      BONUS_HIGH = 100  # 90%以上
      BONUS_MID  = 50   # 80〜89%

      # GET /api/v1/students/:id/test_results  — 履歴
      def index
        student = Student.find(params[:id])
        results = student.test_results.recent_first.limit(50)
        render json: results.map { |r| serialize_result(r) }
      end

      # POST /api/v1/students/:id/test_results — テスト提出（一括採点）
      # body: { scope_type, scope_id, answers: [{ problem_id, submitted_answer }] }
      def create
        student = Student.find(params[:id])
        answers = params.require(:answers)

        graded = grade_answers(student, answers)
        total = graded.size
        correct = graded.count { |g| g[:is_correct] }
        score = total > 0 ? (correct.to_f / total * 100).round : 0

        scope = ProblemScope.new(scope_type: params[:scope_type], scope_id: params[:scope_id])

        # 自己ベスト判定（この結果を保存する前の最高点と比較）
        best_before = student.test_results
          .where(scope_type: params[:scope_type], scope_id: params[:scope_id].presence)
          .maximum(:score_percent)
        is_best = best_before.nil? || score > best_before

        # ボーナスは自己ベスト更新時のみ（farming 防止）
        bonus = is_best ? apply_bonus(student, graded, score) : 0

        result = student.test_results.create!(
          scope_type: params[:scope_type],
          scope_id: params[:scope_id].presence,
          scope_label: scope.label,
          total_questions: total,
          correct_count: correct,
          score_percent: score
        )

        render json: serialize_result(result).merge(
          bonus_points: bonus,
          is_best: is_best,
          previous_score: result.previous&.score_percent,
          answers: graded.map { |g| g.slice(:problem_id, :is_correct, :correct_answer) }
        ), status: :created
      end

      private

      # 各回答を採点し、AnswerRecord を作成（=通常ポイントが自動加算される）
      def grade_answers(student, answers)
        answers.map do |a|
          problem = Problem.find(a[:problem_id])
          record = AnswerRecord.create!(
            student: student,
            problem: problem,
            submitted_answer: a[:submitted_answer].to_s
          )
          {
            problem_id: problem.id,
            is_correct: record.is_correct,
            correct_answer: problem.answer,
            problem: problem
          }
        end
      end

      # 高得点ボーナス。テストに出たステータスへ均等配分。
      def apply_bonus(student, graded, score)
        bonus = if score >= 90 then BONUS_HIGH
                elsif score >= 80 then BONUS_MID
                else 0
                end
        return 0 if bonus.zero?

        stat_type_ids = graded.map { |g| g[:problem].unit.stat_type_id }.compact.uniq
        return 0 if stat_type_ids.empty?

        per_stat = (bonus.to_f / stat_type_ids.size).round
        stat_type_ids.each do |stat_type_id|
          stat = StudentStat.find_or_initialize_by(student: student, stat_type_id: stat_type_id)
          stat.value = (stat.value || 0) + per_stat
          stat.save!
        end
        bonus
      end

      def serialize_result(r)
        {
          id: r.id,
          scope_type: r.scope_type,
          scope_id: r.scope_id,
          scope_label: r.scope_label,
          total_questions: r.total_questions,
          correct_count: r.correct_count,
          score_percent: r.score_percent,
          rank: r.rank,
          created_at: r.created_at
        }
      end
    end
  end
end
