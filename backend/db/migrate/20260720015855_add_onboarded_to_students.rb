class AddOnboardedToStudents < ActiveRecord::Migration[8.1]
  def change
    add_column :students, :onboarded, :boolean, default: false, null: false
  end
end
