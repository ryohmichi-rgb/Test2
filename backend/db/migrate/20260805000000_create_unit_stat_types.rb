# 1単元が複数のステータスを伸ばせるようにする（文章題＝文章読解力＋計算力 など）。
# 既存の units.stat_type_id は 1単元1ステータスしか表せなかった。
#
# units.stat_type_id は**この移行では消さない**。デプロイ中は旧コードが新スキーマに
# 対して動く窓があり、列を消すと `units.*` を読む旧インスタンスがその間だけ落ちるため。
# 参照はすべて unit_stat_types に移し、列の削除は後日おこなう（TODO に記載）。
class CreateUnitStatTypes < ActiveRecord::Migration[8.0]
  def up
    create_table :unit_stat_types do |t|
      t.references :unit, null: false, foreign_key: true
      t.references :stat_type, null: false, foreign_key: true
      t.timestamps
    end
    add_index :unit_stat_types, [:unit_id, :stat_type_id], unique: true

    # 既存データの移行。いまは1単元1ステータスなので、そのまま1行ずつ入れる。
    execute <<~SQL
      INSERT INTO unit_stat_types (unit_id, stat_type_id, created_at, updated_at)
      SELECT id, stat_type_id, NOW(), NOW() FROM units WHERE stat_type_id IS NOT NULL
    SQL
  end

  def down
    drop_table :unit_stat_types
  end
end
