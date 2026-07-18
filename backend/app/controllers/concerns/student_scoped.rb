# /students/:id/* のエンドポイントを「ログイン中の本人のみ」に制限する。
module StudentScoped
  extend ActiveSupport::Concern

  included do
    before_action :authorize_student!
  end

  private

  def authorize_student!
    head :forbidden unless current_student&.id == params[:id].to_i
  end
end
