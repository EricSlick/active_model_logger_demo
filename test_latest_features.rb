#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

puts "Testing Latest ActiveModelLogger Features..."
puts "=" * 50

# Test 1: Enhanced Log Key Management
puts "\n1. Testing Enhanced Log Key Management"
puts "-" * 40

user = User.create!(
  name: "Latest Features Test User",
  email: "latest@example.com"
)

puts "Created user: #{user.name}"

# Start a session (generates new log_chain)
user.start_user_session({
  ip_address: "192.168.1.100",
  user_agent: "Chrome/120.0",
  session_id: SecureRandom.hex(16)
})

puts "✓ Started user session"

# Log session activities (uses cached log_chain)
user.log_session_activity("viewed_profile", { profile_id: user.id })
user.log_session_activity("updated_settings", { settings_updated: ["theme", "notifications"] })
user.log_session_activity("browsed_products", { products_viewed: 5, category: "electronics" })

puts "✓ Logged session activities"

# End session (uses cached log_chain)
user.end_user_session

puts "✓ Ended user session"

# Show session logs
session_logs = user.session_logs
puts "Session logs count: #{session_logs.count}"
session_logs.each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} [#{log.log_level}] #{log.message} (Chain: #{log.log_chain})"
end

# Test 2: Batch Logging
puts "\n2. Testing Batch Logging"
puts "-" * 40

batch_user = User.create!(
  name: "Batch Test User",
  email: "batch@example.com"
)

workflow_steps = [
  { message: "User registration started", level: "info", status: "started", data: { step: 1 } },
  { message: "Email validation completed", level: "info", status: "completed", data: { step: 2, email: batch_user.email } },
  { message: "Profile creation in progress", level: "debug", status: "in_progress", data: { step: 3 } },
  { message: "Preferences configured", level: "info", status: "completed", data: { step: 4, preferences: ["email_notifications", "sms_alerts"] } },
  { message: "Welcome email sent", level: "info", status: "completed", data: { step: 5, email_template: "welcome_v2" } },
  { message: "User onboarding completed", level: "info", status: "completed", data: { step: 6, total_time: "2.5s" } }
]

batch_user.log_user_workflow_steps(workflow_steps)

puts "✓ Batch logged #{workflow_steps.count} workflow steps"

# Test 3: Order Processing Workflow
puts "\n3. Testing Order Processing Workflow"
puts "-" * 40

order = batch_user.orders.create!(
  amount: 199.99,
  status: "pending"
)

# Start order processing
order.start_order_processing
order.log_processing_step("validating_payment", { payment_method: "credit_card" })
order.log_processing_step("checking_inventory", { items: ["laptop", "mouse"] })
order.log_processing_step("preparing_shipment", { warehouse: "warehouse_1" })
order.complete_order_processing

puts "✓ Completed order processing workflow"

# Test batch logging for order lifecycle
order.log_order_lifecycle_events

puts "✓ Batch logged order lifecycle events"

# Test 4: Enhanced Query Methods
puts "\n4. Testing Enhanced Query Methods"
puts "-" * 40

query_user = User.create!(
  name: "Query Test User",
  email: "query@example.com"
)

# Create various types of logs
query_user.log("Debug message", log_level: "debug", metadata: { status: "debug", category: "test" })
query_user.log("Info message", log_level: "info", metadata: { status: "success", category: "test" })
query_user.log("Warning message", log_level: "warn", metadata: { status: "warning", category: "test" })
query_user.log("Error message", log_level: "error", metadata: { status: "error", category: "test" })
query_user.log("Message with data", log_level: "info", metadata: { status: "success", category: "data_test", data: { key: "value" } })

puts "✓ Created test logs"

# Test various query methods
puts "Recent errors: #{query_user.recent_errors.count}"
puts "Info logs: #{query_user.active_model_logs.by_level('info').count}"
puts "Logs with data: #{query_user.active_model_logs.with_data.count}"
puts "Logs by category 'test': #{query_user.logs_by_category('test').count}"
puts "Logs by status 'success': #{query_user.active_model_logs.by_status('success').count}"

# Test 5: Log Cleanup
puts "\n5. Testing Log Cleanup"
puts "-" * 40

cleanup_user = User.create!(
  name: "Cleanup Test User",
  email: "cleanup@example.com"
)

# Create logs with different timestamps (simulate old logs)
(1..10).each do |i|
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
(1..3).each do |i|
  cleanup_user.log("Recent log entry #{i}",
    log_level: "info",
    metadata: {
      status: "completed",
      category: "cleanup_demo",
      data: { day: "recent", created_at: Time.current }
    })
end

puts "✓ Created #{cleanup_user.active_model_logs.count} logs (10 old + 3 recent)"

# Clean up old logs
cleanup_user.cleanup_old_logs

puts "✓ Cleaned up old logs"
puts "Remaining logs: #{cleanup_user.active_model_logs.count}"

# Test 6: Class-level Query Methods
puts "\n6. Testing Class-level Query Methods"
puts "-" * 40

puts "Users with recent logs: #{User.with_recent_logs(since: 1.hour.ago).count}"
puts "Users with error logs: #{User.joins(:active_model_logs).where(active_model_logs: { id: ActiveModelLogger::Log.by_level('error').select(:id) }).distinct.count}"

# Test 7: Advanced Metadata Support
puts "\n7. Testing Advanced Metadata Support"
puts "-" * 40

advanced_user = User.create!(
  name: "Advanced Test User",
  email: "advanced@example.com"
)

advanced_user.log("Complex operation completed",
  log_level: "info",
  metadata: {
    status: "success",
    category: "data_processing",
    data: {
      records_processed: 1000,
      processing_time: "2.5s",
      errors: 0,
      warnings: 2,
      memory_usage: "256MB",
      cpu_usage: "15%"
    }
  })

puts "✓ Created log with advanced metadata"

# Display all logs
puts "\n=== All Logs Summary ==="
ActiveModelLogger::Log.order(created_at: :desc).limit(10).each do |log|
  puts "#{log.created_at.strftime('%H:%M:%S')} [#{log.loggable_type}] #{log.message}"
  puts "  Level: #{log.log_level}, Visibility: #{log.visible_to}, Status: #{log.status}, Category: #{log.category}"
  if log.data
    puts "  Data: #{log.data.inspect}"
  end
  puts
end

puts "Total logs created: #{ActiveModelLogger::Log.count}"
puts "Latest features test completed successfully! 🎉"
