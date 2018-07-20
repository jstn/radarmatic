class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  after_action :allow_iframe

  private

    def allow_iframe
      response.headers.except! "X-Frame-Options"
      response.set_header "X-XSS-Protection", "0"
    end
end
