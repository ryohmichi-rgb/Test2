class AddSolutionToProblems < ActiveRecord::Migration[8.0]
  def change
    # 間違えたときに出す「解き方」。hint（解く前のヒント）とは別物で、
    # hint は答えに近づけるための一言、solution は解き終わったあとに読む手順。
    add_column :problems, :solution, :text
  end
end
