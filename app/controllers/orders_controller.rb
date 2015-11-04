class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  before_action :set_options, only: [:new, :create, :edit, :update]
  before_action :set_product, only: [:edit, :update]
  before_filter :set_categories, except: [:show, :delete]
  before_filter :authenticate_user!

  # GET /orders
  # GET /orders.json
  def index
    read_exchange_rate
    @conditions = Array.new

    @conditions << "sold_at BETWEEN '#{Date.new(params[:sold_at]["sold_at(1i)"].to_i, params[:sold_at]["sold_at(2i)"].to_i, 1)}' AND '#{Date.new(params[:sold_at]["sold_at(1i)"].to_i, params[:sold_at]["sold_at(2i)"].to_i, -1)}'" if params[:sold_at]
    @conditions << "price_original >= #{params[:low_price]}" unless params[:low_price].blank?
    @conditions << "price_original <= #{params[:high_price]}" unless params[:high_price].blank?
    @conditions << "products.category = '#{params[:category]}'" unless params[:category].blank?

    if params[:manufacturer]
      @conditions << "products.manufacturer = '#{params[:manufacturer]}'"
    end

    @orders = Order.joins(:product).where(@conditions.join(" AND ")).order("sold_at DESC").all # .page params[:page]
    @sales = @orders.sum(:price_original)
    @average_exchange_rate = (@orders.sum(:price_yen) / @sales).round(2)
    @cost = @orders.sum(:cost)
    @shipping_cost = @orders.sum(:shipping_cost)
    @ebay_cost = @sales * 0.1
    @paypal_cost = (@sales * 0.039 + 0.3 * @orders.size)
    @profit = @orders.sum(:profit)

    @products_hash = Product.where(["id IN (?)", @orders.pluck(:product_id)]).inject(Hash.new) {|h, p| h[p.id] = p; h}
  end

  # GET /orders/1
  # GET /orders/1.json
  def show
  end

  # GET /orders/new
  def new
    @order = Order.new
    @product = Product.find(params[:product_id]) if params[:product_id]
  end

  # GET /orders/1/edit
  def edit
  end

  # POST /orders
  # POST /orders.json
  def create
    @order = Order.new(order_params)

    respond_to do |format|
      if @order.save
        format.html { redirect_to @order, notice: 'Order was successfully created.' }
        format.json { render :show, status: :created, location: @order }
      else
        format.html { render :new }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /orders/1
  # PATCH/PUT /orders/1.json
  def update
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to @order, notice: 'Order was successfully updated.' }
        format.json { render :show, status: :ok, location: @order }
      else
        format.html { render :edit }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1
  # DELETE /orders/1.json
  def destroy
    @order.destroy
    respond_to do |format|
      format.html { redirect_to orders_url, notice: 'Order was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_order
    @order = Order.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def order_params
    params.require(:order).permit(:product_id, :locale, :memo, :price_original, :price_yen, :cost, :shipping_cost, :profit, :sold_at, :shipped)
  end

  def set_options
    @product_options = ProductToSell.joins(:product).where("listed IS TRUE").inject(Array.new) {|a, pts| a << [pts.product.title, pts.product_id]; a}
  end

  def set_product
    @product = @order.product
  end
end
