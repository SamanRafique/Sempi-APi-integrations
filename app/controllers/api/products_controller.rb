class Api::ProductsController < ApplicationController
  def create
    # Post to Marketplace A
    marketplace_a_result = post_to_marketplace_a(product_params)
    
    # Post to Marketplace B (Create Inventory and Publish)
    inventory_result = create_inventory_on_marketplace_b(product_params)
    publish_result = publish_inventory_on_marketplace_b(inventory_result)

    # Combine results and render response
    render json: {
      marketplace_a: marketplace_a_result,
      marketplace_b: {
        inventory: inventory_result,
        publish: publish_result
      }
    }
  end

  private

  def product_params
    params.require(:product).permit(:name, :price, :sku)
  end

  def post_to_marketplace_a(payload)
    MarketplaceAService.post_product(payload)
  end

  def create_inventory_on_marketplace_b(payload)
    MarketplaceBService.create_inventory(
      title: payload[:name],
      price_cents: payload[:price],
      seller_sku: payload[:sku]
    )
  end

  def publish_inventory_on_marketplace_b(inventory_result)
    return { error: "Failed to create inventory on Marketplace B" } unless inventory_result

    MarketplaceBService.publish_inventory(inventory_result["inventory_id"])
  end
end
