module Admin
  class UsersController < BaseController
    def index
      @users = User.includes(:sessions).order(created_at: :desc)
      @new_user = User.new(admin: true)
    end

    def create
      @new_user = User.new(user_params.except(:admin))
      @new_user.admin = user_params[:admin] == "1"

      if @new_user.save
        redirect_to admin_users_path, notice: "Account #{@new_user.email_address} created successfully (#{@new_user.role_title})."
      else
        @users = User.includes(:sessions).order(created_at: :desc)
        flash.now[:alert] = @new_user.errors.full_messages.to_sentence
        render :index, status: :unprocessable_entity
      end
    end

    def toggle_admin
      @user = User.find(params[:id])
      if @user == Current.user && @user.admin?
        redirect_to admin_users_path, alert: "You cannot revoke your own administrator privileges."
      else
        @user.update!(admin: !@user.admin?)
        state = @user.admin? ? "promoted to Administrator" : "changed to Regular Reader"
        redirect_to admin_users_path, notice: "User #{@user.email_address} #{state}."
      end
    end

    def destroy
      @user = User.find(params[:id])
      if @user == Current.user
        redirect_to admin_users_path, alert: "You cannot delete your own account from the administrator dashboard."
      else
        @user.destroy
        redirect_to admin_users_path, notice: "User #{@user.email_address} has been removed."
      end
    end

    private

    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation, :admin)
    end
  end
end

