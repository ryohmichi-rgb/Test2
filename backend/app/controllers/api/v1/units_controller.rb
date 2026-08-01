module Api
  module V1
    class UnitsController < ApplicationController
      def show
        unit = Unit.includes(:grade, :subject, problems: :choices).find(params[:id])
        json = unit.as_json(
          only: [:id, :title, :description, :lesson_body, :display_order],
          include: { grade: { only: [:id, :name] }, subject: { only: [:id, :name] } }
        )
        # 有効な問題だけを、やさしい順に出す。
        # 単元べつ演習はこの並びのまま1問ずつ進む画面なので、難易度の昇順にしておくと
        # 「進むほど手ごたえが出る／どこでやめても区切りになる」形になる。
        json["problems"] = unit.problems.select(&:active).sort_by { |p| [p.difficulty.to_i, p.id] }.map do |p|
          p.as_json(only: [:id, :question, :hint, :difficulty, :problem_type])
           .merge("choices" => p.choices.as_json(only: [:id, :text]))
        end
        render json: json
      end
    end
  end
end
