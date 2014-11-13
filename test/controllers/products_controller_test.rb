require 'test_helper'

class ProductsControllerTest < ActionController::TestCase
  setup do
    @product = products(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:products)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create product" do
    assert_difference('Product.count') do
      post :create, product: { asin: @product.asin, color: @product.color, cost: @product.cost, currency: @product.currency, deleted_at: @product.deleted_at, features: @product.features, group: @product.group, image_url1: @product.image_url1, image_url2: @product.image_url2, image_url3: @product.image_url3, image_url4: @product.image_url4, image_url5: @product.image_url5, manufacturer: @product.manufacturer, model: @product.model, price: @product.price, sales_rank: @product.sales_rank, size: @product.size, title: @product.title, url: @product.url, url_jp: @product.url_jp }
    end

    assert_redirected_to product_path(assigns(:product))
  end

  test "should show product" do
    get :show, id: @product
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @product
    assert_response :success
  end

  test "should update product" do
    patch :update, id: @product, product: { asin: @product.asin, color: @product.color, cost: @product.cost, currency: @product.currency, deleted_at: @product.deleted_at, features: @product.features, group: @product.group, image_url1: @product.image_url1, image_url2: @product.image_url2, image_url3: @product.image_url3, image_url4: @product.image_url4, image_url5: @product.image_url5, manufacturer: @product.manufacturer, model: @product.model, price: @product.price, sales_rank: @product.sales_rank, size: @product.size, title: @product.title, url: @product.url, url_jp: @product.url_jp }
    assert_redirected_to product_path(assigns(:product))
  end

  test "should destroy product" do
    assert_difference('Product.count', -1) do
      delete :destroy, id: @product
    end

    assert_redirected_to products_path
  end
end
