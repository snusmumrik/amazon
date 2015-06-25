class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy, :refresh]
  before_action :read_exchange_rate
  before_filter :set_locale, only: [:index, :show]
  before_filter :set_categories, except: [:show, :delete]
  after_filter :remember_previous_page, only: :index

  # GET /products
  # GET /products.json
  def index
    @product = Product.new
    @conditions = Array.new
    @orders = Array.new

    @conditions << "price >= #{params[:low_price]}" unless params[:low_price].blank?
    @conditions << "price <= #{params[:high_price]}" unless params[:high_price].blank?
    @conditions << "category = '#{params[:category]}'" unless params[:category].blank?
    @conditions << "profit > 0" if params[:profit] == "1"
    if params[:sales_rank]
      @conditions << "sales_rank IS NOT NULL"
      @orders << "sales_rank ASC"
    end

    if params[:profit]
      @orders << "profit DESC"
    end

    if params[:manufacturer]
      @conditions << "manufacturer = '#{params[:manufacturer]}'"
    end

    if params[:image]
      @conditions << "image_url1 IS NOT null"
    end

    if params[:ebay]
      @products = Product.joins(:ebay_items).where(@conditions.join(" AND ")).group("products.id").order(@orders.join(",")).page params[:page]
      @count = Product.joins(:ebay_items).where(@conditions.join(" AND ")).group("products.id").count.size
    else
      @products = Product.where(@conditions.join(" AND ")).order(@orders.join(",")).page params[:page]
      @count = Product.where(@conditions.join(" AND ")).count
    end

    @amazon_profit_hash = @products.inject(Hash.new) {|h, p| h[p.id] = (p.price * (1 - 0.1 - 0.039) - 0.3) * @exchange_rate - p.shipping_cost - p.cost if p.price && p.cost; h}
    @product_to_sells = ProductToSell.where(["product_id in (?)", @products.pluck(:id)]).pluck(:product_id)

    set_ebay_data_for_multiple_products(@products.pluck(:id))
    @ebay_profit_hash = @products.inject(Hash.new) {|h, p| h[p.id] = Product.calculate_profit(p, @average_hash[p.id]) if !@sold_item_hash[p.id].blank?  && p.cost; h}

    respond_to do |format|
      format.html # index.html.erb
      format.js # index.js.erb
    end
  end

  # GET /products/1
  # GET /products/1.json
  def show
    if @product.price && @product.cost
      @amazon_profit = Product.calculate_profit(@product)
    end

    set_ebay_data_for_single_product(@product.id)
    if @average && @product.cost
      @ebay_profit = Product.calculate_profit(@product, @average)
    end

    @related_products = Product.where(["category = ? AND id != ?", @product.category, @product.id]).order("RAND()").limit(4)
    @amazon_profit_hash = @related_products.inject(Hash.new) {|h, p| h[p.id] = Product.calculate_profit(p) if p.price && p.cost; h}

    puts @related_products.pluck(:id)

    set_ebay_data_for_multiple_products(@related_products.pluck(:id))
    @ebay_profit_hash = @related_products.inject(Hash.new) {|h, p| h[p.id] = Product.calculate_profit(p, @average_hash[p.id]) if @average_hash[p.id] > 0 && p.cost; h}
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
  end

  # POST /products
  # POST /products.json
  def create
    @product = Product.new(product_params)

    respond_to do |format|
      if @product.save
        find_ebay_completed_items(@product.title, @product.id)

        format.html { redirect_to @product, notice: 'Product was successfully created.' }
        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    respond_to do |format|
      if @product.update(product_params)
        format.html { redirect_to @product, notice: 'Product was successfully updated.' }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    @product.destroy
    respond_to do |format|
      format.html { redirect_to products_url, notice: 'Product was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # GET /products/refresh/1
  # GET /products/refresh/1.json
  def refresh
    Product.lookup @product.asin
    redirect_to product_path @product
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def product_params
    params.require(:product).permit(:asin, :category, :manufacturer, :model, :title, :color, :size, :weight, :features, :sales_rank, :url, :url_jp, :image_url1, :image_url2, :image_url3, :image_url4, :image_url5, :currency, :price, :cost, :shipping_cost, :profit, :ebay_average, :deleted_at)
  end

  def remember_previous_page
    session[:previous_page] = request.env['HTTP_REFERER'] || products_url
  end
end
