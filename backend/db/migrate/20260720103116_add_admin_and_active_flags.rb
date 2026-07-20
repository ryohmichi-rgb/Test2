class AddAdminAndActiveFlags < ActiveRecord::Migration[8.1]
  def change
    add_column :students, :admin, :boolean, default: false, null: false
    add_column :problems, :active, :boolean, default: true, null: false
    add_column :units, :active, :boolean, default: true, null: false
  end
end
