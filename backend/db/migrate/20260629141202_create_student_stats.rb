class CreateStudentStats < ActiveRecord::Migration[8.1]
  def change
    create_table :student_stats do |t|
      t.references :student, null: false, foreign_key: true
      t.references :stat_type, null: false, foreign_key: true
      t.integer :value

      t.timestamps
    end
  end
end
