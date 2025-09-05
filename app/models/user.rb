class User < ApplicationRecord
  include ActiveModelLogger::Loggable

  has_many :orders, dependent: :destroy

  # Configure logging defaults for users
  configure_loggable(
    default_visible_to: "user",
    default_log_level: "info"
  )

  def log_user_action(action, details = {})
    log("User #{action}",
        log_level: "info",
        metadata: {
          status: "success",
          category: "user_action",
          data: details
        })
  end
end
