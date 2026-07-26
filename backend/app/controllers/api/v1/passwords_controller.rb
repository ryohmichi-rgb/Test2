module Api
  module V1
    # 生徒が自分でパスワードを変える。
    class PasswordsController < ApplicationController
      include StudentScoped

      MIN_LENGTH = 4

      # PUT /api/v1/students/:id/password  { current_password, new_password }
      def update
        student = current_student

        unless student.authenticate(params[:current_password].to_s)
          return render json: { error: "いまのパスワードが違います" }, status: :unauthorized
        end

        new_password = params[:new_password].to_s
        if new_password.length < MIN_LENGTH
          return render json: { error: "あたらしいパスワードは#{MIN_LENGTH}文字以上にしてね" }, status: :unprocessable_entity
        end

        if student.update(password: new_password)
          # パスワードを変えると今までのトークンは失効する（署名にソルトを含むため）。
          # そのままだと本人が締め出されるので、新しいトークンを返してフロントで差し替える。
          render json: { token: student.generate_token_for(:auth) }
        else
          render json: { errors: student.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
