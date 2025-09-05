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
    create_cached_log_key_demo
    redirect_to root_path, notice: "Demo data created successfully!"
  end

  def clear_logs
    ActiveModelLogger::Log.delete_all
    redirect_to root_path, notice: "All logs cleared!"
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

  def create_cached_log_key_demo
    # Create a user specifically for demonstrating cached log_key behavior
    demo_user = User.create!(
      name: "Cached Log Demo User",
      email: "cached_demo@example.com"
    )

    # Demonstrate cached log_key behavior
    # First log generates and caches a UUID
    demo_user.log("First log - generates UUID", log_level: "info", visible_to: "admin")

    # Second log uses cached key (no explicit log_key)
    demo_user.log("Second log - uses cached key", log_level: "info", visible_to: "admin")

    # Third log uses cached key (no explicit log_key)
    demo_user.log("Third log - still uses cached key", log_level: "warn", visible_to: "admin")

    # Fourth log with explicit log_chain breaks the cache
    demo_user.log("Fourth log - breaks cache with new key",
                  log_chain: "explicit_key_123",
                  log_level: "info",
                  visible_to: "admin")

    # Fifth log uses the new cached key
    demo_user.log("Fifth log - uses new cached key", log_level: "info", visible_to: "admin")

    # Sixth log uses the new cached key
    demo_user.log("Sixth log - still uses new cached key", log_level: "error", visible_to: "admin")

    # Seventh log with another explicit log_chain breaks cache again
    demo_user.log("Seventh log - breaks cache again",
                  log_chain: "another_key_456",
                  log_level: "info",
                  visible_to: "admin")

    # Eighth log uses the latest cached key
    demo_user.log("Eighth log - uses latest cached key", log_level: "info", visible_to: "admin")
  end
end
