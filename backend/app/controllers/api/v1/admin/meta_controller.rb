module Api
  module V1
    module Admin
      # フォームのプルダウン用（学年・教科・ステータス種別）
      class MetaController < BaseController
        def show
          render json: {
            grades: Grade.ordered.as_json(only: [:id, :name]),
            subjects: Subject.all.as_json(only: [:id, :name]),
            stat_types: StatType.all.as_json(only: [:id, :name])
          }
        end
      end
    end
  end
end
