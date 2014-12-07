class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  before_action :set_options, only: [:new, :create, :edit, :update]

  # GET /orders
  # GET /orders.json
  def index
    @orders = Order.order("sold_at DESC").page params[:page]
    @products_hash = Hash.new
    products = Product.where(["id IN (?)", @orders.pluck(:product_id)])
    products.each do |p|
      @products_hash.store(p.id, p)
    end

    @categories = Array.new
    Product.group(:category).order(:category).all.each do |product|
      @categories << [product.category, product.category]
    end

    @conditions = Array.new
    @sql_orders = Array.new

    @conditions << "price >= #{params[:low_price]}" unless params[:low_price].blank?
    @conditions << "price <= #{params[:high_price]}" unless params[:high_price].blank?
    @conditions << "category = '#{params[:category]}'" unless params[:category].blank?

    if params[:manufacturer]
      @conditions << "manufacturer = '#{params[:manufacturer]}'"
    end

    case params[:locale]
    when "USD"
      @locale = "USD"
    else
      @locale = "USD"
    end

    @ebay_items = Hash.new do |hash, key|
      hash[key] = Array.new
    end

    @sold_items = Hash.new do |hash, key|
      hash[key] = Array.new
    end

    @averages = Hash.new do |hash, key|
      hash[key] = Array.new
    end

    ebay_items = EbayItem.where(["product_id IN (?)", @orders.pluck(:product_id)]).order("current_price_value")
    ebay_items.each do |item|
      if item.current_price_currency_id == @locale
        @ebay_items[item.product_id] << item.try(:current_price_value)
      end

      if item.current_price_currency_id == @locale && item.selling_state == "EndedWithSales"
        @sold_items[item.product_id] << item.try(:current_price_value)
      end
    end
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

  def set_options
    @product_options = Array.new
    ProductToSell.joins(:product).where("listed IS TRUE").all.each do |p|
      @product_options << [p.product.title, p.product.id]
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def order_params
    params.require(:order).permit(:product_id, :locale, :memo, :price_original, :price_yen, :cost, :shipping_cost, :profit, :sold_at)
  end
end
