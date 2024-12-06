require 'rails_helper'

RSpec.describe 'Products API', type: :request do
  let(:product) { { name: "Test Product", price: 1999, sku: "TEST123" } }
  let(:invalid_product) { { name: "", price: 1999, sku: "TEST123" } } # Example of missing or invalid params
  let(:incomplete_product) { { price: 1999, sku: "TEST123" } } # Missing name

  before do
    # Stubbing the API requests for Marketplace A and Marketplace B
    stub_request(:post, "http://localhost:3001/api/products")
      .to_return(status: 201, body: { id: "12345", status: "success" }.to_json)

    stub_request(:post, "http://localhost:3002/inventory")
      .to_return(status: 200, body: { inventory_id: "67890", status: "created" }.to_json)

    stub_request(:post, "http://localhost:3002/inventory/67890/publish")
      .to_return(status: 200, body: { listing_id: "L123", status: "published" }.to_json)
  end

  it 'posts product data to both marketplaces successfully' do
    post '/api/products', params: { product: product }

    expect(response).to have_http_status(:success)
    result = JSON.parse(response.body)

    expect(result['marketplace_a']['status']).to eq('success')
    expect(result['marketplace_b']['inventory']['status']).to eq('created')
    expect(result['marketplace_b']['publish']['status']).to eq('published')
  end

  context 'when required parameters are missing' do
    it 'returns an error when the name is missing' do
      # Simulate missing 'name' field in the product creation
      stub_request(:post, "http://localhost:3002/inventory")
        .to_return(status: 422, body: { error: "Name is required" }.to_json)

      post '/api/products', params: { product: incomplete_product }
      result = JSON.parse(response.body)

      expect(result['marketplace_b']['inventory']['error']).to eq("Marketplace B inventory creation failed: Name is required")
    end

    it 'returns an error when the name is empty' do
      # Simulate empty 'name' field in the product creation
      stub_request(:post, "http://localhost:3001/api/products")
        .to_return(status: 422, body: { error: "Name can't be blank" }.to_json)

      post '/api/products', params: { product: invalid_product }

      result = JSON.parse(response.body)
      expect(result['marketplace_a']['error']).to eq("Name can't be blank")
    end
  end

  context 'when Marketplace A fails' do
    before do
      stub_request(:post, "http://localhost:3001/api/products")
        .to_return(status: 500, body: { error: "Internal server error" }.to_json)
    end

    it 'returns an error for Marketplace A' do
      post '/api/products', params: { product: product }

      expect(response).to have_http_status(:success)
      result = JSON.parse(response.body)

      expect(result['marketplace_a']['error']).to eq('Internal server error')
    end
  end

  context 'when Marketplace B fails during inventory creation' do
    before do
      stub_request(:post, "http://localhost:3002/inventory")
        .to_return(status: 500, body: { error: "Internal server error" }.to_json)
    end

    it 'retries and eventually succeeds' do
      stub_request(:post, "http://localhost:3002/inventory")
        .to_return(status: 500, body: { error: "Internal server error" }.to_json)
        .then
        .to_return(status: 200, body: { inventory_id: "67890", status: "created" }.to_json)

      post '/api/products', params: { product: product }

      expect(response).to have_http_status(:success)
      result = JSON.parse(response.body)
      expect(result['marketplace_b']['inventory']['status']).to eq('created')
    end
  end

  context 'when Marketplace B fails during publishing' do
    before do
      stub_request(:post, "http://localhost:3002/inventory/67890/publish")
        .to_return(status: 500, body: { error: "Internal server error" }.to_json)
    end

    it 'retries and eventually publishes the product' do
      stub_request(:post, "http://localhost:3002/inventory/67890/publish")
        .to_return(status: 500, body: { error: "Internal server error" }.to_json)
        .then
        .to_return(status: 200, body: { listing_id: "L123", status: "published" }.to_json)

      post '/api/products', params: { product: product }

      expect(response).to have_http_status(:success)
      result = JSON.parse(response.body)

      expect(result['marketplace_b']['publish']['status']).to eq('published')
    end

    it 'fails after retry attempts' do
      stub_request(:post, "http://localhost:3002/inventory/67890/publish")
        .to_return(status: 500, body: { error: "Internal server error" }.to_json)
        .then
        .to_return(status: 500, body: { error: "Internal server error" }.to_json)

      post '/api/products', params: { product: product }

      expect(response).to have_http_status(:success)
      result = JSON.parse(response.body)

      expect(result['marketplace_b']['publish']['status']).to eq('failed')
      expect(result['marketplace_b']['publish']['error']).to eq('Marketplace B inventory publishing failed: Internal server error')
    end
  end

  context 'when both marketplaces fail' do
    before do
      stub_request(:post, "http://localhost:3001/api/products")
        .to_return(status: 500, body: { error: "Internal server error" }.to_json)

      stub_request(:post, "http://localhost:3002/inventory")
        .to_return(status: 500, body: { error: "Internal server error" }.to_json)

      stub_request(:post, "http://localhost:3002/inventory/67890/publish")
        .to_return(status: 500, body: { error: "Internal server error" }.to_json)
    end

    it 'handles failures and returns appropriate error responses' do
      post '/api/products', params: { product: product }

      expect(response).to have_http_status(:success)
      result = JSON.parse(response.body)

      expect(result['marketplace_a']['error']).to eq('Internal server error')
      expect(result['marketplace_b']['inventory']['status']).to eq('failed')
      expect(result['marketplace_b']['publish']['status']).to eq('failed')
    end
  end
end
