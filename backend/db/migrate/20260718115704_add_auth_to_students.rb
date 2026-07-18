class AddAuthToStudents < ActiveRecord::Migration[8.1]
  def change
    add_column :students, :username, :string
    add_column :students, :password_digest, :string
    add_index :students, :username, unique: true
  end
end
