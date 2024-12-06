require 'json'

class MarketplaceBService
  include HTTParty

  def self.create_inventory(payload)
    handle_with_retries(max_retries: 3, sleep_duration: 2, payload: payload) do
      Rails.logger.info("Creating inventory on Marketplace B: #{payload}")
      
      response = post_inventory(payload)

      handle_response(response, 'inventory creation')
    end
  end

  def self.publish_inventory(inventory_id)
    handle_with_retries(max_retries: 3, sleep_duration: 2, inventory_id: inventory_id) do
      Rails.logger.info("Publishing inventory on Marketplace B: #{inventory_id}")
      
      response = post_publish_inventory(inventory_id)

      handle_response(response, 'inventory publishing')
    end
  end

  private

  def self.handle_with_retries(max_retries:, sleep_duration:, payload: nil, inventory_id: nil)
    Retryable.with_retries(max_retries: max_retries, sleep_duration: sleep_duration, on_exceptions: [StandardError]) do
      yield
    end
  rescue => e
    { status: 'failed', error: e.message }
  end

  def self.post_inventory(payload)
    HTTParty.post(
      'http://localhost:3002/inventory',
      body: payload.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  def self.post_publish_inventory(inventory_id)
    HTTParty.post(
      "http://localhost:3002/inventory/#{inventory_id}/publish",
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  def self.handle_response(response, action)
    if response.success?
      Rails.logger.info("Marketplace B #{action} success: #{response.body}")
      JSON.parse(response.body)
    else
      raise "Marketplace B #{action} failed: #{JSON.parse(response.body)['error']}"
    end
  end
end
