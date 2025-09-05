#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

puts "Testing ActiveModelLogger scopes..."

# Create a user
user = User.create!(
  name: "Scope Test User",
  email: "scope@example.com"
)

puts "Created user: #{user.name}"

# Create various types of logs
user.log("Debug message", log_level: "debug", metadata: { status: "debug", category: "test" })
user.log("Info message", log_level: "info", metadata: { status: "success", category: "test" })
user.log("Warning message", log_level: "warn", metadata: { status: "warning", category: "test" })
user.log("Error message", log_level: "error", metadata: { status: "error", category: "test" })
user.log("Message with data", log_level: "info", metadata: { status: "success", category: "data_test", data: { key: "value" } })

puts "Created 5 test logs"

# Test scopes
puts "\n=== Testing Scopes ==="

puts "Recent logs (3):"
user.active_record_logs.recent(3).each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} [#{log.log_level}] #{log.message}"
end

puts "\nError logs:"
user.active_record_logs.error_logs.each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} #{log.message}"
end

puts "\nInfo logs:"
user.active_record_logs.info_logs.each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} #{log.message}"
end

puts "\nLogs with data:"
user.active_record_logs.with_data.each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} #{log.message} - Data: #{log.data}"
end

puts "\nLogs by category 'test':"
user.active_record_logs.by_category('test').each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} [#{log.category}] #{log.message}"
end

puts "\nLogs by status 'success':"
user.active_record_logs.by_status('success').each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} [#{log.status}] #{log.message}"
end

puts "\nCounts:"
puts "  Total logs: #{user.active_record_logs.count}"
puts "  Error logs: #{user.active_record_logs.by_level('error').count}"
puts "  Info logs: #{user.active_record_logs.by_level('info').count}"
puts "  Success status: #{user.active_record_logs.by_status('success').count}"
puts "  Test category: #{user.active_record_logs.by_category('test').count}"

# Test time range
puts "\nLogs in last 5 minutes:"
user.active_record_logs.in_range(5.minutes.ago, Time.current).each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} #{log.message}"
end

puts "\n=== Direct Log Model Scopes ==="

# Test direct Log model scopes
puts "All error logs in system:"
ActiveModelLogger::Log.error_logs.each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} [#{log.loggable_type}] #{log.message}"
end

puts "Recent logs across all models:"
ActiveModelLogger::Log.recent(5).each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} [#{log.loggable_type}] #{log.message}"
end

puts "\nScope testing completed successfully! 🎉"
