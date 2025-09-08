#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

puts "Testing ActiveModelLogger Performance Benchmarks..."
puts "=" * 50

# Test 1: Batch vs Individual Logging Performance
puts "\n1. Testing Batch vs Individual Logging Performance"
puts "-" * 40

user = User.create!(
  name: "Performance Test User",
  email: "performance@example.com"
)

# Test individual logging
puts "Testing individual logging..."

individual_start = Time.current
(1..100).each do |i|
  user.log("Individual log #{i}",
    log_level: "info",
    metadata: {
      status: "success",
      category: "performance_test",
      data: { iteration: i }
    })
end
individual_time = Time.current - individual_start

puts "Individual logging: #{individual_time.round(4)}s for 100 logs"

# Test batch logging
puts "Testing batch logging..."

batch_start = Time.current
log_entries = (1..100).map do |i|
  {
    message: "Batch log #{i}",
    level: "info",
    metadata: {
      status: "success",
      category: "performance_test",
      data: { iteration: i }
    }
  }
end
user.log_user_workflow_steps(log_entries)
batch_time = Time.current - batch_start

puts "Batch logging: #{batch_time.round(4)}s for 100 logs"
puts "Performance improvement: #{(individual_time / batch_time).round(2)}x faster"

# Test 2: Query Performance
puts "\n2. Testing Query Performance"
puts "-" * 40

# Create a user with many logs
query_user = User.create!(
  name: "Query Performance User",
  email: "query_perf@example.com"
)

# Create logs with different categories and levels
categories = ["auth", "payment", "order", "session", "error"]
levels = ["debug", "info", "warn", "error"]

(1..200).each do |i|
  query_user.log("Performance test log #{i}",
    log_level: levels.sample,
    metadata: {
      status: ["success", "failed", "pending"].sample,
      category: categories.sample,
      data: { iteration: i, random_data: SecureRandom.hex(8) }
    })
end

puts "Created 200 test logs"

# Test various query methods
queries = [
  { name: "Recent logs (10)", method: -> { query_user.recent_logs(10).count } },
  { name: "Error logs", method: -> { query_user.error_logs.count } },
  { name: "Info logs", method: -> { query_user.info_logs.count } },
  { name: "Logs with data", method: -> { query_user.logs_with_data.count } },
  { name: "Logs by category 'auth'", method: -> { query_user.logs_by_category('auth').count } },
  { name: "Logs by status 'success'", method: -> { query_user.logs_by_status('success').count } },
  { name: "Logs in last hour", method: -> { query_user.logs_in_range(1.hour.ago, Time.current).count } }
]

queries.each do |query|
  start_time = Time.current
  result = query[:method].call
  query_time = Time.current - start_time
  puts "#{query[:name]}: #{result} results in #{query_time.round(4)}s"
end

# Test 3: Log Cleanup Performance
puts "\n3. Testing Log Cleanup Performance"
puts "-" * 40

cleanup_user = User.create!(
  name: "Cleanup Performance User",
  email: "cleanup_perf@example.com"
)

# Create logs with different timestamps
(1..50).each do |i|
  log_time = i.days.ago

  cleanup_user.log("Old log #{i}",
    log_level: "info",
    metadata: {
      status: "completed",
      category: "cleanup_test",
      data: { day: i, created_at: log_time }
    })
end

# Create recent logs
(1..20).each do |i|
  cleanup_user.log("Recent log #{i}",
    log_level: "info",
    metadata: {
      status: "completed",
      category: "cleanup_test",
      data: { day: "recent", created_at: Time.current }
    })
end

puts "Created 70 logs (50 old + 20 recent)"

# Test cleanup performance
cleanup_start = Time.current
cleanup_user.cleanup_old_logs
cleanup_time = Time.current - cleanup_start

puts "Cleanup completed in #{cleanup_time.round(4)}s"
puts "Remaining logs: #{cleanup_user.logs_count}"

# Test 4: Memory Usage with Large Data
puts "\n4. Testing Memory Usage with Large Data"
puts "-" * 40

memory_user = User.create!(
  name: "Memory Test User",
  email: "memory@example.com"
)

# Create logs with large data payloads
(1..50).each do |i|
  large_data = {
    iteration: i,
    large_string: "x" * 1000,
    nested_data: {
      level1: {
        level2: {
          level3: {
            data: SecureRandom.hex(100)
          }
        }
      }
    },
    array_data: (1..100).map { |j| { id: j, value: SecureRandom.hex(20) } }
  }

  memory_user.log("Memory test log #{i}",
    log_level: "info",
    metadata: {
      status: "success",
      category: "memory_test",
      data: large_data
    })
end

puts "Created 50 logs with large data payloads"
puts "Logs with data: #{memory_user.logs_with_data.count}"

# Test 5: Concurrent Logging
puts "\n5. Testing Concurrent Logging"
puts "-" * 40

concurrent_user = User.create!(
  name: "Concurrent Test User",
  email: "concurrent@example.com"
)

# Simulate concurrent logging
threads = []
concurrent_start = Time.current

(1..10).each do |thread_id|
  threads << Thread.new do
    (1..10).each do |i|
      concurrent_user.log("Concurrent log from thread #{thread_id}, iteration #{i}",
        log_level: "info",
        metadata: {
          status: "success",
          category: "concurrent_test",
          data: { thread_id: thread_id, iteration: i }
        })
    end
  end
end

threads.each(&:join)
concurrent_time = Time.current - concurrent_start

puts "Concurrent logging: #{concurrent_time.round(4)}s for 100 logs across 10 threads"
puts "Total logs created: #{concurrent_user.logs_count}"

# Test 6: Database Query Optimization
puts "\n6. Testing Database Query Optimization"
puts "-" * 40

# Test scopes performance
scope_tests = [
  { name: "All error logs", method: -> { ActiveModelLogger::Log.error_logs.count } },
  { name: "All info logs", method: -> { ActiveModelLogger::Log.info_logs.count } },
  { name: "Recent logs (20)", method: -> { ActiveModelLogger::Log.recent(20).count } },
  { name: "Logs with data", method: -> { ActiveModelLogger::Log.with_data.count } },
  { name: "Logs by status 'success'", method: -> { ActiveModelLogger::Log.by_status('success').count } }
]

scope_tests.each do |test|
  start_time = Time.current
  result = test[:method].call
  query_time = Time.current - start_time
  puts "#{test[:name]}: #{result} results in #{query_time.round(4)}s"
end

puts "\nPerformance benchmarking completed successfully! 🚀"
puts "Total logs in database: #{ActiveModelLogger::Log.count}"
