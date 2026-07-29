class CreateRanks < ActiveRecord::Migration[8.0]
  def change
    create_table :ranks do |t|
      t.string :name, null: false                       # 10級 / 1級 / 初段
      t.integer :threshold_points, null: false          # このランクに到達するのに要る合計ポイント
      t.integer :exam_question_count, null: false, default: 10  # 昇格試験の問題数
      t.integer :pass_percent, null: false, default: 80          # 合格ライン(%)
      t.integer :display_order, null: false

      t.timestamps
    end

    add_index :ranks, :display_order, unique: true
  end
end
