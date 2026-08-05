class CreateDailyQuotas < ActiveRecord::Migration[8.0]
  def change
    # その日のノルマ（目標ポイント）を記録する。
    #
    # ノルマは goals（目標値・期限）と当時のステータス値から毎日計算しているが、
    # goals は上書き更新で履歴を持たないため、**あとから「その日のノルマ」を復元できない**。
    # 「ノルマを達成した日」の連続を数えるには、その日のうちに残しておくしかない。
    # （稼いだポイントの方は points_awarded が確定値なので再計算できる。だからここには持たない）
    create_table :daily_quotas do |t|
      t.references :student, null: false, foreign_key: true
      t.date :on_date, null: false
      t.integer :target_points, null: false

      t.timestamps
    end

    add_index :daily_quotas, [:student_id, :on_date], unique: true
  end
end
