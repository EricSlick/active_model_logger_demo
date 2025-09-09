class HomeController < ApplicationController
  def index
    # Create some sample data and demonstrate logging
    @users = User.all
    @orders = Order.all
    @logs = ActiveModelLogger::Log.order(created_at: :desc).page(params[:page]).per(20)

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

  def create_nested_keys_demo
    create_nested_keys_demo_data
    redirect_to root_path, notice: "Nested keys demo created!"
  end

  def create_log_chain_demo
    create_log_chain_demo_data
    redirect_to log_chain_demo_path, notice: "Log chain demo created! View the grouped log chains below."
  end

  def log_chain_demo
    # Group logs by log_chain and get the first log in each chain
    @log_chains = ActiveModelLogger::Log
      .where.not(Arel.sql("JSON_EXTRACT(metadata, '$.log_chain') IS NULL"))
      .where.not(Arel.sql("JSON_EXTRACT(metadata, '$.log_chain') = ''"))
      .group(Arel.sql("JSON_EXTRACT(metadata, '$.log_chain')"))
      .order(Arel.sql("MIN(created_at) DESC"))
      .pluck(Arel.sql("JSON_EXTRACT(metadata, '$.log_chain')"))
      .map do |chain_id|
        first_log = ActiveModelLogger::Log
          .where(Arel.sql("JSON_EXTRACT(metadata, '$.log_chain') = ?"), chain_id)
          .order(:created_at)
          .first

        all_logs = ActiveModelLogger::Log
          .where(Arel.sql("JSON_EXTRACT(metadata, '$.log_chain') = ?"), chain_id)
          .order(:created_at)

        {
          chain_id: chain_id,
          first_log: first_log,
          total_count: all_logs.count,
          all_logs: all_logs
        }
      end
  end

  def clear_logs
    ActiveModelLogger::Log.delete_all
    redirect_to root_path, notice: "All logs cleared!"
  end

  def clear_users
    # Get user count before deletion
    user_count = User.count

    # Clear all users (this will automatically destroy associated orders and logs due to dependent: :destroy)
    User.destroy_all

    redirect_to root_path, notice: "Cleared #{user_count} users, their orders, and all associated logs!"
  end

  def clear_orders
    # Clear all orders
    # This will automatically destroy associated order logs due to dependent: :destroy
    order_count = Order.count
    Order.destroy_all

    redirect_to root_path, notice: "Cleared #{order_count} orders and their associated logs!"
  end

  def create_job_workflow_demo
    # Create a user and order for the demo
    user = User.create!(
      name: "Job Workflow Demo User",
      email: "job-demo@example.com"
    )

    order = user.orders.create!(
      amount: rand(50..500),
      status: "pending"
    )

    # Generate a unique workflow ID for this demo
    workflow_id = SecureRandom.uuid

    # Log the start of the workflow
    user.log("Starting multi-job workflow demo",
             log_chain: workflow_id,
             metadata: {
               category: "workflow_demo",
               data: {
                 workflow_id: workflow_id,
                 user_id: user.id,
                 order_id: order.id,
                 total_jobs: 3
               }
             })

    # Queue the jobs with the same log_chain
    OrderProcessingJob.perform_later(order.id, workflow_id)
    EmailNotificationJob.perform_later(user.id, workflow_id, "order_confirmation")
    InventoryManagementJob.perform_later(order.id, workflow_id, "reserve")

    redirect_to root_path, notice: "Multi-job workflow demo started! Check the logs to see the workflow progress. Workflow ID: #{workflow_id[0..8]}..."
  end

  def cleanup_old_logs
    total_cleaned = 0
    user_cleaned = 0
    order_cleaned = 0

    # Clean up user logs
    User.all.each do |user|
      cleaned = user.cleanup_old_logs
      user_cleaned += cleaned
    end

    # Clean up order logs
    Order.all.each do |order|
      cleaned = order.cleanup_order_logs
      order_cleaned += cleaned
    end

    total_cleaned = user_cleaned + order_cleaned

    if total_cleaned > 0
      redirect_to root_path, notice: "Cleaned up #{total_cleaned} old logs! (#{user_cleaned} user logs, #{order_cleaned} order logs)"
    else
      redirect_to root_path, notice: "No old logs found to clean up. All logs are recent or within the retention period."
    end
  end

  def create_test_logs_for_cleanup
    create_three_week_test_logs
    redirect_to root_path, notice: "Created 30 test logs spanning the previous 3 weeks for cleanup testing!"
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
    demo_user.log("Fourth log - demonstrates log chain management",
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
    demo_user.log("Seventh log - demonstrates log chain management",
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
      { message: "Preferences configured", level: "info", status: "completed", data: { step: 4, preferences: [ "email_notifications", "sms_alerts" ] } },
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

      # Create the log entry first
      log_entry = cleanup_user.log("Old log entry #{i}",
        log_level: "info",
        metadata: {
          status: "completed",
          category: "cleanup_demo",
          data: { day: i, created_at: log_time }
        })

      # Then update the created_at timestamp to simulate old logs
      log_entry.update_columns(created_at: log_time, updated_at: log_time)
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
    begin
      block_user.log_block do |logger|
        logger.log("Complex Data Processing started", log_level: "info")
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
        logger.log("Complex Data Processing completed", log_level: "info")
      end
    rescue StandardError => e
      Rails.logger.error "Block logging error: #{e.message}"
    end

    # Demonstrate block logging with error handling
    begin
      block_user.log_block do |logger|
        logger.log("Risky Operation started", log_level: "info")
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
        logger.log("Risky Operation completed", log_level: "info")
      end
    rescue StandardError => e
      # Error handling is automatic in block logging
      Rails.logger.info "Block logging demo completed with error handling: #{e.message}"
    end
  end

  def create_three_week_test_logs
    # Create a user for three-week test logs
    test_user = User.create!(
      name: "Three Week Test User",
      email: "threeweek@example.com"
    )

    # Create 30 logs spanning the previous 3 weeks (21 days)
    # Distribute them across different days with some clustering
    log_dates = [
      # Week 1 (most recent - 7 days ago to 1 day ago)
      1.day.ago, 2.days.ago, 3.days.ago, 4.days.ago, 5.days.ago, 6.days.ago, 7.days.ago,

      # Week 2 (8-14 days ago)
      8.days.ago, 9.days.ago, 10.days.ago, 11.days.ago, 12.days.ago, 13.days.ago, 14.days.ago,

      # Week 3 (15-21 days ago)
      15.days.ago, 16.days.ago, 17.days.ago, 18.days.ago, 19.days.ago, 20.days.ago, 21.days.ago,

      # Additional logs for more realistic distribution
      1.day.ago, 3.days.ago, 5.days.ago, 7.days.ago, 9.days.ago, 11.days.ago, 13.days.ago,
      15.days.ago, 17.days.ago, 19.days.ago, 21.days.ago, 2.days.ago, 4.days.ago, 6.days.ago,
      8.days.ago, 10.days.ago, 12.days.ago, 14.days.ago, 16.days.ago, 18.days.ago, 20.days.ago
    ]

    log_dates.each_with_index do |log_date, index|
      # Create the log entry first
      log_entry = test_user.log("Test log entry #{index + 1}",
        log_level: "info",
        metadata: {
          status: "completed",
          category: "cleanup_test",
          data: {
            day_offset: (Time.current - log_date).to_i / 1.day,
            created_at: log_date,
            week: case (Time.current - log_date).to_i / 1.day
                  when 0..7 then "Week 1 (Recent)"
                  when 8..14 then "Week 2 (Middle)"
                  else "Week 3 (Old)"
                  end
          }
        })

      # Update the created_at timestamp to the specific date
      log_entry.update_columns(created_at: log_date, updated_at: log_date)
    end
  end

  def create_nested_keys_demo_data
    # Create a user for nested keys demo
    nested_user = User.create!(
      name: "Nested Keys Demo User",
      email: "nested@example.com"
    )

    # Create logs with deeply nested structures using raw SQL to ensure proper storage
    ActiveRecord::Base.connection.execute("INSERT INTO active_model_logs (loggable_type, loggable_id, message, metadata, created_at, updated_at) VALUES ('User', #{nested_user.id}, 'User settings updated', '{\"status\":\"success\",\"category\":\"settings\",\"settings\":{\"notifications\":{\"email\":true,\"sms\":false,\"push\":true},\"privacy\":{\"public\":false,\"share_data\":false},\"preferences\":{\"theme\":\"dark\",\"language\":\"en\"}}}', datetime('now'), datetime('now'))")

    ActiveRecord::Base.connection.execute("INSERT INTO active_model_logs (loggable_type, loggable_id, message, metadata, created_at, updated_at) VALUES ('User', #{nested_user.id}, 'User profile created', '{\"status\":\"success\",\"category\":\"profile\",\"user\":{\"profile\":{\"personal\":{\"name\":\"John Doe\",\"age\":30,\"city\":\"New York\"},\"contact\":{\"email\":\"john@example.com\",\"phone\":\"+1234567890\"},\"preferences\":{\"newsletter\":true,\"marketing\":false}}}}', datetime('now'), datetime('now'))")

    ActiveRecord::Base.connection.execute("INSERT INTO active_model_logs (loggable_type, loggable_id, message, metadata, created_at, updated_at) VALUES ('User', #{nested_user.id}, 'System configuration', '{\"status\":\"completed\",\"category\":\"config\",\"config\":{\"database\":{\"host\":\"localhost\",\"port\":5432,\"ssl\":true},\"cache\":{\"redis\":{\"enabled\":true,\"ttl\":3600},\"memcached\":{\"enabled\":false}},\"features\":{\"beta\":{\"enabled\":true,\"users\":[\"admin\"]}}}}', datetime('now'), datetime('now'))")

    ActiveRecord::Base.connection.execute("INSERT INTO active_model_logs (loggable_type, loggable_id, message, metadata, created_at, updated_at) VALUES ('User', #{nested_user.id}, 'API integration setup', '{\"status\":\"completed\",\"category\":\"integration\",\"api\":{\"endpoints\":{\"auth\":{\"enabled\":true,\"rate_limit\":1000},\"data\":{\"enabled\":true,\"rate_limit\":5000}},\"security\":{\"oauth\":{\"enabled\":true,\"scopes\":[\"read\",\"write\"]},\"api_key\":{\"enabled\":false}}}}', datetime('now'), datetime('now'))")

    # Create an order with nested metadata
    order = nested_user.orders.create!(
      amount: 199.99,
      status: "pending"
    )

    # Create order log with nested data using raw SQL
    ActiveRecord::Base.connection.execute("INSERT INTO active_model_logs (loggable_type, loggable_id, message, metadata, created_at, updated_at) VALUES ('Order', #{order.id}, 'Order created', '{\"status\":\"success\",\"category\":\"order\",\"amount\":199.99,\"payment\":{\"method\":\"credit_card\",\"details\":{\"card_type\":\"visa\",\"last_four\":\"1234\",\"expiry\":\"12/25\"}},\"shipping\":{\"address\":{\"street\":\"123 Main St\",\"city\":\"New York\",\"state\":\"NY\",\"zip\":\"10001\"},\"method\":\"standard\",\"tracking\":{\"enabled\":true,\"provider\":\"ups\"}}}', datetime('now'), datetime('now'))")
  end

  def create_log_chain_demo_data
    # Create a user for log chain demo
    chain_user = User.create!(
      name: "Log Chain Demo User",
      email: "chain@example.com"
    )

    # DEMONSTRATION 1: Manual log chain assignment
    # Show how you can manually set a specific log chain
    manual_chain_id = "manual_chain_#{SecureRandom.hex(8)}"

    chain_user.log("Manual log chain assigned",
                   log_chain: manual_chain_id,
                   log_level: "info",
                   metadata: {
                     status: "started",
                     category: "demo",
                     data: {
                       chain_type: "manual_assignment",
                       chain_id: manual_chain_id,
                       note: "This log chain was manually set to a specific value"
                     }
                   })

    # DEMONSTRATION 2: Auto-generated log chain (using auto_log_chain: true)
    # This will use the model's auto_log_chain feature
    chain_user.log("Auto-generated log chain",
                   log_level: "info",
                   metadata: {
                     status: "started",
                     category: "demo",
                     data: {
                       chain_type: "auto_generated",
                       note: "This log chain was auto-generated by the model"
                     }
                   })

    # DEMONSTRATION 3: Changing log chain mid-workflow
    # Start with one chain, then switch to another
    workflow_chain_1 = "workflow_phase_1_#{SecureRandom.hex(4)}"
    workflow_chain_2 = "workflow_phase_2_#{SecureRandom.hex(4)}"

    # Phase 1: User authentication
    chain_user.log("User authentication started",
                   log_chain: workflow_chain_1,
                   log_level: "info",
                   metadata: {
                     status: "started",
                     category: "authentication",
                     data: {
                       phase: "authentication",
                       chain_id: workflow_chain_1,
                       note: "Phase 1: Authentication workflow"
                     }
                   })

    chain_user.log("User credentials validated",
                   log_chain: workflow_chain_1,
                   log_level: "info",
                   metadata: {
                     status: "success",
                     category: "authentication",
                     data: {
                       phase: "authentication",
                       validation_time: "150ms",
                       method: "email_password"
                     }
                   })

    # Phase 2: Switch to different chain for shopping workflow
    chain_user.log("Switching to shopping workflow",
                   log_chain: workflow_chain_2,
                   log_level: "info",
                   metadata: {
                     status: "transition",
                     category: "workflow",
                     data: {
                       phase: "shopping",
                       chain_id: workflow_chain_2,
                       previous_chain: workflow_chain_1,
                       note: "Phase 2: Shopping workflow with new chain"
                     }
                   })

    chain_user.log("Product catalog loaded",
                   log_chain: workflow_chain_2,
                   log_level: "info",
                   metadata: {
                     status: "success",
                     category: "shopping",
                     data: {
                       phase: "shopping",
                       products_count: 150,
                       load_time: "2.3s"
                     }
                   })

    # DEMONSTRATION 4: Nested log chains (chain within a chain)
    # Create a sub-workflow with its own chain
    main_chain = "main_workflow_#{SecureRandom.hex(6)}"
    sub_chain = "sub_workflow_#{SecureRandom.hex(4)}"

    chain_user.log("Main workflow started",
                   log_chain: main_chain,
                   log_level: "info",
                   metadata: {
                     status: "started",
                     category: "main_workflow",
                     data: {
                       chain_id: main_chain,
                       note: "Main workflow with nested sub-workflow"
                     }
                   })

    # Sub-workflow with different chain
    chain_user.log("Sub-workflow: Payment processing",
                   log_chain: sub_chain,
                   log_level: "info",
                   metadata: {
                     status: "started",
                     category: "payment",
                     data: {
                       parent_chain: main_chain,
                       sub_chain_id: sub_chain,
                       note: "Nested sub-workflow for payment processing"
                     }
                   })

    chain_user.log("Payment method selected",
                   log_chain: sub_chain,
                   log_level: "info",
                   metadata: {
                     status: "completed",
                     category: "payment",
                     data: {
                       payment_method: "credit_card",
                       amount: 99.99
                     }
                   })

    # Back to main workflow
    chain_user.log("Sub-workflow completed, returning to main",
                   log_chain: main_chain,
                   log_level: "info",
                   metadata: {
                     status: "completed",
                     category: "main_workflow",
                     data: {
                       chain_id: main_chain,
                       completed_sub_chain: sub_chain,
                       note: "Returned to main workflow after sub-workflow"
                     }
                   })

    # DEMONSTRATION 5: Dynamic log chain generation
    # Show how log chains can be generated based on context
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    dynamic_chain = "dynamic_#{timestamp}_#{SecureRandom.hex(4)}"

    chain_user.log("Dynamic chain generation",
                   log_chain: dynamic_chain,
                   log_level: "info",
                   metadata: {
                     status: "started",
                     category: "dynamic",
                     data: {
                       chain_id: dynamic_chain,
                       generation_method: "timestamp_based",
                       timestamp: timestamp,
                       note: "Log chain generated dynamically based on timestamp"
                     }
                   })

    # DEMONSTRATION 6: Shared log chain across different models
    # Create an order that shares a log chain with the user
    shared_chain = "shared_workflow_#{SecureRandom.hex(6)}"

    # User action
    chain_user.log("User initiated order creation",
                   log_chain: shared_chain,
                   log_level: "info",
                   metadata: {
                     status: "initiated",
                     category: "user_action",
                     data: {
                       chain_id: shared_chain,
                       action: "order_creation",
                       note: "User action in shared workflow"
                     }
                   })

    # Create order and continue with same chain
    order = chain_user.orders.create!(
      amount: 149.99,
      status: "pending"
    )

    # Order continues the same chain
    order.log_order_event("Order created in shared workflow",
                         log_chain: shared_chain,
                         log_level: "info",
                         metadata: {
                           status: "created",
                           category: "order",
                           data: {
                             chain_id: shared_chain,
                             order_id: order.id,
                             amount: order.amount,
                             note: "Order continues the shared workflow chain"
                           }
                         })

    order.log_order_event("Order processing in shared workflow",
                         log_chain: shared_chain,
                         log_level: "info",
                         metadata: {
                           status: "processing",
                           category: "order",
                           data: {
                             chain_id: shared_chain,
                             processing_stage: "validation",
                             note: "Order processing continues shared chain"
                           }
                         })

    # User completes the shared workflow
    chain_user.log("User completed order workflow",
                   log_chain: shared_chain,
                   log_level: "info",
                   metadata: {
                     status: "completed",
                     category: "user_action",
                     data: {
                       chain_id: shared_chain,
                       final_action: "workflow_completion",
                       order_id: order.id,
                       note: "User completed shared workflow with order"
                     }
                   })
  end
end
