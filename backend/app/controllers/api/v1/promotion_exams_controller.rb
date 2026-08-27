module Api
  module V1
    # 昇格試験。到達（そのまとまりで積んだポイント）＋合格でランクが上がる。
    # ランクは「教科のまとまり」ごとにあるので、状況は配列で返す。
    class PromotionExamsController < ApplicationController
      include StudentScoped
      allow_guardian_read! :status

      # GET /api/v1/students/:id/rank — まとまりごとのランクと次までの状況（配列）
      def status
        student = find_student
        payload = SubjectGroup.active.map { |g| PromotionExam.new(student, g).status }
        render json: payload
      end

      # GET /api/v1/students/:id/promotion_exam — 試験の問題を取り出す
      def show
        exam = PromotionExam.new(find_student, find_group)
        problems = exam.problems
        render json: {
          subject_group: { id: exam.group.id, name: exam.group.name },
          rank: exam.status[:next_rank],
          pass_percent: exam.next_rank.pass_percent,
          scope_label: exam.scope.label,
          problems: serialize_problems(problems)
        }
      rescue PromotionExam::NotAvailable => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # POST /api/v1/students/:id/promotion_exam — 提出（採点＋昇格判定）
      # body: { answers: [{ problem_id, submitted_answer }] }
      def create
        student = find_student
        exam = PromotionExam.new(student, find_group)
        raise PromotionExam::NotAvailable, "いまは昇格試験に挑戦できません。" unless exam.available?

        # 通常のテストと同じく AnswerRecord 経由で採点する（加点の経路を分けない）。
        graded = params.require(:answers).map do |a|
          problem = Problem.find(a[:problem_id])
          record = AnswerRecord.create!(
            student: student,
            problem: problem,
            submitted_answer: AnswerRecord.normalize_submitted(a[:submitted_answer])
          )
          { problem_id: problem.id, is_correct: record.is_correct, correct_answer: problem.answer }
        end

        outcome = exam.finish!(graded)
        after = PromotionExam.new(student.reload, exam.group)

        render json: {
          passed: outcome[:passed],
          score_percent: outcome[:score_percent],
          correct_count: outcome[:correct_count],
          total_questions: outcome[:total_questions],
          answers: graded,
          status: after.status
        }, status: :created
      rescue PromotionExam::NotAvailable => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def find_student
        Student.find(params[:id])
      end

      # subject_group_id 未指定なら最初のまとまり（＝まとまりが1つしか無いうちは省略できる）
      def find_group
        group = params[:subject_group_id].presence && SubjectGroup.find_by(id: params[:subject_group_id])
        group || SubjectGroup.active.first or
          raise PromotionExam::NotAvailable, "ランクの対象になる教科がありません。"
      end
    end
  end
end
