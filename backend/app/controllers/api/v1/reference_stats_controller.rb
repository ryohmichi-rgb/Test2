module Api
  module V1
    class ReferenceStatsController < ApplicationController
      def index
        refs = ReferenceStat.includes(:stat_type).all
        result = refs.group_by(&:label).map do |label, items|
          {
            label: label,
            stats: items.map { |r| { stat_type_id: r.stat_type_id, name: r.stat_type.name, value: r.value } }
          }
        end
        render json: result
      end
    end
  end
end
