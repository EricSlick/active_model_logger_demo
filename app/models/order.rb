class Order < ApplicationRecord
  include ActiveModelLogger::Loggable

  belongs_to :user
  has_many :active_model_logs, as: :loggable, class_name: "ActiveModelLogger::Log", dependent: :destroy

  # Configure logging defaults for orders
  configure_loggable(
    default_visible_to: "admin",
    default_log_level: "info",
    auto_log_chain: true
  )

  def log_order_event(event, details = {})
    log("Order #{event}",
        log_level: "info",
        metadata: {
          status: "success",
          category: "order",
          data: {
            order_id: id,
            amount: amount,
            user_id: user_id,
            **details
          }
        })
  end

  def process_payment!
    log_order_event("payment_processing_started", { payment_method: "credit_card" })

    # Simulate payment processing
    sleep(0.1) # Simulate API call

    if amount > 0
      update!(status: "paid")
      log_order_event("payment_completed", {
        payment_id: "pay_#{SecureRandom.hex(8)}",
        processed_at: Time.current
      })
    else
      log_order_event("payment_failed", {
        error: "Invalid amount",
        log_level: "error"
      }, log_level: "error")
    end
  end

  # Demonstrate order workflow with log chains
  def start_order_processing
    log("Order processing started",
        log_level: "info",
        metadata: {
          status: "started",
          category: "order_processing",
          data: { order_id: id, amount: amount }
        })
  end

  def log_processing_step(step, details = {})
    log("Processing step: #{step}",
        log_level: "debug",
        metadata: {
          status: "in_progress",
          category: "order_processing",
          data: { step: step, **details }
        })
  end

  def complete_order_processing
    log("Order processing completed",
        log_level: "info",
        metadata: {
          status: "completed",
          category: "order_processing",
          data: { order_id: id, final_status: status }
        })
  end

  # Demonstrate batch logging for order events
  def log_order_lifecycle_events
    events = [
      { message: "Order created", level: "info", status: "created", data: { amount: amount } },
      { message: "Payment processed", level: "info", status: "paid", data: { payment_method: "credit_card" } },
      { message: "Order shipped", level: "info", status: "shipped", data: { tracking_number: "TRK#{SecureRandom.hex(4)}" } },
      { message: "Order delivered", level: "info", status: "delivered", data: { delivered_at: Time.current } }
    ]

    log_batch(events)
  end

  # Demonstrate enhanced query methods
  def processing_logs
    logs_by_category("order_processing")
  end

  def error_logs
    active_model_logs.error_logs
  end

  def recent_activity
    recent_logs(10)
  end

  # Demonstrate log cleanup for orders
  def cleanup_order_logs
    cleanup_logs(older_than: 30.days, keep_recent: 20)
  end
end
