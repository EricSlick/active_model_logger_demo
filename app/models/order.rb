class Order < ApplicationRecord
  include ActiveModelLogger::Loggable

  belongs_to :user

  # Configure logging defaults for orders
  configure_loggable(
    default_visible_to: "admin",
    default_log_level: "info"
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
end
