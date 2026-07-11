class ApplicationController < ActionController::API
  # フロントが期待する形で問題を整形（units#show と同じ形）
  def serialize_problems(problems)
    problems.as_json(
      only: [:id, :question, :hint, :difficulty, :problem_type],
      include: { choices: { only: [:id, :text] } }
    )
  end
end
