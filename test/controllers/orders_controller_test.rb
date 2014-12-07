require 'test_helper'

class OrdersControllerTest < ActionController::TestCase
  setup do
    @order = orders(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:orders)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create order" do
    assert_difference('Order.count') do
      post :create, order: { cost: @order.cost, locale: @order.locale, price_original: @order.price_original, price_yen: @order.price_yen, product_id: @order.product_id, profit: @order.profit, shipping_cost: @order.shipping_cost, sold_at: @order.sold_at }
    end

    assert_redirected_to order_path(assigns(:order))
  end

  test "should show order" do
    get :show, id: @order
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @order
    assert_response :success
  end

  test "should update order" do
    patch :update, id: @order, order: { cost: @order.cost, locale: @order.locale, price_original: @order.price_original, price_yen: @order.price_yen, product_id: @order.product_id, profit: @order.profit, shipping_cost: @order.shipping_cost, sold_at: @order.sold_at }
    assert_redirected_to order_path(assigns(:order))
  end

  test "should destroy order" do
    assert_difference('Order.count', -1) do
      delete :destroy, id: @order
    end

    assert_redirected_to orders_path
  end
end
