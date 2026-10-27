module Admin
  class BaseController < ApplicationController
    before_action :require_admin

    private

    def require_admin
      unless Current.user&.admin?
        redirect_to root_path, alert: "Access restricted. Administrator privileges required."
      end
    end
  end
end

