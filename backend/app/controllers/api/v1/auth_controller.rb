module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_request, only: [:signup, :login]

      # POST /api/v1/signup  { name, username, password }
      def signup
        student = Student.new(signup_params)
        if student.save
          render json: token_payload(student), status: :created
        else
          render json: { errors: student.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/login  { username, password }
      def login
        student = Student.find_by("lower(username) = ?", params[:username].to_s.downcase)
        if student&.authenticate(params[:password])
          render json: token_payload(student)
        else
          render json: { error: "ユーザーIDかパスワードが違います" }, status: :unauthorized
        end
      end

      # GET /api/v1/me  — トークンから現在のユーザーを返す（起動時の確認用）
      def me
        render json: student_json(current_student)
      end

      private

      def signup_params
        params.permit(:name, :username, :password)
      end

      def token_payload(student)
        { token: student.generate_token_for(:auth), student: student_json(student) }
      end

      def student_json(student)
        { id: student.id, name: student.name, username: student.username }
      end
    end
  end
end
