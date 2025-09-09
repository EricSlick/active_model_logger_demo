class OrderProcessingJob < ApplicationJob
  def perform(order_id, workflow_id)
    @order = Order.find(order_id)
    @workflow_id = workflow_id

    # Use the same log_chain for the entire workflow
    ActiveModelLogger::Log.create!(
      loggable: @order,
      message: "Starting order processing workflow",
      metadata: {
        log_chain: @workflow_id,
        category: "order_processing",
        data: { order_id: @order.id, step: 1, total_steps: 4 }
      }
    )

    # Step 1: Validate order
    validate_order

    # Step 2: Process payment
    process_payment

    # Step 3: Update inventory
    update_inventory

    # Step 4: Send confirmation
    send_confirmation

    ActiveModelLogger::Log.create!(
      loggable: @order,
      message: "Order processing workflow completed successfully",
      metadata: {
        log_chain: @workflow_id,
        category: "order_processing",
        data: { order_id: @order.id, step: 4, total_steps: 4, status: "completed" }
      }
    )
  end

  private

  def validate_order
    ActiveModelLogger::Log.create!(
      loggable: @order,
      message: "Validating order details",
      metadata: {
        log_chain: @workflow_id,
        category: "validation",
        data: { order_id: @order.id, step: 1 }
      }
    )

    # Simulate validation logic
    sleep(0.5) # Simulate processing time

    if @order.amount > 0
      ActiveModelLogger::Log.create!(
        loggable: @order,
        message: "Order validation passed",
        metadata: {
          log_chain: @workflow_id,
          category: "validation",
          data: { order_id: @order.id, step: 1, result: "passed" }
        }
      )
    else
      ActiveModelLogger::Log.create!(
        loggable: @order,
        message: "Order validation failed - invalid amount",
        metadata: {
          log_chain: @workflow_id,
          log_level: "error",
          category: "validation",
          data: { order_id: @order.id, step: 1, result: "failed", error: "invalid_amount" }
        }
      )
      raise "Order validation failed"
    end
  end

  def process_payment
    ActiveModelLogger::Log.create!(
      loggable: @order,
      message: "Processing payment for order",
      metadata: {
        log_chain: @workflow_id,
        category: "payment",
        data: { order_id: @order.id, step: 2, amount: @order.amount }
      }
    )

    # Simulate payment processing
    sleep(1.0) # Simulate processing time

    # Simulate payment success/failure
    if @order.amount < 1000 # Simulate payment success for orders under $1000
      ActiveModelLogger::Log.create!(
        loggable: @order,
        message: "Payment processed successfully",
        metadata: {
          log_chain: @workflow_id,
          category: "payment",
          data: { order_id: @order.id, step: 2, result: "success", transaction_id: SecureRandom.hex(8) }
        }
      )
    else
      ActiveModelLogger::Log.create!(
        loggable: @order,
        message: "Payment processing failed - amount too high",
        metadata: {
          log_chain: @workflow_id,
          log_level: "error",
          category: "payment",
          data: { order_id: @order.id, step: 2, result: "failed", error: "amount_too_high" }
        }
      )
      raise "Payment processing failed"
    end
  end

  def update_inventory
    ActiveModelLogger::Log.create!(
      loggable: @order,
      message: "Updating inventory for order",
      metadata: {
        log_chain: @workflow_id,
        category: "inventory",
        data: { order_id: @order.id, step: 3 }
      }
    )

    # Simulate inventory update
    sleep(0.8) # Simulate processing time

    ActiveModelLogger::Log.create!(
      loggable: @order,
      message: "Inventory updated successfully",
      metadata: {
        log_chain: @workflow_id,
        category: "inventory",
        data: { order_id: @order.id, step: 3, result: "success", items_reserved: 1 }
      }
    )
  end

  def send_confirmation
    ActiveModelLogger::Log.create!(
      loggable: @order,
      message: "Sending order confirmation",
      metadata: {
        log_chain: @workflow_id,
        category: "notification",
        data: { order_id: @order.id, step: 4, user_id: @order.user_id }
      }
    )

    # Simulate sending confirmation
    sleep(0.3) # Simulate processing time

    ActiveModelLogger::Log.create!(
      loggable: @order,
      message: "Order confirmation sent successfully",
      metadata: {
        log_chain: @workflow_id,
        category: "notification",
        data: { order_id: @order.id, step: 4, result: "success", email_sent: true }
      }
    )
  end
end
