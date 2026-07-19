class AddLessonBodyToUnits < ActiveRecord::Migration[8.1]
  def change
    add_column :units, :lesson_body, :text
  end
end
