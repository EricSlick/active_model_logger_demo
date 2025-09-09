# Mission Control Jobs configuration
# Disable authentication in development for easier testing
if Rails.env.development?
  Rails.application.config.after_initialize do
    # Override the authentication method to always return true in development
    MissionControl::Jobs::ApplicationController.class_eval do
      def authenticate_by_http_basic
        true
      end

      # Also override the before_action callback
      skip_before_action :authenticate_by_http_basic, if: -> { Rails.env.development? }
    end
  end
end
