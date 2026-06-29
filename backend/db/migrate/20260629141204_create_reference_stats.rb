class CreateReferenceStats < ActiveRecord::Migration[8.1]
  def change
    create_table :reference_stats do |t|
      t.string :label
      t.references :stat_type, null: false, foreign_key: true
      t.integer :value

      t.timestamps
    end
  end
end
