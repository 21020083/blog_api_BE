module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_api_v1_user!
      before_action :set_user, only: %i[ show update destroy ]
      # GET /users
      def index
            render json: UserSerializer.new(current_user).serializable_hash[:data][:attributes], status: :ok
      end

      # GET /users/1
      def show
        render jsonapi: @user
      end

      # PATCH/PUT /users/1
      def update
        if @user.update(user_params)
          render jsonapi: @user
        else
          render json: @user.errors, status: :unprocessable_entity
        end
      end

      # DELETE /users/1
      def destroy
        @user.destroy!
        render jsonapi: @user
      end

      private
        # Use callbacks to share common setup or constraints between actions.
        def set_user
          @user = User.find(params[:id])
        end

        # Only allow a list of trusted parameters through.
        def user_params
          params.require(:user).permit(:username, :name, :email)
        end

    end
  end
end
