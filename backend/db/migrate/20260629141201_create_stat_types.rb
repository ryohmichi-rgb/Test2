class CreateStatTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :stat_types do |t|
      t.string :name
      t.text :description
      t.integer :display_order

      t.timestamps
    end
  end
end
