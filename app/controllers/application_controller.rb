class ApplicationController < ActionController::Base
  before_action :skip_session
  after_action :allow_iframe

  private
    def skip_session
      request.session_options[:skip] = true
    end

    def allow_iframe
      response.headers.except! "X-Frame-Options"
      response.set_header "X-XSS-Protection", "0"
    end
end
