# Mission Control Jobs configuration
# Disable authentication in development for easier testing
if Rails.env.development?
  Rails.application.config.after_initialize do
    MissionControl::Jobs::ApplicationController.class_eval do
      def authenticate_by_http_basic
        true
      end
    end
  end
end
