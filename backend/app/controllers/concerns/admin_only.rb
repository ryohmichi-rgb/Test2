# 管理者（students.admin）だけがアクセスできるエンドポイント用。
module AdminOnly
  extend ActiveSupport::Concern

  included do
    before_action :require_admin!
  end

  private

  def require_admin!
    head :forbidden unless current_student&.admin?
  end
end
