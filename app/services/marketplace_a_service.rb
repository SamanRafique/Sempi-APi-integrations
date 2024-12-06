require 'httparty'

class MarketplaceAService
  include HTTParty

  def self.post_product(payload)
    Rails.logger.info("Posting product to Marketplace A: #{payload}")

    response = post_to_marketplace_a(payload)
    response.success? ? handle_success_response(response) : handle_error_response(response)
    
  rescue Errno::ECONNREFUSED => e
    handle_connection_error(e)
  end

  private

  def self.post_to_marketplace_a(payload)
    HTTParty.post(
      'http://localhost:3001/api/products', 
      body: payload.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  def self.handle_success_response(response)
    Rails.logger.info("Marketplace A response: #{response.body}")
    JSON.parse(response.body)
  end

  def self.handle_error_response(response)
    Rails.logger.error("Marketplace A error: #{response.body}")
    JSON.parse(response.body)
  end

  def self.handle_connection_error(exception)
    Rails.logger.error("Marketplace A connection failed: #{exception.message}")
    { error: "Connection refused to Marketplace A" }
  end
end
