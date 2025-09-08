class HomeController < ApplicationController
  def index
    # Create some sample data and demonstrate logging
    @users = User.all
    @orders = Order.all
    @logs = ActiveModelLogger::Log.order(created_at: :desc).limit(10)

    # Create a demo user and order if none exist
    if @users.empty?
      create_demo_data
    end
  end

  def create_demo
    create_demo_data
    create_cached_log_chain_demo
    redirect_to root_path, notice: "Demo data created successfully!"
  end

  def create_session_demo
    create_session_workflow_demo
    redirect_to root_path, notice: "Session workflow demo created!"
  end

  def create_batch_demo
    create_batch_logging_demo
    redirect_to root_path, notice: "Batch logging demo created!"
  end

  def create_cleanup_demo
    create_cleanup_demo_data
    redirect_to root_path, notice: "Cleanup demo created!"
  end

  def create_block_demo
    create_block_logging_demo
    redirect_to root_path, notice: "Block logging demo created!"
  end

  def clear_logs
    ActiveModelLogger::Log.delete_all
    redirect_to root_path, notice: "All logs cleared!"
  end

  def cleanup_old_logs
    User.all.each(&:cleanup_old_logs)
    Order.all.each(&:cleanup_order_logs)
    redirect_to root_path, notice: "Old logs cleaned up!"
  end

  private

  def create_demo_data
    # Create a user
    user = User.create!(
      name: "John Doe",
      email: "john@example.com"
    )

    # Log user creation
    user.log_user_action("created", {
      email: user.email,
      created_by: "system"
    })

    # Create an order
    order = user.orders.create!(
      amount: 99.99,
      status: "pending"
    )

    # Log order creation
    order.log_order_event("created", {
      amount: order.amount,
      created_by: user.name
    })

    # Process the payment (this will create more logs)
    order.process_payment!

    # Log some additional user activities
    user.log_user_action("logged_in", {
      ip_address: "192.168.1.1",
      user_agent: "Mozilla/5.0..."
    })

    user.log_user_action("viewed_dashboard", {
      page: "home",
      session_id: SecureRandom.hex(16)
    })
  end

  def create_cached_log_chain_demo
    # Create a user specifically for demonstrating cached log_chain behavior
    demo_user = User.create!(
      name: "Cached Log Demo User",
      email: "cached_demo@example.com"
    )

    # Demonstrate cached log_chain behavior
    # First log generates and caches a UUID
    demo_user.log("First log - generates UUID", log_level: "info", visible_to: "admin")

    # Second log uses cached key (no explicit log_chain)
    demo_user.log("Second log - uses cached key", log_level: "info", visible_to: "admin")

    # Third log uses cached key (no explicit log_chain)
    demo_user.log("Third log - still uses cached key", log_level: "warn", visible_to: "admin")

    # Fourth log with explicit log_chain breaks the cache
    # Note: The gem handles log_chain automatically, so we'll demonstrate this differently
    demo_user.log("Fourth log - demonstrates log key management",
                  log_level: "info",
                  visible_to: "admin",
                  metadata: {
                    status: "success",
                    category: "log_chain_demo",
                    data: { explicit_key: "explicit_key_123" }
                  })

    # Fifth log uses the new cached key
    demo_user.log("Fifth log - uses new cached key", log_level: "info", visible_to: "admin")

    # Sixth log uses the new cached key
    demo_user.log("Sixth log - still uses new cached key", log_level: "error", visible_to: "admin")

    # Seventh log with another explicit log_chain breaks cache again
    demo_user.log("Seventh log - demonstrates log key management",
                  log_level: "info",
                  visible_to: "admin",
                  metadata: {
                    status: "success",
                    category: "log_chain_demo",
                    data: { explicit_key: "another_key_456" }
                  })

    # Eighth log uses the latest cached key
    demo_user.log("Eighth log - uses latest cached key", log_level: "info", visible_to: "admin")
  end

  def create_session_workflow_demo
    # Create a user for session workflow demo
    session_user = User.create!(
      name: "Session Workflow User",
      email: "session@example.com"
    )

    # Start a new session
    session_user.start_user_session({
      ip_address: "10.0.0.1",
      user_agent: "Firefox/121.0",
      session_id: SecureRandom.hex(16)
    })

    # Simulate a complex user workflow with multiple activities
    activities = [
      { activity: "viewed_homepage", details: { page_views: 1 } },
      { activity: "searched_products", details: { search_term: "laptop", results_count: 12 } },
      { activity: "viewed_product", details: { product_id: 123, product_name: "MacBook Pro" } },
      { activity: "added_to_cart", details: { product_id: 123, quantity: 1 } },
      { activity: "viewed_cart", details: { items_count: 1, total_amount: 1999.99 } },
      { activity: "started_checkout", details: { step: "payment" } },
      { activity: "completed_purchase", details: { order_id: 456, amount: 1999.99 } }
    ]

    activities.each do |activity|
      session_user.log_session_activity(activity[:activity], activity[:details])
      sleep(0.1) # Simulate time between activities
    end

    # End the session
    session_user.end_user_session
  end

  def create_batch_logging_demo
    # Create a user for batch logging demo
    batch_user = User.create!(
      name: "Batch Logging User",
      email: "batch@example.com"
    )

    # Demonstrate batch logging with workflow steps
    workflow_steps = [
      { message: "User registration started", level: "info", status: "started", data: { step: 1 } },
      { message: "Email validation completed", level: "info", status: "completed", data: { step: 2, email: batch_user.email } },
      { message: "Profile creation in progress", level: "debug", status: "in_progress", data: { step: 3 } },
      { message: "Preferences configured", level: "info", status: "completed", data: { step: 4, preferences: ["email_notifications", "sms_alerts"] } },
      { message: "Welcome email sent", level: "info", status: "completed", data: { step: 5, email_template: "welcome_v2" } },
      { message: "User onboarding completed", level: "info", status: "completed", data: { step: 6, total_time: "2.5s" } }
    ]

    batch_user.log_user_workflow_steps(workflow_steps)

    # Create an order with batch lifecycle events
    order = batch_user.orders.create!(
      amount: 299.99,
      status: "pending"
    )

    order.log_order_lifecycle_events
  end

  def create_cleanup_demo_data
    # Create a user with many old logs for cleanup demo
    cleanup_user = User.create!(
      name: "Cleanup Demo User",
      email: "cleanup@example.com"
    )

    # Create logs with different timestamps (simulate old logs)
    (1..20).each do |i|
      # Create logs with timestamps from different days
      log_time = i.days.ago

      cleanup_user.log("Old log entry #{i}",
        log_level: "info",
        metadata: {
          status: "completed",
          category: "cleanup_demo",
          data: { day: i, created_at: log_time }
        })
    end

    # Create some recent logs
    (1..5).each do |i|
      cleanup_user.log("Recent log entry #{i}",
        log_level: "info",
        metadata: {
          status: "completed",
          category: "cleanup_demo",
          data: { day: "recent", created_at: Time.current }
        })
    end
  end

  def create_block_logging_demo
    # Create a user for block logging demo
    block_user = User.create!(
      name: "Block Logging User",
      email: "block@example.com"
    )

    # Demonstrate block logging with automatic start/end logs
    block_user.log_block("Complex Data Processing") do |logger|
      logger.log("Starting data validation", log_level: "info")

      # Simulate some processing steps
      sleep(0.1)
      logger.log("Validating user input", log_level: "debug",
                 metadata: { step: 1, status: "in_progress" })

      sleep(0.1)
      logger.log("Processing payment data", log_level: "debug",
                 metadata: { step: 2, status: "in_progress" })

      sleep(0.1)
      logger.log("Updating database records", log_level: "debug",
                 metadata: { step: 3, status: "in_progress" })

      sleep(0.1)
      logger.log("Sending confirmation email", log_level: "info",
                 metadata: { step: 4, status: "completed" })

      logger.log("Data processing completed successfully", log_level: "info",
                 metadata: { total_steps: 4, processing_time: "0.4s" })
    end

    # Demonstrate block logging with error handling
    block_user.log_block("Risky Operation") do |logger|
      logger.log("Attempting risky operation", log_level: "warn")

      # Simulate a risky operation that might fail
      if rand < 0.3  # 30% chance of failure
        logger.log("Operation failed", log_level: "error",
                   metadata: { error: "Simulated failure", retry_count: 0 })
        raise StandardError, "Simulated operation failure"
      else
        logger.log("Risky operation succeeded", log_level: "info",
                   metadata: { success: true, duration: "0.2s" })
      end
    end
  rescue StandardError => e
    # Error handling is automatic in block logging
    Rails.logger.info "Block logging demo completed with error handling"
  end
end
