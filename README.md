# ActiveModelLogger Demo

This is a comprehensive Rails 8.x application that demonstrates the advanced features of the ActiveModelLogger gem v0.2.0+.

## Features

- **Enhanced Logging**: Advanced logging with log chains, batch operations, and block logging
- **User Management**: Create users with comprehensive logging capabilities
- **Order Processing**: Process orders with detailed workflow logging
- **Interactive Demos**: Multiple demo actions showcasing different logging patterns
- **Log Visualization**: Rich web interface with statistics and log browsing
- **Query Scopes**: Advanced querying capabilities for log analysis
- **Performance Testing**: Built-in performance benchmarks

## Getting Started

1. **Install Dependencies**:
   ```bash
   bundle install
   ```

2. **Setup Database**:
   ```bash
   rails db:migrate
   ```

3. **Start the Server**:
   ```bash
   rails server
   ```

4. **Visit the Application**:
   Open your browser to `http://localhost:3000`

## What You'll See

The demo application provides:

- **Statistics Dashboard**: Count of users, orders, logs by level, and key-based queries
- **Interactive Demos**: Multiple demo buttons showcasing different logging patterns
- **Recent Logs Table**: Comprehensive view of all log entries with:
  - Timestamp and model information
  - Message and log level
  - Log chain (groups related logs)
  - Visibility, status, and category
  - Structured metadata and data

## Demo Actions

### Core Demos
- **Create Demo Data**: Generates comprehensive sample data with various log patterns
- **Session Workflow Demo**: Demonstrates log chain management across user sessions
- **Batch Logging Demo**: Shows efficient bulk logging operations
- **Block Logging Demo**: Demonstrates automatic start/end logging with error handling
- **Cleanup Demo**: Shows log cleanup and maintenance operations

### Advanced Demos
- **Nested Keys Demo**: Demonstrates enhanced `with_keys` scope with nested searching
- **Clear All Logs**: Removes all log entries from the database
- **Cleanup Old Logs**: Removes logs older than 7 days

## ActiveModelLogger v0.2.0+ Features

### Log Chains
Log chains group related log entries together using UUIDs:

```ruby
# Automatic log chain generation
user.log("Session started", log_chain: "user_session_123")
user.log("Action performed", log_chain: "user_session_123")  # Same chain
user.log("Session ended", log_chain: "user_session_123")     # Same chain
```

### Batch Logging
Efficiently log multiple entries at once:

```ruby
user.log_batch([
  { message: "Step 1 completed", status: "success", category: "workflow" },
  { message: "Step 2 completed", status: "success", category: "workflow" },
  { message: "Process finished", status: "complete", category: "workflow" }
], log_chain: "batch_process_456")
```

### Block Logging
Automatic start/end logging with error handling:

```ruby
user.log_block("Complex operation") do |log|
  # Your code here
  log.update(metadata: { progress: 50 })
  # More code
  log.update(metadata: { progress: 100, status: "complete" })
end
```

### Enhanced Query Scopes

#### Basic Scopes
```ruby
ActiveModelLogger::Log.info_logs
ActiveModelLogger::Log.error_logs
ActiveModelLogger::Log.debug_logs
ActiveModelLogger::Log.by_category("payment")
ActiveModelLogger::Log.visible_to("admin")
```

#### Advanced Scopes
```ruby
# Find logs with specific keys (including nested)
ActiveModelLogger::Log.with_keys("email")        # Finds email at any nesting level
ActiveModelLogger::Log.with_keys("enabled")      # Finds enabled in deeply nested config
ActiveModelLogger::Log.with_keys("email", "sms") # Finds logs with both keys

# Examples of nested structures that would be found:
# {"settings": {"notifications": {"email": true, "sms": false}}}
# {"user": {"profile": {"contact": {"email": "user@example.com"}}}}
# {"config": {"cache": {"redis": {"enabled": true}}}}
```

#### Log Chain Queries
```ruby
# Find all logs in a specific chain
ActiveModelLogger::Log.with_log_chain("user_session_123")

# Find logs for a specific model instance
user.logs(log_chain: "user_session_123")
order.logs(log_chain: "order_processing_789")
```

## Models

### User Model
- Includes `ActiveModelLogger::Loggable`
- Configured with `auto_log_chain: true` for automatic chain generation
- Methods:
  - `log_user_workflow_steps`: Batch logging for user workflows
  - `start_user_session`, `log_session_activity`, `end_user_session`: Session management
  - `cleanup_old_logs`: Log maintenance
  - `recent_errors`, `logs_by_category`, `session_logs`: Query methods

### Order Model
- Includes `ActiveModelLogger::Loggable`
- Configured with `auto_log_chain: true` for automatic chain generation
- Methods:
  - `start_order_processing`, `log_processing_step`, `complete_order_processing`: Workflow management
  - `log_order_lifecycle_events`: Batch lifecycle logging
  - `processing_logs`, `error_logs`, `recent_activity`: Query methods
  - `cleanup_order_logs`: Log maintenance

## Log Structure

All logs are stored in the `active_model_logs` table with:

### Core Fields
- `message`: The log message
- `loggable_type` and `loggable_id`: Associated model
- `created_at` and `updated_at`: Timestamps

### Metadata JSON Field
The `metadata` field contains structured data:
- `log_chain`: UUID grouping related logs
- `log_level`: Log level (info, warn, error, debug)
- `visible_to`: Who can see this log (user, admin, system)
- `status`: Status of the operation (success, error, pending, etc.)
- `category`: Category for organization (user_action, order, payment, etc.)
- `type` and `title`: Additional classification fields
- `data`: Flexible field for structured data

### Database Structure
The `active_model_logs` table is managed by the `active_model_logger` gem and contains:
- `loggable_type` and `loggable_id`: Associated model reference
- `message`: The log message text
- `metadata`: JSON field containing all structured data
- `created_at` and `updated_at`: Timestamps

All additional fields (`log_chain`, `log_level`, `status`, `category`, `visible_to`, etc.) are stored within the `metadata` JSON field for maximum flexibility.

## Performance Features

### Batch Operations
- `log_batch`: Efficient bulk logging
- Bulk insert operations for better performance
- Reduced database round trips

### Query Optimization
- Indexed columns for fast filtering
- JSON field queries with proper indexing
- Efficient scopes for common queries

### Memory Management
- Automatic log cleanup methods
- Configurable retention periods
- Memory-efficient batch operations

## Testing Scripts

The project includes comprehensive testing scripts:

### `test_latest_features.rb`
- Demonstrates all v0.2.0+ features
- Shows log chain management
- Tests batch and block logging
- Validates query scopes

### `test_performance_benchmarks.rb`
- Performance testing for logging operations
- Memory usage analysis
- Concurrent logging tests
- Query performance benchmarks

## Rails 8.x Compatibility

This demo is built with Rails 8.0.2.1 and includes:
- Propshaft asset pipeline
- Turbo and Stimulus integration
- Modern Rails 8.x features
- Compatible with Ruby 3.3.1

## Learn More

This demo showcases the full capabilities of ActiveModelLogger v0.2.0+. The gem provides:

- **Structured Logging**: Rich metadata and categorization
- **Performance**: Efficient batch operations and querying
- **Flexibility**: Multiple logging patterns and query options
- **Integration**: Seamless ActiveRecord integration
- **Maintenance**: Built-in cleanup and management tools

For more information, check out the main ActiveModelLogger gem repository.
