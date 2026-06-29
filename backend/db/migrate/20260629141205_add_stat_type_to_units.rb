class AddStatTypeToUnits < ActiveRecord::Migration[8.1]
  def change
    add_reference :units, :stat_type, null: true, foreign_key: true
  end
end
