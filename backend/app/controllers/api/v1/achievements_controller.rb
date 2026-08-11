module Api
  module V1
    class AchievementsController < ApplicationController
      include StudentScoped
      allow_guardian_read! :index

      # 実績バッジ。獲得済みかどうかと、獲得した日時を返す。
      # 判定は毎回やり直すが、**獲得した事実は StudentBadge に残す**。
      # そうしないと「今まさに取った」瞬間を検出できず、お祝いが出せない。
      # GET /api/v1/students/:id/achievements
      def index
        student = Student.find(params[:id])
        earned_now = BadgeCatalog.earned_keys_for(student)
        already = student.student_badges.pluck(:badge_key, :earned_at).to_h

        # 保護者が見たときは獲得を確定させない。ここで保存してしまうと、
        # 子どもが自分で開いたときに「新しいバッジ！」が出なくなる（お祝いを横取りしてしまう）。
        newly = guardian_viewing? ? [] : (earned_now - already.keys).to_a
        newly.each do |key|
          record = student.student_badges.create!(badge_key: key, earned_at: Time.current)
          already[key] = record.earned_at
        rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
          # 同時アクセスで先に入っていた場合。獲得済みなので拾い直すだけ。
          already[key] = student.student_badges.find_by(badge_key: key)&.earned_at
        end

        payload = BadgeCatalog::ALL.map do |b|
          {
            key: b.key, label: b.label, emoji: b.emoji, hint: b.hint, title: b.title,
            earned: already.key?(b.key),
            earned_at: already[b.key]
          }
        end

        render json: {
          badges: payload,
          newly_earned: newly,
          title_key: student.title_key,
          title: student.title,
          # 称号の選択肢（称号を持つバッジだけ。未獲得のものも「あと何をすれば」を見せる）
          titles: BadgeCatalog.with_title.map do |b|
            { key: b.key, title: b.title, label: b.label, emoji: b.emoji,
              hint: b.hint, earned: already.key?(b.key) }
          end
        }
      end
    end
  end
end
