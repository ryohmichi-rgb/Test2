class AddRoleAndGuardianships < ActiveRecord::Migration[8.0]
  def change
    # アカウントの種類。既存はすべて生徒なので既定値でそのまま通る。
    # admin フラグとは直交（「どんな種類の人か」と「コンテンツを管理できるか」は別）。
    add_column :students, :role, :string, null: false, default: "student"
    add_index :students, :role

    # 保護者と子どもの紐づけ。父と母の2人が同じ子を見る、きょうだいを1人が見る、
    # どちらも起きるので N:N にする。
    create_table :guardianships do |t|
      t.references :guardian, null: false, foreign_key: { to_table: :students }
      t.references :student, null: false, foreign_key: true

      t.timestamps
    end
    add_index :guardianships, [:guardian_id, :student_id], unique: true
  end
end
