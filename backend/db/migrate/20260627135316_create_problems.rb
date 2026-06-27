class CreateProblems < ActiveRecord::Migration[8.1]
  def change
    create_table :problems do |t|
      t.references :unit, null: false, foreign_key: true
      t.text :question
      t.string :answer
      t.text :hint
      t.integer :difficulty
      t.string :problem_type

      t.timestamps
    end
  end
end
