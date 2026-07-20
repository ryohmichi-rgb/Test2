module Api
  module V1
    module Admin
      class BaseController < ApplicationController
        include AdminOnly
      end
    end
  end
end
