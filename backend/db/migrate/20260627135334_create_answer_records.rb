class CreateAnswerRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :answer_records do |t|
      t.references :student, null: false, foreign_key: true
      t.references :problem, null: false, foreign_key: true
      t.string :submitted_answer
      t.boolean :is_correct

      t.timestamps
    end
  end
end
