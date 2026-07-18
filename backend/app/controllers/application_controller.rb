class ApplicationController < ActionController::API
  before_action :authenticate_request

  attr_reader :current_student

  # フロントが期待する形で問題を整形（units#show と同じ形）
  def serialize_problems(problems)
    problems.as_json(
      only: [:id, :question, :hint, :difficulty, :problem_type],
      include: { choices: { only: [:id, :text] } }
    )
  end

  private

  # Authorization: Bearer <token> から現在のログインユーザーを特定する
  def authenticate_request
    token = request.headers["Authorization"]&.split(" ")&.last
    @current_student = token && Student.find_by_token_for(:auth, token)
    render json: { error: "認証が必要です" }, status: :unauthorized unless @current_student
  end
end
