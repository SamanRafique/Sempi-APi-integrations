module Retryable
  def self.with_retries(max_retries: 3, sleep_duration: 2, on_exceptions: [StandardError])
    retries = 0

    begin
      yield # Execute the block
    rescue *on_exceptions => e
      retries += 1
      if retries <= max_retries
        log_retry(retries, e, sleep_duration)
        sleep(sleep_duration)
        retry
      else
        log_max_retries_reached(e)
        raise
      end
    end
  end

  private

  def self.log_retry(retries, error, sleep_duration)
    Rails.logger.warn("Retry #{retries} after error: #{error.message}. Retrying in #{sleep_duration} seconds...")
  end

  def self.log_max_retries_reached(error)
    Rails.logger.error("Max retries reached: #{error.message}")
  end
end
