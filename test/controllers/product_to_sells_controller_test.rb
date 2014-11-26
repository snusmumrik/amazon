require 'test_helper'

class ProductToSellsControllerTest < ActionController::TestCase
  setup do
    @product_to_sell = product_to_sells(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:product_to_sells)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create product_to_sell" do
    assert_difference('ProductToSell.count') do
      post :create, product_to_sell: { product_id: @product_to_sell.product_id }
    end

    assert_redirected_to product_to_sell_path(assigns(:product_to_sell))
  end

  test "should show product_to_sell" do
    get :show, id: @product_to_sell
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @product_to_sell
    assert_response :success
  end

  test "should update product_to_sell" do
    patch :update, id: @product_to_sell, product_to_sell: { product_id: @product_to_sell.product_id }
    assert_redirected_to product_to_sell_path(assigns(:product_to_sell))
  end

  test "should destroy product_to_sell" do
    assert_difference('ProductToSell.count', -1) do
      delete :destroy, id: @product_to_sell
    end

    assert_redirected_to product_to_sells_path
  end
end
