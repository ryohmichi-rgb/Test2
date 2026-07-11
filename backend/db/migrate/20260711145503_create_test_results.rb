class CreateTestResults < ActiveRecord::Migration[8.1]
  def change
    create_table :test_results do |t|
      t.references :student, null: false, foreign_key: true
      t.string :scope_type
      t.integer :scope_id
      t.string :scope_label
      t.integer :total_questions
      t.integer :correct_count
      t.integer :score_percent

      t.timestamps
    end

    add_index :test_results, [:student_id, :scope_type, :created_at]
  end
end
