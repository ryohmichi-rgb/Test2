class CreateGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :goals do |t|
      t.references :student, null: false, foreign_key: true
      t.references :stat_type, null: false, foreign_key: true
      t.integer :target_value
      t.date :target_date

      t.timestamps
    end
  end
end
