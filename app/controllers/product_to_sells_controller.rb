require 'csv'

class ProductToSellsController < ApplicationController
  before_action :set_product_to_sell, only: [:show, :edit, :update, :destroy]
  before_action :read_exchange_rate
  before_action :get_ebay_sold_items, only: [:show, :edit]
  after_action :list_to_ebay, only: :update
  after_filter :remember_previous_page, only: :index

  @@amazon_affiliate_link = "http://www.amazon.com/?_encoding=UTF8&camp=1789&creative=9325&linkCode=ur2&tag=chishaku-20&linkId=AOXRRTZSW6246HKX"

  # GET /product_to_sells
  # GET /product_to_sells.json
  def index
    @conditions = Array.new
    @orders = Array.new

    @conditions << "category = '#{params[:category]}'" unless params[:category].blank?

    @product_to_sells = ProductToSell.joins(:product).where(@conditions.join(" AND ")).page params[:page]

    @categories = Array.new
    Product.group(:category).order(:category).all.each do |product|
      @categories << [product.category, product.category]
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

    ebay_items = EbayItem.where(["product_id IN (?)", @product_to_sells.pluck(:product_id)]).order("current_price_value")
    ebay_items.each do |item|
      if item.current_price_currency_id == @locale
        @ebay_items[item.product_id] << item.try(:current_price_value)
      end

      if item.current_price_currency_id == @locale && item.selling_state == "EndedWithSales"
        @sold_items[item.product_id] << item.try(:current_price_value)
      end
    end
  end

  # GET /product_to_sells/1
  # GET /product_to_sells/1.json
  def show
  end

  # GET /product_to_sells/new
  def new
    @product_to_sell = ProductToSell.new
  end

  # GET /product_to_sells/1/edit
  def edit
  end

  # POST /product_to_sells
  # POST /product_to_sells.json
  def create
    @product_to_sell = ProductToSell.new(product_to_sell_params)
    @product_to_sell.category_id = EbayCategory.where(["category_name LIKE ? AND leaf_category = TRUE", "%#{@product_to_sell.product.category}%"]).first.try(:category_id)

    respond_to do |format|
      if @product_to_sell.save
        format.html { redirect_to @product_to_sell, notice: 'Product to sell was successfully created.' }
        format.json { render :show, status: :created, location: @product_to_sell }
      else
        format.html { render :new }
        format.json { render json: @product_to_sell.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /product_to_sells/1
  # PATCH/PUT /product_to_sells/1.json
  def update
    respond_to do |format|
      if @product_to_sell.update(product_to_sell_params)
        format.html { redirect_to @product_to_sell, notice: 'Product to sell was successfully updated.' }
        format.json { render :show, status: :ok, location: @product_to_sell }
      else
        format.html { render :edit }
        format.json { render json: @product_to_sell.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /product_to_sells/1
  # DELETE /product_to_sells/1.json
  def destroy
    @product_to_sell.destroy
    respond_to do |format|
      format.html { redirect_to product_to_sells_url, notice: 'Product to sell was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_product_to_sell
    @product_to_sell = ProductToSell.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def product_to_sell_params
    params.require(:product_to_sell).permit(:product_id, :category_id, :listed)
  end

  def remember_previous_page
    session[:previous_page] = request.env['HTTP_REFERER'] || products_url
  end

  def read_exchange_rate
    @exchange_rate = open("public/exchange_rate.txt", "r").read.to_i
    puts "EXCHANGE RATE:#{@exchange_rate}"
  end

  def get_ebay_sold_items
    case
    when "USD"
      @locale = "USD"
    else
      @locale = "USD"
    end

    @ebay_items = EbayItem.where(["product_id = ?", @product_to_sell.product.id]).order("end_time DESC")
    @sold_items = EbayItem.where(["product_id = ? AND current_price_currency_id = ? AND selling_state = ?",
                                  @product_to_sell.product.id,
                                  @locale,
                                  "EndedWithSales"])
    @average = (@sold_items.pluck(:current_price_value).inject{ |sum, el| sum + el }.to_f / @sold_items.size).round(1) if @sold_items.count > 0
  end

  def list_to_ebay(api_call_name = "VerifyAddItem", start_price = nil)
    if @product_to_sell.category_id && @product_to_sell.listed
      @product = @product_to_sell.product

      @header = {
        "X-EBAY-API-DEV-NAME" => DEVID,
        "X-EBAY-API-APP-NAME" => APPID,
        "X-EBAY-API-CERT-NAME" => CERTID,
        "X-EBAY-API-CALL-NAME" => api_call_name,
        "X-EBAY-API-COMPATIBILITY-LEVEL" => API_COMPATIBILITY_LEVEL,
        "X-EBAY-API-SITEID" => EBAY_API_SITEID,
        "Content-Type" => "text/xml",
      }

      descriptions = Array.new
      descriptions << "Brand new #{@product.title}(#{@product.manufacturer})"
      descriptions << "Model:#{@product.model}" if @product.model
      descriptions << "Color:#{@product.color}" if @product.color
      descriptions << "Size:#{@product.size}" if @product.size
      descriptions << "International shipping free."

      if start_price.blank?
        # start_price = (@product.price*0.95).round(0)
        start_price = @product.price.round(0)
      end
      condition_id = 1000
      listing_duration = "Days_3"
      listing_type = "Chinese"
      payment_methods = "PayPal"
      paypal_email = "hiroyuki.kondo@chishaku.com"

      pictures = Array.new
      pictures << "<PictureURL>#{@product.image_url1}</PictureURL>" unless @product.image_url1.blank?
      pictures << "<PictureURL>#{@product.image_url2}</PictureURL>" unless @product.image_url2.blank?
      pictures << "<PictureURL>#{@product.image_url3}</PictureURL>" unless @product.image_url3.blank?
      pictures << "<PictureURL>#{@product.image_url4}</PictureURL>" unless @product.image_url4.blank?
      pictures << "<PictureURL>#{@product.image_url5}</PictureURL>" unless @product.image_url5.blank?

      return_accespted_option = "ReturnsAccepted"
      refund_option = "MoneyBack"
      returns_within_option = "Days_30"

      xml = "
<?xml version='1.0' encoding='utf-8'?>
<#{api_call_name}Request xmlns='urn:ebay:apis:eBLBaseComponents'>
  <RequesterCredentials>
    <eBayAuthToken>#{TOKEN}</eBayAuthToken>
  </RequesterCredentials>
  <ErrorLanguage>en_US</ErrorLanguage>
  <WarningLevel>High</WarningLevel>
  <Item>
    <Title>#{@product.title} [#{@product.asin}]</Title>
    <Description>#{descriptions.join(', ')}</Description>
    <PrimaryCategory>
      <CategoryID>#{@product_to_sell.category_id}</CategoryID>
    </PrimaryCategory>
    <StartPrice>#{start_price}</StartPrice>
    <CategoryMappingAllowed>true</CategoryMappingAllowed>
    <ConditionID>#{condition_id}</ConditionID>
    <Country>US</Country>
    <Currency>USD</Currency>
    <DispatchTimeMax>3</DispatchTimeMax>
    <ListingDuration>#{listing_duration}</ListingDuration>
    <ListingType>#{listing_type}</ListingType>
    <PaymentMethods>#{payment_methods}</PaymentMethods>
    <PayPalEmailAddress>#{paypal_email}</PayPalEmailAddress>
    <PictureDetails>
      #{pictures.join("
")}
    </PictureDetails>
    <Location>Japan</Location>
    <Quantity>1</Quantity>
    <ReturnPolicy>
      <ReturnsAcceptedOption>#{return_accespted_option}</ReturnsAcceptedOption>
      <RefundOption>#{refund_option}</RefundOption>
      <ReturnsWithinOption>#{returns_within_option}</ReturnsWithinOption>
      <Description>If you are not satisfied, return the item for refund.</Description>
      <ShippingCostPaidByOption>Seller</ShippingCostPaidByOption>
    </ReturnPolicy>
    <ShippingDetails>
      <ShippingType>Flat</ShippingType>
      <ShippingServiceOptions>
        <ShippingServicePriority>1</ShippingServicePriority>
        <ShippingService>USPSStandardPost</ShippingService>
        <ShippingServiceCost>0</ShippingServiceCost>
      </ShippingServiceOptions>
    </ShippingDetails>
    <Site>US</Site>
  </Item>
</#{api_call_name}Request>
"

      puts "XML: #{xml}"

      response = Typhoeus::Request.post(URL, :body => xml, :headers => @header )
      hash = Hash.from_xml(response.response_body)

      puts "#{hash}"

      if api_call_name == "VerifyAddItem"
        fees = 0
        if hash["VerifyAddItemResponse"] && hash["VerifyAddItemResponse"]["Fees"] && hash["VerifyAddItemResponse"]["Fees"]["Fee"]
          hash["VerifyAddItemResponse"]["Fees"]["Fee"].each do |fee|
            fees += fee["Fee"].to_f
          end
          puts "TOTAL FEE: $#{fees}"
        end

        begin
          list_to_ebay("AddItem", params[:start_price]) if fees < 1
        rescue => ex
          warn ex.message
        end
      end
    end
  end

  def list_to_ebay_from_csv(api_call_name = "VerifyAddItem")
    CSV.open("public/amazon_com_31.csv").each_with_index do |row, i|
      next if i <= 0
      break if i == 2

      @product = Product.new
      @product.title = row[4].gsub!("&", "&amp;") + "[#{rand(10000)}]"
      @product.price = row[8]
      images = row[7].split("/")
      @product.image_url1 = "http://ecx.images-amazon.com/images/I/#{images[0]}"
      @product.image_url2 = "http://ecx.images-amazon.com/images/I/#{images[1]}"
      @product.image_url3 = "http://ecx.images-amazon.com/images/I/#{images[2]}"
      @product.image_url4 = "http://ecx.images-amazon.com/images/I/#{images[3]}"
      @product.image_url5 = "http://ecx.images-amazon.com/images/I/#{images[4]}"
      @description = row[20]
      @category_id = 1345
      # raise @product.inspect

      @header = {
        "X-EBAY-API-DEV-NAME" => DEVID,
        "X-EBAY-API-APP-NAME" => APPID,
        "X-EBAY-API-CERT-NAME" => CERTID,
        "X-EBAY-API-CALL-NAME" => api_call_name,
        "X-EBAY-API-COMPATIBILITY-LEVEL" => API_COMPATIBILITY_LEVEL,
        "X-EBAY-API-SITEID" => EBAY_API_SITEID,
        "Content-Type" => "text/xml",
      }

      description = @description
      # start_price = (@product.price*0.95).round(0)
      start_price = @product.price.round(0)
      condition_id = 1000
      listing_duration = "Days_3"
      listing_type = "Chinese"
      payment_methods = "PayPal"
      paypal_email = "hiroyuki.kondo@chishaku.com"

      pictures = Array.new
      pictures << "<PictureURL>#{@product.image_url1}</PictureURL>" unless @product.image_url1.blank?
      pictures << "<PictureURL>#{@product.image_url2}</PictureURL>" unless @product.image_url2.blank?
      pictures << "<PictureURL>#{@product.image_url3}</PictureURL>" unless @product.image_url3.blank?
      pictures << "<PictureURL>#{@product.image_url4}</PictureURL>" unless @product.image_url4.blank?
      pictures << "<PictureURL>#{@product.image_url5}</PictureURL>" unless @product.image_url5.blank?

      return_accespted_option = "ReturnsAccepted"
      refund_option = "MoneyBack"
      returns_within_option = "Days_30"

      xml = "
<?xml version='1.0' encoding='utf-8'?>
<#{api_call_name}Request xmlns='urn:ebay:apis:eBLBaseComponents'>
  <RequesterCredentials>
    <eBayAuthToken>#{TOKEN}</eBayAuthToken>
  </RequesterCredentials>
  <ErrorLanguage>en_US</ErrorLanguage>
  <WarningLevel>High</WarningLevel>
  <Item>
    <Title>#{@product.title}</Title>
    <Description>#{description}</Description>
    <PrimaryCategory>
      <CategoryID>#{@category_id}</CategoryID>
    </PrimaryCategory>
    <StartPrice>#{start_price}</StartPrice>
    <CategoryMappingAllowed>true</CategoryMappingAllowed>
    <ConditionID>#{condition_id}</ConditionID>
    <Country>US</Country>
    <Currency>USD</Currency>
    <DispatchTimeMax>3</DispatchTimeMax>
    <ListingDuration>#{listing_duration}</ListingDuration>
    <ListingType>#{listing_type}</ListingType>
    <PaymentMethods>#{payment_methods}</PaymentMethods>
    <PayPalEmailAddress>#{paypal_email}</PayPalEmailAddress>
    <PictureDetails>
      #{pictures.join("
")}
    </PictureDetails>
    <Location>Japan</Location>
    <Quantity>1</Quantity>
    <ReturnPolicy>
      <ReturnsAcceptedOption>#{return_accespted_option}</ReturnsAcceptedOption>
      <RefundOption>#{refund_option}</RefundOption>
      <ReturnsWithinOption>#{returns_within_option}</ReturnsWithinOption>
      <Description>If you are not satisfied, return the item for refund.</Description>
      <ShippingCostPaidByOption>Seller</ShippingCostPaidByOption>
    </ReturnPolicy>
    <ShippingDetails>
      <ShippingType>Flat</ShippingType>
      <ShippingServiceOptions>
        <ShippingServicePriority>1</ShippingServicePriority>
        <ShippingService>USPSStandardPost</ShippingService>
        <ShippingServiceCost>0</ShippingServiceCost>
      </ShippingServiceOptions>
    </ShippingDetails>
    <Site>US</Site>
  </Item>
</#{api_call_name}Request>
"

      puts "XML: #{xml}"
      response = Typhoeus::Request.post(URL, :body => xml, :headers => @header )
      hash = Hash.from_xml(response.response_body)
      puts "#{hash}"

      fees = 0
      if hash["VerifyAddItemResponse"] && hash["VerifyAddItemResponse"]["Fees"] && hash["VerifyAddItemResponse"]["Fees"]["Fee"]
        hash["VerifyAddItemResponse"]["Fees"]["Fee"].each do |fee|
          fees += fee["Fee"].to_f
        end
        puts "TOTAL FEE: $#{fees}"
      end

      raise hash.inspect

      begin
        list_to_ebay_from_csv("AddItem") if fees < 1
      rescue => ex
        warn ex.message
      end
      raise hash.inspect
    end
  end
end
