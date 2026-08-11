class AddCharacterKeyToAiUsages < ActiveRecord::Migration[8.0]
  def change
    # どのキャラに聞いたか。「先生に聞く」は nil のまま。
    # 回数の枠を分けるために持つ（先生20回／ペルソナ5回）。
    # 質問文と返答は保存しない（子どもの書いたものを残さない方針）。
    add_column :ai_usages, :character_key, :string
    add_index :ai_usages, [:student_id, :character_key, :created_at],
              name: "index_ai_usages_on_student_character_created"
  end
end
