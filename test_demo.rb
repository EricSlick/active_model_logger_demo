# Test the updated nested keys demo
ActiveModelLogger::Log.delete_all

# Create the demo data
user = User.create!(name: 'Nested Keys Demo User', email: 'nested@example.com')

# Create logs with deeply nested structures using raw SQL to ensure proper storage
ActiveRecord::Base.connection.execute("INSERT INTO active_model_logs (loggable_type, loggable_id, message, metadata, created_at, updated_at) VALUES ('User', #{user.id}, 'User settings updated', '{\"status\":\"success\",\"category\":\"settings\",\"settings\":{\"notifications\":{\"email\":true,\"sms\":false,\"push\":true},\"privacy\":{\"public\":false,\"share_data\":false},\"preferences\":{\"theme\":\"dark\",\"language\":\"en\"}}}', datetime('now'), datetime('now'))")

ActiveRecord::Base.connection.execute("INSERT INTO active_model_logs (loggable_type, loggable_id, message, metadata, created_at, updated_at) VALUES ('User', #{user.id}, 'User profile created', '{\"status\":\"success\",\"category\":\"profile\",\"user\":{\"profile\":{\"personal\":{\"name\":\"John Doe\",\"age\":30,\"city\":\"New York\"},\"contact\":{\"email\":\"john@example.com\",\"phone\":\"+1234567890\"},\"preferences\":{\"newsletter\":true,\"marketing\":false}}}}', datetime('now'), datetime('now'))")

# Test the with_keys scope
puts 'Total logs: ' + ActiveModelLogger::Log.count.to_s
puts 'Logs with email key: ' + ActiveModelLogger::Log.with_keys('email').count.to_s
puts 'Logs with theme key: ' + ActiveModelLogger::Log.with_keys('theme').count.to_s
puts 'Logs with enabled key: ' + ActiveModelLogger::Log.with_keys('enabled').count.to_s
puts 'Logs with both email and sms: ' + ActiveModelLogger::Log.with_keys('email', 'sms').count.to_s
