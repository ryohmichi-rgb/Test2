module Api
  module V1
    module Admin
      class SubjectsController < BaseController
        def index
          render json: Subject.order(:id).map { |s| subject_json(s) }
        end

        def create
          subject = Subject.new(subject_params)
          if subject.save
            render json: subject_json(subject), status: :created
          else
            render json: { errors: subject.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          subject = Subject.find(params[:id])
          if subject.update(subject_params)
            render json: subject_json(subject)
          else
            render json: { errors: subject.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # 単元がぶら下がっている教科は消させない。
        # Subject は has_many :units, dependent: :destroy なので、そのまま消すと
        # 単元も問題も回答履歴もまとめて消える。他の管理画面と同じ「未使用のみ削除」に揃える。
        def destroy
          subject = Subject.find(params[:id])
          if subject.units.exists?
            render json: { error: "この教科には単元があるため削除できません。先に単元を移すか削除してください。" },
                   status: :unprocessable_entity
          else
            subject.destroy
            head :no_content
          end
        end

        private

        def subject_params
          params.require(:subject).permit(:name)
        end

        def subject_json(s)
          { id: s.id, name: s.name, unit_count: s.units.count, used: s.units.exists? }
        end
      end
    end
  end
end
