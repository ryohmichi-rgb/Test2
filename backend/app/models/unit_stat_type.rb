# 単元がどのステータスを伸ばすか（1単元に複数）。
class UnitStatType < ApplicationRecord
  belongs_to :unit
  belongs_to :stat_type

  validates :stat_type_id, uniqueness: { scope: :unit_id }
end
