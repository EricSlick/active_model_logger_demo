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

# Add logs with deeply nested structures
user.log("User settings updated", log_level: "info",
         metadata: {
           status: "success",
           category: "settings",
           settings: {
             notifications: { email: true, sms: false, push: true },
             privacy: { public: false, share_data: false },
             preferences: { theme: "dark", language: "en" }
           }
         })

user.log("User profile created", log_level: "info",
         metadata: {
           status: "success",
           category: "profile",
           user: {
             profile: {
               personal: { name: "John Doe", age: 30, city: "New York" },
               contact: { email: "john@example.com", phone: "+1234567890" },
               preferences: { newsletter: true, marketing: false }
             }
           }
         })

user.log("System configuration", log_level: "info",
         metadata: {
           status: "completed",
           category: "config",
           config: {
             database: { host: "localhost", port: 5432, ssl: true },
             cache: { redis: { enabled: true, ttl: 3600 }, memcached: { enabled: false } },
             features: { beta: { enabled: true, users: [ "admin" ] } }
           }
         })

puts "Created 8 test logs (including nested structures)"

# Test scopes
puts "\n=== Testing Scopes ==="

puts "Recent logs (3):"
user.active_model_logs.newest(3).each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} [#{log.log_level}] #{log.message}"
end

puts "\nError logs:"
user.active_model_logs.error_logs.each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} #{log.message}"
end

puts "\nInfo logs:"
user.active_model_logs.info_logs.each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} #{log.message}"
end

puts "\nLogs with data:"
user.active_model_logs.with_data.each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} #{log.message} - Data: #{log.data}"
end

puts "\nLogs by category 'test':"
user.active_model_logs.by_category('test').each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} [#{log.category}] #{log.message}"
end

puts "\nLogs by status 'success':"
user.active_model_logs.by_status('success').each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} [#{log.status}] #{log.message}"
end

# Test with_keys scope
puts "\nLogs with 'status' key:"
user.active_model_logs.with_keys('status').each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} #{log.message} - Status: #{log.status}"
end

puts "\nLogs with 'category' key:"
user.active_model_logs.with_keys('category').each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} #{log.message} - Category: #{log.category}"
end

puts "\nLogs with both 'status' and 'category' keys:"
user.active_model_logs.with_keys('status', 'category').each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} #{log.message} - Status: #{log.status}, Category: #{log.category}"
end

# Test nested key searching
puts "\n=== Testing Nested Key Searching ==="

puts "\nLogs with 'email' key (anywhere in metadata):"
user.active_model_logs.with_keys('email').each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} #{log.message}"
end

puts "\nLogs with 'enabled' key (deeply nested):"
user.active_model_logs.with_keys('enabled').each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} #{log.message}"
end

puts "\nLogs with 'name' key (nested in user profile):"
user.active_model_logs.with_keys('name').each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} #{log.message}"
end

puts "\nLogs with 'theme' key (nested in settings):"
user.active_model_logs.with_keys('theme').each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} #{log.message}"
end

puts "\nLogs with both 'email' and 'sms' keys (same nested structure):"
user.active_model_logs.with_keys('email', 'sms').each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} #{log.message}"
end

puts "\nCounts:"
puts "  Total logs: #{user.active_model_logs.count}"
puts "  Error logs: #{user.active_model_logs.by_level('error').count}"
puts "  Info logs: #{user.active_model_logs.by_level('info').count}"
puts "  Success status: #{user.active_model_logs.by_status('success').count}"
puts "  Test category: #{user.active_model_logs.by_category('test').count}"
puts "  Logs with 'status' key: #{user.active_model_logs.with_keys('status').count}"
puts "  Logs with 'category' key: #{user.active_model_logs.with_keys('category').count}"
puts "  Logs with both keys: #{user.active_model_logs.with_keys('status', 'category').count}"
puts "\nNested Key Counts:"
puts "  Logs with 'email' key: #{user.active_model_logs.with_keys('email').count}"
puts "  Logs with 'enabled' key: #{user.active_model_logs.with_keys('enabled').count}"
puts "  Logs with 'name' key: #{user.active_model_logs.with_keys('name').count}"
puts "  Logs with 'theme' key: #{user.active_model_logs.with_keys('theme').count}"
puts "  Logs with 'email' and 'sms': #{user.active_model_logs.with_keys('email', 'sms').count}"

# Test time range
puts "\nLogs in last 5 minutes:"
user.active_model_logs.in_range(5.minutes.ago, Time.current).each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} #{log.message}"
end

puts "\n=== Direct Log Model Scopes ==="

# Test direct Log model scopes
puts "All error logs in system:"
ActiveModelLogger::Log.error_logs.each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} [#{log.loggable_type}] #{log.message}"
end

puts "Recent logs across all models:"
ActiveModelLogger::Log.newest(5).each do |log|
  puts "  #{log.created_at.strftime('%H:%M:%S')} [#{log.loggable_type}] #{log.message}"
end

puts "\nScope testing completed successfully! 🎉"
