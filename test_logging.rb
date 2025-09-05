#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

puts "Testing ActiveModelLogger gem..."

# Create a user
user = User.create!(
  name: "Test User",
  email: "test@example.com"
)

puts "Created user: #{user.name}"

# Test basic logging
user.log("User created successfully")
puts "✓ Basic logging works"

# Test logging with metadata
user.log("User logged in",
         log_level: "info",
         metadata: {
           status: "success",
           category: "authentication",
           data: {
             ip_address: "192.168.1.1",
             user_agent: "Mozilla/5.0"
           }
         })
puts "✓ Logging with metadata works"

# Test batch logging
user.log_batch([
  { message: "Step 1 completed", status: "success" },
  { message: "Step 2 completed", status: "success" },
  { message: "Process finished", status: "complete" }
])
puts "✓ Batch logging works"

# Create an order
order = user.orders.create!(
  amount: 99.99,
  status: "pending"
)

puts "Created order: $#{order.amount}"

# Test order logging
order.log_order_event("created", {
  amount: order.amount,
  created_by: user.name
})
puts "✓ Order logging works"

# Test payment processing (this will create more logs)
order.process_payment!
puts "✓ Payment processing with logging works"

# Test cached log_chain functionality
puts "\n=== Testing Cached Log Chain Functionality ==="
cached_user = User.create!(name: 'Cached Test User', email: 'cached@example.com')

# First log generates and caches a UUID
log1 = cached_user.log('First log - generates UUID', log_level: 'info', visible_to: 'admin')
puts "✓ First log chain: #{log1.log_chain}"

# Second log uses cached chain
log2 = cached_user.log('Second log - uses cached chain', log_level: 'info', visible_to: 'admin')
puts "✓ Second log chain: #{log2.log_chain} (should match first)"

# Third log uses cached chain
log3 = cached_user.log('Third log - still uses cached chain', log_level: 'warn', visible_to: 'admin')
puts "✓ Third log chain: #{log3.log_chain} (should match first)"

# Fourth log with explicit log_chain breaks cache
log4 = cached_user.log('Fourth log - breaks cache', log_chain: 'explicit_key_123', log_level: 'info', visible_to: 'admin')
puts "✓ Fourth log chain: #{log4.log_chain} (should be explicit_key_123)"

# Fifth log uses new cached chain
log5 = cached_user.log('Fifth log - uses new cached chain', log_level: 'info', visible_to: 'admin')
puts "✓ Fifth log chain: #{log5.log_chain} (should match fourth)"

puts "✓ Cached log_chain functionality works"

# Display all logs
puts "\n=== All Logs ==="
ActiveModelLogger::Log.order(created_at: :desc).each do |log|
  puts "#{log.created_at.strftime('%H:%M:%S')} [#{log.loggable_type}] #{log.message}"
  puts "  Level: #{log.log_level}, Visibility: #{log.visible_to}"
  puts "  Status: #{log.status}, Category: #{log.category}"
  if log.data
    puts "  Data: #{log.data.inspect}"
  end
  puts
end

puts "Total logs created: #{ActiveModelLogger::Log.count}"
puts "Test completed successfully! 🎉"
