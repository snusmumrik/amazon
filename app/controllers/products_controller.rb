require 'open-uri'
require 'csv'

class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  before_action :read_exchange_rate
  after_filter :remember_previous_page, only: :index

  # @@app_id = "Chishaku-8e8f-48de-a23a-e1304518388d" # sandbox
  @@app_id = "Chishaku-0efe-4739-a2ff-dba4724f0514" # production

  # GET /products
  # GET /products.json
  def index
    @product = Product.new
    @categories = Array.new
    Product.group(:category).order(:category).all.each do |product|
      @categories << [product.category, product.category]
    end

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

    if params[:ebay]
      @products = Product.joins(:ebay_items).where(@conditions.join(" AND ")).group("products.id").order(@orders.join(",")).page params[:page]
    else
      @products = Product.where(@conditions.join(" AND ")).order(@orders.join(",")).page params[:page]
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

    ebay_items = EbayItem.where(["product_id IN (?)", @products.pluck(:id)]).order("current_price_value")
    ebay_items.each do |item|
      if item.current_price_currency_id == @locale
        @ebay_items[item.product_id] << item.try(:current_price_value)
      end

      if item.current_price_currency_id == @locale && item.selling_state == "EndedWithSales"
        @sold_items[item.product_id] << item.try(:current_price_value)
      end
    end
  end

  # GET /products/1
  # GET /products/1.json
  def show
   case
    when "USD"
      @locale = "USD"
    else
      @locale = "USD"
    end

    @ebay_items = EbayItem.where(["product_id = ?", @product.id]).order("end_time DESC")
    @sold_items = EbayItem.where(["product_id = ? AND current_price_currency_id = ? AND selling_state = ?",
                                 @product.id,
                                 @locale,
                                 "EndedWithSales"])
    @average = (@sold_items.pluck(:current_price_value).inject{ |sum, el| sum + el }.to_f / @sold_items.size).round(2) if @sold_items.count > 0
  end

  # GET /products/new
  def new
    @product = Product.new

    # CSV.open("public/amazon_com_31.csv").each_with_index do |row, i|
    #   next if i <= 0
    #   asin = row[5]
    #   lookup(asin)
    # end
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
      next if search_index.id < 25

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

              product = save_product(item)
              find_ebay_completed_items(product.title, product.id)
            end
          end
        end
      end
    end

    redirect_to products_path
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def product_params
    params.require(:product).permit(:asin, :category, :manufacturer, :model, :title, :color, :size, :weight, :features, :sales_rank, :url, :url_jp, :image_url1, :image_url2, :image_url3, :image_url4, :image_url5, :currency, :price, :cost, :shipping_cost, :profit, :deleted_at)
  end

  def get_exchange_rate
    begin
      file = open("public/exchange_rate.txt", "w")
      api = "http://www.freecurrencyconverterapi.com/api/v2/convert?q=USD_JPY&compact=y"
      source = open(api).read()
      json = JSON.parse(source)
      exchange_rate = json["USD_JPY"]["val"]
      puts "EXCHANGE RATE FROM API:#{exchange_rate}"
      file.puts exchange_rate
    rescue => ex
      warn ex.message
    end
  end

  def read_exchange_rate
    @exchange_rate = open("public/exchange_rate.txt", "r").read.to_i
    puts "EXCHANGE RATE FROM FILE:#{@exchange_rate}"
  end

  def lookup(asin)
    get_exchange_rate

    request = Vacuum.new()
    request.configure(aws_access_key_id: AWS_ACCESS_KEY_ID,
                      aws_secret_access_key: AWS_SECRET_ACCESS_KEY,
                      associate_tag: ASSOCIATE_TAG)
    parameters = {
      "ItemId" => asin,
      "ResponseGroup" => "Medium"
    }

    # amazon.com
    begin
      response = request.item_lookup(query: parameters).to_h
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

    if response && response["ItemLookupResponse"]["Items"]["Item"]
      item = response["ItemLookupResponse"]["Items"]["Item"]

      product = save_product(item)
      find_ebay_completed_items(product.title, product.id)
    end
  end

  def save_product(item)
    # puts item

    product = Product.new
    product.asin = item["ASIN"]
    product.category = item["ItemAttributes"]["ProductGroup"]
    product.manufacturer = item["ItemAttributes"]["Manufacturer"]
    product.model = item["ItemAttributes"]["Model"]
    product.title = item["ItemAttributes"]["Title"]
    product.color = item["ItemAttributes"]["Color"]
    product.size = item["ItemAttributes"]["Size"]
    product.weight = item["ItemAttributes"]["PackageDimensions"]["Weight"]["__content__"] rescue product.weight = 0
    product.features = item["ItemAttributes"]["Feature"].join(",") if item["ItemAttributes"]["Feature"].class == "Array"
    product.sales_rank = item["SalesRank"]
    product.url = item["DetailPageURL"]

    puts "TITLE:#{product.title}"
    puts "URL:#{product.url}"

    if item["ImageSets"]
      for j in 0..4
        if item["ImageSets"]["ImageSet"][j]
          case j
          when 0
            product.image_url1 = item["ImageSets"]["ImageSet"][j]["LargeImage"]["URL"]
          when 1
            product.image_url2 = item["ImageSets"]["ImageSet"][j]["LargeImage"]["URL"]
          when 2
            product.image_url3 = item["ImageSets"]["ImageSet"][j]["LargeImage"]["URL"]
          when 3
            product.image_url4 = item["ImageSets"]["ImageSet"][j]["LargeImage"]["URL"]
          when 4
            product.image_url5 = item["ImageSets"]["ImageSet"][j]["LargeImage"]["URL"]
          end
        end
      end
    end

    if item["OfferSummary"] && item["OfferSummary"]["LowestNewPrice"]
      product.currency = item["OfferSummary"]["LowestNewPrice"]["CurrencyCode"]
      product.price = (item["OfferSummary"]["LowestNewPrice"]["Amount"].to_f/100).round(2)
    end

    # amazon.co.jp
    request2 = Vacuum.new("JP")
    request2.configure(aws_access_key_id: AWS_ACCESS_KEY_ID,
                       aws_secret_access_key: AWS_SECRET_ACCESS_KEY,
                       associate_tag: ASSOCIATE_TAG)
    parameters_for_jp = {
      "ItemId" => product.asin,
      "ResponseGroup" => "Medium",
    }

    begin
      response2 = request2.item_lookup(query: parameters_for_jp).to_h
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

    if response2
      product.url_jp = response2["ItemLookupResponse"]["Items"]["Item"]["DetailPageURL"] rescue nil
      product.cost = response2["ItemLookupResponse"]["Items"]["Item"]["OfferSummary"]["LowestNewPrice"]["Amount"] rescue nil
    end

    if saved_product = Product.where(["asin = ?", product.asin]).with_deleted.first
      saved_product.update_attributes(:manufacturer => product.manufacturer,
                                      :model => product.model,
                                      :title => product.title,
                                      :color => product.color,
                                      :size => product.size,
                                      :weight => product.weight,
                                      :features => product.features,
                                      :sales_rank => product.sales_rank,
                                      :url => product.url,
                                      :url_jp => product.url_jp,
                                      :image_url1 => product.image_url1,
                                      :image_url2 => product.image_url2,
                                      :image_url3 => product.image_url3,
                                      :image_url4 => product.image_url4,
                                      :image_url5 => product.image_url5,
                                      :currency => product.currency,
                                      :price => product.price,
                                      :cost => product.cost
                                      )
      puts "PRODUCT UPDATED:#{product.title}"
    else
      product.save
      Category.create(name: product.category) unless Category.where(["name = ?", product.category]).first
    end
    product
  end

  def find_ebay_completed_items(keyword, product_id)
    url = "http://svcs.ebay.com/services/search/FindingService/v1?OPERATION-NAME=findCompletedItems&SERVICE-VERSION=1.0.0&SECURITY-APPNAME=#{@@app_id}&RESPONSE-DATA-FORMAT=JSON&REST-PAYLOAD&keywords=#{URI.escape(keyword)}"
    puts "EBAY URL:#{url}"

    begin
      source = open(url).read()
      json = JSON.parse(source)
      # puts "\r\n#{json}"
    rescue TimeoutError
      warn "TimeoutError"
    rescue  => ex
      warn ex.message
    end

    begin
      items = json["findCompletedItemsResponse"][0]["searchResult"][0]["item"]
    rescue => ex
      warn ex.message
    end

    if items
      items.each do |item|
        ebay = EbayItem.new
        ebay.product_id = product_id
        ebay.item_id = item["itemId"][0] rescue nil
        ebay.title = item["title"][0] rescue nil
        ebay.global_id = item["globalId"][0] rescue nil
        ebay.category_name = item["primaryCategory"][0]["categoryName"][0] rescue nil
        ebay.gallery_url = item["galleryURL"][0] rescue nil
        ebay.view_item_url = item["viewItemURL"][0] rescue nil
        ebay.shipping_service_cost_currency_id = item["shippingInfo"][0]["shippingServiceCost"][0]["@currencyId"] rescue nil
        ebay.shipping_service_cost_value = item["shippingInfo"][0]["shippingServiceCost"][0]["__value__"].to_f rescue nil
        ebay.shipping_type = item["shippingInfo"][0]["shippingType"][0] rescue nil
        ebay.handling_time = item["shippingInfo"][0]["handlingTime"][0] rescue nil
        ebay.current_price_currency_id = item["sellingStatus"][0]["currentPrice"][0]["@currencyId"] rescue nil
        ebay.current_price_value = item["sellingStatus"][0]["currentPrice"][0]["__value__"].to_f rescue nil
        ebay.bid_count = item["sellingStatus"][0]["bidCount"][0] if item["sellingStatus"][0]["bidCount"] rescue nil
        ebay.selling_state = item["sellingStatus"][0]["sellingState"][0] rescue nil
        ebay.best_offer_enabled = item["listingInfo"][0]["bestOfferEnabled"][0] rescue nil
        ebay.buy_it_now_available = item["listingInfo"][0]["buyItNowAvailable"][0] rescue nil
        ebay.start_time = item["listingInfo"][0]["startTime"][0] rescue nil
        ebay.end_time = item["listingInfo"][0]["endTime"][0] rescue nil
        ebay.listing_type = item["listingInfo"][0]["listingType"][0] rescue nil
        ebay.returns_accepted = item["returnsAccepted"][0] rescue nil
        ebay.condition_display_name = item["condition"][0]["conditionDisplayName"][0] rescue nil

        if EbayItem.where(["item_id = ?", ebay.item_id]).first.nil?
          ebay.save
          puts "EBAY TITLE: #{ebay.title}"
          puts "EBAY PRICE: #{ebay.current_price_currency_id} #{ebay.current_price_value}"
        else
          puts "ALREADY SAVED: #{ebay.title}"
        end
      end
    end
  end

  def remember_previous_page
    session[:previous_page] = request.env['HTTP_REFERER'] || products_url
  end
end
