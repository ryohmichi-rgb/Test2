module Api
  module V1
    module Admin
      # ランク（段位）の調整。しきい値・合格ライン・問題数を seed の書き換えなしで直せるようにする。
      class RanksController < BaseController
        def index
          render json: Rank.ordered.map { |r| rank_json(r) }
        end

        # 新しい段位は一番上に足す（display_order は最大＋1）。
        # 途中に差しこむ形は用意していない。`next_rank` は display_order の順で次を探すので、
        # 抜け番があっても動く＝削除で番号を詰め直す必要もない。
        def create
          rank = Rank.new(rank_params)
          rank.display_order = (Rank.maximum(:display_order) || 0) + 1
          if rank.save
            render json: rank_json(rank), status: :created
          else
            render json: { errors: rank.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          rank = Rank.find(params[:id])
          if rank.update(rank_params)
            render json: rank_json(rank)
          else
            render json: { errors: rank.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # そのランクの生徒がいたら消さない。消すと student_ranks.rank_id が NULL になり、
        # 最下位ランク扱い＝実質の降格になってしまう。
        def destroy
          rank = Rank.find(params[:id])
          if rank.used?
            render json: { error: "このランクの生徒がいるため削除できません。" }, status: :unprocessable_entity
          elsif Rank.count <= 1
            render json: { error: "ランクを空にはできません。" }, status: :unprocessable_entity
          else
            rank.destroy
            head :no_content
          end
        end

        private

        # display_order は create で自動、update では変えない（段位の並びは画面から動かさない）
        def rank_params
          params.require(:rank).permit(:name, :threshold_points, :exam_question_count, :pass_percent)
        end

        def rank_json(r)
          {
            id: r.id,
            name: r.name,
            display_order: r.display_order,
            threshold_points: r.threshold_points,
            exam_question_count: r.exam_question_count,
            pass_percent: r.pass_percent,
            student_count: r.student_ranks.count,
            used: r.used?,
            # このランク名に依存しているバッジ。名前を変えると獲得できなくなるので画面で知らせる
            badges: BadgeCatalog.badges_for_rank_name(r.name).map { |b| "#{b.emoji} #{b.label}" }
          }
        end
      end
    end
  end
end
