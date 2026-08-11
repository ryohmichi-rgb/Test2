# /students/:id/* のエンドポイントを「ログイン中の本人のみ」に制限する。
#
# 保護者アカウントは、紐づいた子どもの分だけ**読み取りに限って**通す。
# 見る専用ロールなので、書き込み（回答・目標設定・パスワード変更・先生に聞く など）は本人のみ。
#
# 開くのは **アクション単位**（`allow_guardian_read! :index`）。コントローラ単位だと
# 開けすぎる（例: 昇格試験は「ランク状況」と「試験問題の取得」が同じコントローラにある）。
# **既定は本人のみ**なので、新しいエンドポイントを足してもうっかり保護者へ開くことはない。
module StudentScoped
  extend ActiveSupport::Concern

  included do
    before_action :authorize_student!
    class_attribute :guardian_readable_actions, instance_writer: false, default: [].freeze
  end

  class_methods do
    def allow_guardian_read!(*actions)
      self.guardian_readable_actions = actions.map(&:to_s).freeze
    end
  end

  private

  def authorize_student!
    return if current_student&.id == params[:id].to_i
    return if guardian_viewing?

    head :forbidden
  end

  # いま保護者が子どもの画面を見ているか。
  # 表示内容を変える必要があるところ（副作用を伴う画面など）でも使う。
  def guardian_viewing?
    return false unless request.get?
    return false unless self.class.guardian_readable_actions.include?(action_name)

    current_student&.guardian_of?(params[:id])
  end
end
