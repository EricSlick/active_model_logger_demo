# ActiveModelLogger Demo

This is a simple Rails application that demonstrates how to use the ActiveModelLogger gem.

## Features

- **User Management**: Create users with logging capabilities
- **Order Processing**: Process orders with detailed logging
- **Log Visualization**: View logs in a web interface
- **Demo Data**: Generate sample data to see logging in action

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

The demo application shows:

- **Statistics**: Count of users, orders, and logs
- **Recent Logs**: A table showing all log entries with:
  - Timestamp
  - Model type (User, Order)
  - Message
  - Log level (info, error, etc.)
  - Visibility level (user, admin)
  - Status and category
  - Structured data

## Demo Actions

- **Create Demo Data**: Generates sample users and orders with various log entries
- **Clear All Logs**: Removes all log entries from the database

## Code Examples

The demo shows several logging patterns:

### Basic Logging
```ruby
user.log("User logged in")
```

### Logging with Metadata
```ruby
user.log("Payment processed",
         log_level: "info",
         metadata: {
           status: "success",
           category: "payment",
           data: {
             amount: 99.99,
             currency: "USD"
           }
         })
```

### Batch Logging
```ruby
user.log_batch([
  { message: "Step 1 completed", status: "success" },
  { message: "Step 2 completed", status: "success" },
  { message: "Process finished", status: "complete" }
])
```

## Models

### User Model
- Includes `ActiveModelLogger::Loggable`
- Configured with `default_visible_to: "user"`
- Has a `log_user_action` helper method

### Order Model
- Includes `ActiveModelLogger::Loggable`
- Configured with `default_visible_to: "admin"`
- Has a `log_order_event` helper method
- Includes a `process_payment!` method that demonstrates logging throughout a process

## Log Structure

All logs are stored in the `active_record_logs` table with:
- `message`: The log message
- `metadata`: JSON field containing:
  - `log_level`: Log level (info, warn, error, etc.)
  - `visible_to`: Who can see this log
  - `status`, `category`, `type`, `title`: Additional metadata
  - `data`: Flexible field for structured data
  - `log_key`: Groups related logs together

## Learn More

This demo is part of the ActiveModelLogger gem. Check out the main gem repository for more information and documentation.
