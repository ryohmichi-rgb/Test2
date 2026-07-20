module Api
  module V1
    module Admin
      class ReferenceStatsController < BaseController
        def index
          refs = ReferenceStat.includes(:stat_type).order(:label, :stat_type_id)
          render json: refs.map { |r| ref_json(r) }
        end

        def create
          ref = ReferenceStat.new(ref_params)
          if ref.save
            render json: ref_json(ref), status: :created
          else
            render json: { errors: ref.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          ref = ReferenceStat.find(params[:id])
          if ref.update(ref_params)
            render json: ref_json(ref)
          else
            render json: { errors: ref.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          ReferenceStat.find(params[:id]).destroy
          head :no_content
        end

        private

        def ref_params
          params.require(:reference_stat).permit(:label, :stat_type_id, :value)
        end

        def ref_json(r)
          { id: r.id, label: r.label, stat_type_id: r.stat_type_id, stat_type: r.stat_type&.name, value: r.value }
        end
      end
    end
  end
end
