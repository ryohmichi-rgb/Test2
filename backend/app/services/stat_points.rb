# 1回の加点を、その単元が伸ばすステータスへ分ける。
#
# 合計は**必ず元のポイントと一致させる**。total_points（= student_stats の合計）が
# 総合ランクの判定軸なので、ここで増減するとランク・ノルマ・目標の意味がずれる
# （ステータスを2つ付けた単元だけ2倍おいしい、という抜け道にもなる）。
#
# 端数は先頭（stat_types.display_order 順）から1ptずつ配る。並びが決まっているので
# 何度計算しても同じ結果になる＝成長曲線の再構築が現在値とずれない。
module StatPoints
  # stat_type_ids => 配分後の { stat_type_id => points }。0ptになるステータスは含めない。
  def self.split(points, stat_type_ids)
    points = points.to_i
    ids = ordered(stat_type_ids)
    return {} if points <= 0 || ids.empty?

    base, remainder = points.divmod(ids.size)
    ids.each_with_index.each_with_object({}) do |(id, i), acc|
      share = base + (i < remainder ? 1 : 0)
      acc[id] = share if share > 0
    end
  end

  # 表示順に並べたステータスID（重複は除く）
  def self.ordered(stat_type_ids)
    ids = Array(stat_type_ids).compact.uniq
    return [] if ids.empty?
    StatType.where(id: ids).order(:display_order, :id).pluck(:id)
  end
end
