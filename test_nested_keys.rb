# Clear existing logs
ActiveModelLogger::Log.delete_all

# Create a user
user = User.create!(name: 'Nested Test User', email: 'nested@example.com')

# Create logs with nested structures using raw SQL to ensure proper storage
ActiveRecord::Base.connection.execute("INSERT INTO active_model_logs (loggable_type, loggable_id, message, metadata, created_at, updated_at) VALUES ('User', #{user.id}, 'Settings updated', '{\"status\":\"success\",\"category\":\"settings\",\"settings\":{\"notifications\":{\"email\":true,\"sms\":false},\"preferences\":{\"theme\":\"dark\"}}}', datetime('now'), datetime('now'))")

ActiveRecord::Base.connection.execute("INSERT INTO active_model_logs (loggable_type, loggable_id, message, metadata, created_at, updated_at) VALUES ('User', #{user.id}, 'Profile created', '{\"status\":\"success\",\"category\":\"profile\",\"user\":{\"profile\":{\"contact\":{\"email\":\"user@example.com\"}}}}', datetime('now'), datetime('now'))")

# Test the with_keys scope
puts 'Total logs: ' + ActiveModelLogger::Log.count.to_s
puts 'Logs with email key: ' + ActiveModelLogger::Log.with_keys('email').count.to_s
puts 'Logs with theme key: ' + ActiveModelLogger::Log.with_keys('theme').count.to_s
puts 'Logs with both email and sms: ' + ActiveModelLogger::Log.with_keys('email', 'sms').count.to_s

# Show the actual metadata
ActiveModelLogger::Log.all.each do |log|
  puts 'Log: ' + log.message + ' - Metadata: ' + log.metadata.to_json
end
