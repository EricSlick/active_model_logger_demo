class User < ApplicationRecord
  include ActiveModelLogger::Loggable

  has_many :orders, dependent: :destroy
  has_many :active_model_logs, as: :loggable, class_name: 'ActiveModelLogger::Log', dependent: :destroy

  # Configure logging defaults for users
  configure_loggable(
    default_visible_to: "user",
    default_log_level: "info",
    auto_log_chain: true
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

  # Demonstrate batch logging for performance
  def log_user_workflow_steps(steps)
    log_entries = steps.map do |step|
      {
        message: step[:message],
        log_level: step[:level] || "info",
        metadata: {
          status: step[:status] || "success",
          category: "workflow",
          data: step[:data] || {}
        }
      }
    end

    log_batch(log_entries)
  end

  # Demonstrate session tracking with log chains
  def start_user_session(session_data = {})
    log("User session started",
        log_level: "info",
        metadata: {
          status: "started",
          category: "session",
          data: session_data
        })
  end

  def log_session_activity(activity, details = {})
    log("Session activity: #{activity}",
        log_level: "debug",
        metadata: {
          status: "active",
          category: "session_activity",
          data: details
        })
  end

  def end_user_session
    log("User session ended",
        log_level: "info",
        metadata: {
          status: "completed",
          category: "session"
        })
  end

  # Demonstrate log cleanup
  def cleanup_old_logs
    cleanup_logs(older_than: 7.days, keep_recent: 10)
  end

  # Demonstrate enhanced query methods
  def recent_errors
    active_model_logs.by_level("error").limit(5)
  end

  def logs_by_category(category)
    active_model_logs.by_category(category)
  end

  def session_logs
    logs(log_chain: log_chain)
  end
end
