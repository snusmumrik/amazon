class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy, :refresh, :download_images]
  before_action :read_exchange_rate
  before_filter :set_locale, only: [:index, :show]
  before_filter :set_categories, except: [:show, :delete]
  before_filter :authenticate_user!, except: [:index, :show]
  after_filter :remember_previous_page, only: :index

  # GET /products
  # GET /products.json
  def index
    @product = Product.new
    @conditions = Array.new
    @orders = Array.new

    # refactoring required
    @conditions << "price >= #{params[:low_price]}" unless params[:low_price].blank?
    @conditions << "price <= #{params[:high_price]}" unless params[:high_price].blank?
    unless params[:category].blank?
      @conditions << "category = '#{params[:category]}'"
      @orders <<  "products.title"
    end

    unless params[:category_name].blank?
      @conditions << "category = '#{params[:category_name]}'"
      @orders <<  "products.title" unless @orders.include?("products.title")
    end

    @orders << "products.created_at DESC" unless @orders.include?("products.title")

    unless params[:profit].blank?
      @conditions << "profit > 0"
      @orders << "profit DESC"
    end
    @conditions << "title LIKE '%#{params[:keyword]}%'" unless params[:keyword].blank?
    @conditions << "price IS NOT NULL"
    @conditions << "cost IS NOT NULL"

    if params[:sales_rank]
      @conditions << "sales_rank IS NOT NULL"
      @orders << "sales_rank ASC"
    end

    if params[:manufacturer]
      @conditions << "manufacturer = '#{params[:manufacturer]}'"
    end

    if params[:image]
      @conditions << "image_url1 IS NOT null"
    end

    if params[:ebay]
      @conditions << "selling_state = 'EndedWithSales'"
      if params[:profit]
        @conditions << "profit_ebay > 0"
        @products = Product.joins(:ebay_items).where(@conditions.join(" AND ")).uniq.order(@orders.join(",")).page params[:page]
      else
        @products = Product.joins(:ebay_items).where(@conditions.join(" AND ")).uniq.order(@orders.join(",")).page params[:page]
      end
    else
      @products = Product.where(@conditions.join(" AND ")).order(@orders.join(",")).page params[:page]
    end
    @count = @products.total_count

    # @amazon_profit_hash = @products.inject(Hash.new) {|h, p| h[p.id] = Product.calculate_profit_on_amazon(p) if p.price && p.cost; h}
    @product_to_sells = ProductToSell.where(["product_id in (?)", @products.pluck(:id)]).pluck(:product_id)

    set_ebay_data_for_multiple_products(@products.pluck(:id))
    # @ebay_profit_hash = @products.inject(Hash.new) {|h, p| h[p.id] = Product.calculate_profit_on_ebay(p, @average_hash[p.id]) if !@sold_item_hash[p.id].blank?  && p.cost; h}

    if params[:category_name]
      @form_path = "#{products_path}/category/#{params[:category_name]}"
    else
      @form_path = products_path
    end

    @latest_product = Product.order("updated_at").last

    respond_to do |format|
      format.html # index.html.erb
      format.js # index.js.erb
    end
  end

  # GET /products/1
  # GET /products/1.json
  def show
    # if @product.price && @product.cost
    #   @amazon_profit = Product.calculate_profit_on_amazon(@product)
    # end

    set_ebay_data_for_single_product(@product.id)
    if @average && @product.cost
      # @ebay_profit = Product.calculate_profit_on_ebay(@product, @average)
    end

    @related_products = Product.where(["category = ? AND id != ? AND RAND() < ?", @product.category, @product.id, 0.01]).limit(3)
    # @amazon_profit_hash = @related_products.inject(Hash.new) {|h, p| h[p.id] = Product.calculate_profit_on_amazon(p) if p.price && p.cost; h}

    # puts @related_products.pluck(:id)

    set_ebay_data_for_multiple_products(@related_products.pluck(:id))
    # @ebay_profit_hash = @related_products.inject(Hash.new) {|h, p| h[p.id] = Product.calculate_profit_on_ebay(p, @average_hash[p.id]) if @average_hash[p.id] > 0 && p.cost; h}

    @product_to_sells = ProductToSell.where(["product_id = ?", @product.id]).pluck(:product_id)
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

  def download_images
    @destination = "#{Etc.getpwuid.dir}/Downloads/amazon"
    unless File.exists?(@destination)
      unless File.exists?("#{Etc.getpwuid.dir}/Downloads")
        Dir.mkdir "#{Etc.getpwuid.dir}/Downloads"
      end
      Dir.mkdir @destination
    end

    [@product.image_url1, @product.image_url2, @product.image_url3, @product.image_url4, @product.image_url5].each_with_index do |url, i|
      unless url.blank?
        /.+\.([a-z]+)$/ =~ url
        extention = $1
        get_content(url, @product.title, "#{i}.#{extention}")
      end
    end

    render nothing: true
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def product_params
    params.require(:product).permit(:asin, :category, :manufacturer, :model, :title, :color, :size, :weight, :features, :sales_rank, :url, :url_jp, :image_url1, :image_url2, :image_url3, :image_url4, :image_url5, :currency, :price, :cost, :shipping_cost, :profit, :profit_ebay, :ebay_average, :deleted_at)
  end

  def remember_previous_page
    session[:previous_page] = request.env['HTTP_REFERER'] || products_url
  end

  def get_content(uri, title, file_name)
    hc = HTTPClient.new
    begin
      content = hc.get_content(uri, :get, {})
    rescue
    end

    if content.nil? || content.size < 10
      p "file not found from #{uri}."
      return false
    else
      destination = "#{@destination}/#{title.gsub('/', ' ')}"
      unless File.exists?(destination)
        Dir.mkdir destination
      end

      if File.exists?("#{destination}/#{file_name}")
        p "#{file_name} already exists."
        return
      end

      File.open("#{destination}/#{file_name}", "wb") do |f|
        f.print content
        p "#{file_name} saved from #{uri}."
      end
    end
  end
end
