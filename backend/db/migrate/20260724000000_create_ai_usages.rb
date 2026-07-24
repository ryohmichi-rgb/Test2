class CreateAiUsages < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_usages do |t|
      t.references :student, null: false, foreign_key: true
      t.references :problem, foreign_key: true # 文脈にした問題（削除されても残せるよう任意）
      t.string :kind, null: false, default: "hint" # hint / approach / why / free
      t.timestamps
    end

    # 「その生徒の今日の利用回数」を高速に数えるための索引
    add_index :ai_usages, [:student_id, :created_at]
  end
end
