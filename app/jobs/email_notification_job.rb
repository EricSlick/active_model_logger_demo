class EmailNotificationJob < ApplicationJob
  def perform(user_id, workflow_id, notification_type)
    @user = User.find(user_id)
    @workflow_id = workflow_id
    @notification_type = notification_type

    ActiveModelLogger::Log.create!(
      loggable: @user,
      message: "Starting email notification job",
      metadata: {
        log_chain: @workflow_id,
        category: "email_notification",
        data: { user_id: @user.id, notification_type: @notification_type, step: 1, total_steps: 3 }
      }
    )

    # Step 1: Prepare email content
    prepare_email_content

    # Step 2: Send email
    send_email

    # Step 3: Log delivery status
    log_delivery_status

    ActiveModelLogger::Log.create!(
      loggable: @user,
      message: "Email notification job completed",
      metadata: {
        log_chain: @workflow_id,
        category: "email_notification",
        data: { user_id: @user.id, notification_type: @notification_type, step: 3, total_steps: 3, status: "completed" }
      }
    )
  end

  private

  def prepare_email_content
    ActiveModelLogger::Log.create!(
      loggable: @user,
      message: "Preparing email content",
      metadata: {
        log_chain: @workflow_id,
        category: "email_preparation",
        data: { user_id: @user.id, notification_type: @notification_type, step: 1 }
      }
    )

    # Simulate email content preparation
    sleep(0.4) # Simulate processing time

    @email_subject = case @notification_type
    when "welcome"
      "Welcome to our service!"
    when "order_confirmation"
      "Your order has been confirmed"
    when "order_shipped"
      "Your order has been shipped"
    else
      "Notification from our service"
    end

    ActiveModelLogger::Log.create!(
      loggable: @user,
      message: "Email content prepared successfully",
      metadata: {
        log_chain: @workflow_id,
        category: "email_preparation",
        data: {
          user_id: @user.id,
          notification_type: @notification_type,
          step: 1,
          result: "success",
          subject: @email_subject
        }
      }
    )
  end

  def send_email
    ActiveModelLogger::Log.create!(
      loggable: @user,
      message: "Sending email to user",
      metadata: {
        log_chain: @workflow_id,
        category: "email_sending",
        data: { user_id: @user.id, email: @user.email, step: 2 }
      }
    )

    # Simulate email sending
    sleep(0.6) # Simulate processing time

    # Simulate email delivery success/failure
    if @user.email.present?
      ActiveModelLogger::Log.create!(
        loggable: @user,
        message: "Email sent successfully",
        metadata: {
          log_chain: @workflow_id,
          category: "email_sending",
          data: {
            user_id: @user.id,
            email: @user.email,
            step: 2,
            result: "success",
            message_id: SecureRandom.hex(12)
          }
        }
      )
    else
      ActiveModelLogger::Log.create!(
        loggable: @user,
        message: "Email sending failed - no email address",
        metadata: {
          log_chain: @workflow_id,
          log_level: "error",
          category: "email_sending",
          data: { user_id: @user.id, step: 2, result: "failed", error: "no_email_address" }
        }
      )
      raise "Email sending failed - no email address"
    end
  end

  def log_delivery_status
    ActiveModelLogger::Log.create!(
      loggable: @user,
      message: "Logging email delivery status",
      metadata: {
        log_chain: @workflow_id,
        category: "email_delivery",
        data: { user_id: @user.id, step: 3 }
      }
    )

    # Simulate delivery status logging
    sleep(0.2) # Simulate processing time

    ActiveModelLogger::Log.create!(
      loggable: @user,
      message: "Email delivery status logged",
      metadata: {
        log_chain: @workflow_id,
        category: "email_delivery",
        data: {
          user_id: @user.id,
          step: 3,
          result: "success",
          delivery_status: "delivered",
          timestamp: Time.current.iso8601
        }
      }
    )
  end
end
