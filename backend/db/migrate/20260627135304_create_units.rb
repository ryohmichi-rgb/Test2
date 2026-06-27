class CreateUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :units do |t|
      t.string :title
      t.text :description
      t.references :grade, null: false, foreign_key: true
      t.references :subject, null: false, foreign_key: true
      t.integer :display_order

      t.timestamps
    end
  end
end
