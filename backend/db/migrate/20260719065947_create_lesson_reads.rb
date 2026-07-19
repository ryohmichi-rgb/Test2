class CreateLessonReads < ActiveRecord::Migration[8.1]
  def change
    create_table :lesson_reads do |t|
      t.references :student, null: false, foreign_key: true
      t.references :unit, null: false, foreign_key: true

      t.timestamps
    end

    add_index :lesson_reads, [:student_id, :unit_id], unique: true
  end
end
