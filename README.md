# ActiveModelLogger Demo

This is a comprehensive Rails 8.x application that demonstrates the advanced features of the ActiveModelLogger gem v0.2.0+ with **Mission Control Jobs** integration for complete observability.

## 🚀 Features

- **Enhanced Logging**: Advanced logging with log chains, batch operations, and block logging
- **Multi-Job Workflow**: Complex background job orchestration with cross-job traceability
- **Job Monitoring**: Real-time job monitoring with Mission Control Jobs dashboard
- **User Management**: Create users with comprehensive logging capabilities
- **Order Processing**: Process orders with detailed workflow logging
- **Interactive Demos**: Multiple demo actions showcasing different logging patterns
- **Log Visualization**: Rich web interface with statistics and log browsing
- **Query Scopes**: Advanced querying capabilities for log analysis
- **Performance Testing**: Built-in performance benchmarks
- **Log Chain Management**: Grouped log viewing with expandable/collapsible interface

## 🛠 Getting Started

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

5. **Access Job Dashboard** (Optional):
   - Click "View Jobs Dashboard" button
   - Monitor running jobs in real-time
   - No authentication required in development

## 📊 What You'll See

The demo application provides:

- **Statistics Dashboard**: Count of users, orders, logs by level, and key-based queries
- **Interactive Demos**: Multiple demo buttons showcasing different logging patterns
- **Recent Logs Table**: Comprehensive view of all log entries with:
  - Timestamp and model information
  - Message and log level
  - Log chain (groups related logs) - truncated display with hover for full value
  - Visibility, status, and category
  - Structured metadata and data
- **Job Monitoring**: Real-time view of background job execution
- **Log Chain Visualization**: Grouped log chains with expandable details

## 🎯 Demo Actions

### Core Demos
- **Create Demo Data**: Generates comprehensive sample data with various log patterns
- **Session Workflow Demo**: Demonstrates log chain management across user sessions
- **Batch Logging Demo**: Shows efficient bulk logging operations
- **Block Logging Demo**: Demonstrates automatic start/end logging with error handling
- **Cleanup Demo**: Shows log cleanup and maintenance operations

### Advanced Demos
- **Nested Keys Demo**: Demonstrates enhanced `with_keys` scope with nested searching
- **Log Chain Demo**: View and create log chains with grouped visualization
- **Multi-Job Workflow Demo**: **NEW!** Complex background job orchestration
- **Clear All Logs**: Removes all log entries from the database
- **Cleanup Old Logs**: Removes logs older than 7 days
- **Clear All Users**: Removes users and their associated logs
- **Clear All Orders**: Removes orders and their associated logs

## 🔄 Multi-Job Workflow Demo

The **Multi-Job Workflow Demo** showcases complex background job orchestration with cross-job traceability:

### Workflow Overview
1. **OrderProcessingJob**: Validates order, processes payment, updates inventory, sends confirmation
2. **EmailNotificationJob**: Prepares email, sends notification, tracks delivery status
3. **InventoryManagementJob**: Checks availability, manages inventory, updates records

### Key Features
- **Shared Log Chain**: All jobs use the same `workflow_id` for complete traceability
- **Structured Logging**: Each job logs detailed steps with metadata
- **Cross-Job Visibility**: Track the entire workflow from start to finish
- **Real-time Monitoring**: Watch jobs execute in the Mission Control Jobs dashboard

### Code Example
```ruby
# Generate unique workflow ID for cross-job logging
workflow_id = SecureRandom.uuid

# Log workflow start
user.log("Starting multi-job workflow",
         log_chain: workflow_id,
         category: "workflow_demo",
         data: { workflow_id: workflow_id, total_jobs: 3 })

# Queue jobs with same log_chain
OrderProcessingJob.perform_later(order.id, workflow_id)
EmailNotificationJob.perform_later(user.id, workflow_id, "order_confirmation")
InventoryManagementJob.perform_later(order.id, workflow_id, "reserve")

# Each job logs with the same log_chain for traceability
class OrderProcessingJob < ApplicationJob
  def perform(order_id, workflow_id)
    ActiveModelLogger::Log.create!(
      loggable: @order,
      message: "Starting order processing workflow",
      metadata: {
        log_chain: workflow_id,
        category: "order_processing",
        data: { order_id: @order.id, step: 1, total_steps: 4 }
      }
    )
    # ... processing steps ...
  end
end
```

## 📋 ActiveModelLogger v0.2.0+ Features

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

## 🏗 Models

### User Model
- Includes `ActiveModelLogger::Loggable`
- Configured with `auto_log_chain: true` for automatic chain generation
- **Automatic Log Cleanup**: `dependent: :destroy` ensures logs are deleted when user is deleted
- Methods:
  - `log_user_workflow_steps`: Batch logging for user workflows
  - `start_user_session`, `log_session_activity`, `end_user_session`: Session management
  - `cleanup_old_logs`: Log maintenance
  - `recent_errors`, `logs_by_category`, `session_logs`: Query methods

### Order Model
- Includes `ActiveModelLogger::Loggable`
- Configured with `auto_log_chain: true` for automatic chain generation
- **Automatic Log Cleanup**: `dependent: :destroy` ensures logs are deleted when order is deleted
- Methods:
  - `start_order_processing`, `log_processing_step`, `complete_order_processing`: Workflow management
  - `log_order_lifecycle_events`: Batch lifecycle logging
  - `processing_logs`, `error_logs`, `recent_activity`: Query methods
  - `cleanup_order_logs`: Log maintenance

## 📊 Log Structure

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

## 🔧 Mission Control Jobs Integration

### Job Monitoring Dashboard
- **Real-time Monitoring**: Watch jobs execute in real-time
- **Queue Management**: Monitor different job queues and their status
- **Job Details**: View detailed information about individual jobs
- **Performance Metrics**: Track job execution times and success rates
- **Error Handling**: Monitor failed jobs and their error messages

### Accessing the Dashboard
1. Click "View Jobs Dashboard" button on the main page
2. No authentication required in development
3. Monitor the Multi-Job Workflow Demo in real-time
4. View job parameters, execution times, and error details

### Job Configuration
- **Queue Adapter**: Uses `:async` adapter for proper job processing
- **Authentication**: Disabled in development for ease of use
- **Integration**: Perfect complement to ActiveModelLogger for complete observability

## ⚡ Performance Features

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

### Job Processing
- Asynchronous job execution
- Real-time job monitoring
- Efficient queue management

## 🧪 Testing Scripts

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

## 🚀 Rails 8.x Compatibility

This demo is built with Rails 8.0.2.1 and includes:
- Propshaft asset pipeline
- Turbo and Stimulus integration
- Modern Rails 8.x features
- Compatible with Ruby 3.3.1
- Mission Control Jobs integration
- Solid Queue for job processing

## 🎯 Complete Observability Solution

This demo showcases a complete observability solution combining:

### ActiveModelLogger
- **Structured Logging**: Rich metadata and categorization
- **Performance**: Efficient batch operations and querying
- **Flexibility**: Multiple logging patterns and query options
- **Integration**: Seamless ActiveRecord integration
- **Maintenance**: Built-in cleanup and management tools

### Mission Control Jobs
- **Job Monitoring**: Real-time job execution tracking
- **Queue Management**: Monitor job queues and performance
- **Error Tracking**: Detailed error information and debugging
- **Performance Metrics**: Execution times and success rates

### Together
- **End-to-End Visibility**: Complete traceability from web requests to background jobs
- **Cross-System Logging**: Shared log chains across different systems
- **Real-time Monitoring**: Watch complex workflows execute in real-time
- **Comprehensive Debugging**: Detailed logs and job execution information

## 📚 Learn More

This demo showcases the full capabilities of ActiveModelLogger v0.2.0+ combined with Mission Control Jobs for complete observability. The combination provides:

- **Structured Logging**: Rich metadata and categorization
- **Performance**: Efficient batch operations and querying
- **Flexibility**: Multiple logging patterns and query options
- **Integration**: Seamless ActiveRecord integration
- **Maintenance**: Built-in cleanup and management tools
- **Job Monitoring**: Real-time background job tracking
- **Complete Observability**: End-to-end visibility into complex workflows

For more information, check out the main ActiveModelLogger gem repository and Mission Control Jobs documentation.
