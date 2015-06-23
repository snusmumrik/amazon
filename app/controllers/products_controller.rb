require 'csv'

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
    @conditions << "profit > #{3 * @exchange_rate}" if params[:profit] == "1"
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
    else
      @products = Product.where(@conditions.join(" AND ")).order(@orders.join(",")).page params[:page]
    end

    @profit_hash = @products.inject(Hash.new) {|h, p| h[p.id] = (p.price * (1 - 0.1 - 0.039) - 0.3) * @exchange_rate - p.shipping_cost - p.cost if p.price && p.cost; h}
    @product_to_sells = ProductToSell.where(["product_id in (?)", @products.pluck(:id)]).pluck(:product_id)

    set_ebay_data_for_multiple_products(@products.pluck(:id))
  end

  # GET /products/1
  # GET /products/1.json
  def show
    if @product.price && @product.cost
      @amazon_profit = (@product.price * (1 - 0.1 - 0.039) - 0.3) * @exchange_rate - @product.shipping_cost - @product.cost
    end

    set_ebay_data_for_single_product(@product.id)
    @ebay_profit = (@average * (1 - 0.1 - 0.039) - 0.3) * @exchange_rate - @product.cost - @product.shipping_cost if @average && @product.cost
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

  # POST /products/search
  # POST /products/search.json
  def search
    get_exchange_rate

    request = Vacuum.new()
    request.configure(
                      aws_access_key_id: AWS_ACCESS_KEY_ID,
                      aws_secret_access_key: AWS_SECRET_ACCESS_KEY,
                      associate_tag: ASSOCIATE_TAG
                      )
    SearchIndex.all.each_with_index do |search_index, i|
      # next if search_index.id < 23

      search_index.sort_values.each do |sort_value|
        for i in 1..10
          parameters = {
            "SearchIndex" => search_index.name,
            "Keywords" => params[:search],
            "ResponseGroup" => "Medium",
            "Sort" => sort_value.name,
            "ItemPage" => i
          }

          # amazon.com
          begin
            response = request.item_search(query: parameters).to_h
            # puts response
          rescue TimeoutError
            warn "TimeoutError"
          rescue  => ex
            case ex
              # when "404" then
              #   warn "404: #{ex.page.uri} does not exist"
            when "Excon::Errors::ServiceUnavailable: Expected(200) <=> Actual(503 Service Unavailable)" then
              if @retryuri != url && sec = ex.page.header["Retry-After"]
                warn "503: will retry #{ex.page.uri} in #{sec}seconds"
                @retryuri = ex.page.uri
                sleep sec.to_i
                retry
              end
            when /\A5/ then
              warn "#{ex.code}: internal error"
            else
              warn ex.message
            end
          end

          if response && response["ItemSearchResponse"]["Items"]["Item"]
            response["ItemSearchResponse"]["Items"]["Item"].each do |item|
              puts "\r\nSEARCH_INDEX:#{search_index.name}, SORT_VALUE:#{sort_value.name}, ITEM_PAGE:#{i}"

              if !item.nil? && item.instance_of?(Hash)
                if product = save_product(item)
                  find_ebay_completed_items(product.title, product.id)

                  average = product.ebay_items.inject(Array.new) {|a, ei| a << ei.current_price_value if ei.selling_state == "EndedWithSales"
                    puts "SOLD ON EBAY AT:#{ei.current_price_value}"; a
                  }

                  if average.size > 0
                    product.update_attribute(:ebay_average, average.inject{ |sum, el| sum + el }.to_f / average.size)
                    puts "EBAY PROFIT: #{product.ebay_average}"
                  end
                end
              end
            end
          end
        end
      end
    end

    redirect_to products_path
  end

  # GET /products/refresh/1
  # GET /products/refresh/1.json
  def refresh
    lookup @product.asin
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

  def import_from_csv
    file_path = "public/amazon_com_31.csv"
    CSV.open(file_path).each_with_index do |row, i|
      next if i <= 0
      asin = row[5]
      lookup(asin)
    end
  end
  def remember_previous_page
    session[:previous_page] = request.env['HTTP_REFERER'] || products_url
  end
end
