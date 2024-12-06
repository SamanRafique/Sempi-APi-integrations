# Sempi-APi-integrations

# Overview
This application interacts with two external marketplace APIs (Marketplace A and Marketplace B) to create and publish products to them. The system posts product data to both marketplaces, handles failures and retries, and returns a combined response indicating success or failure for each marketplace.


# Approach
1. **Service-Oriented Architecture**:
  Marketplace A: Handles product creation with the **/api/products endpoint**. The system sends product data to this endpoint and expects a response indicating success.
  Marketplace B: Handles inventory creation and publishing via two endpoints: **/inventory** (for creating inventory) and **/inventory/:id/publish** (for publishing the inventory). This system retries failed requests up to 3 times with a sleep duration between retries.
2. **Retry Mechanism:** For any failure in communicating with Marketplace B, the system retries the request up to **3 times**. This ensures resilience in case of transient errors (e.g., network issues or temporary server downtime).
3. **Input Validation:**
The product parameters (name, price, and sku) are validated before making any requests to the external APIs.
If any required parameter is missing or invalid, the system responds with a 400 HTTP status and an appropriate error message.
4. **Error Handling:**
If Marketplace A fails (e.g., due to a server error), the system returns a meaningful error response, which includes the status and message from Marketplace A.
If Marketplace B fails during inventory creation or publishing, the system retries up to 3 times. If all retries fail, the system returns a failure status.
The system returns detailed error messages from both marketplaces when operations fail.
5. **API Responses:**
The system combines responses from both marketplaces into a single JSON object and sends it back to the client, indicating the status of product creation and publishing.
# Design Decisions
1. **Retryable Module:** Implemented custom retry logic to handle failures in Marketplace B. This improves the reliability of the system, especially for temporary server issues.
2. **Separation of Concerns:** Business logic for interacting with each marketplace is separated into dedicated service classes (MarketplaceAService and MarketplaceBService). This improves maintainability and makes the code more modular.
3. **Stubbing in Tests:** External API calls are stubbed during tests to simulate different failure scenarios and test how the retry mechanism behaves.

# Setup and Installation
**1. Clone the repository**
git clone git@github.com:SamanRafique/Sempi-APi-integrations.git
cd Sempi-APi-integrations
**2. Install dependencies**
gem install bundler
bundle install

**3. Install external services**
**Marketplace A:** Make sure the mock API for Marketplace A is running on http://localhost:3001. This mock server is built using Sinatra.
**Marketplace B:** Make sure the mock API for Marketplace B is running on http://localhost:3002. This mock server is also built using Sinatra.
You can use the provided sh setup.sh script to start the mock servers

**4. Running the Rails Server**
rails server

# API Endpoints
**1. POST /api/products**
POST request to /api/products using postman or using curl **curl -X POST http://localhost:3000/api/products   -H "Content-Type: application/json"   -d '{"name": "Test Product", "price": 1999, "sku": "TEST123"}'**
Creates a product on both Marketplace A and Marketplace B and attempts to publish it on Marketplace B.
# Testing
**1. Run Tests**
run test using **rspec** or simply **rspec ./spec/requests/api/products_spec.rb**

**Dependencies**
Ruby 2.7 or higher
Rails 6.x or higher
HTTParty (for making HTTP requests)
RSpec (for testing)
Sinatra (for mock marketplace APIs)
