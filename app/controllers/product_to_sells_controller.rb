require 'csv'

class ProductToSellsController < ApplicationController
  before_action :set_product_to_sell, only: [:show, :edit, :update, :destroy]
  before_action :read_exchange_rate
  after_action :list_to_ebay, only: :update
  before_filter :set_locale, only: [:index]
  after_filter :remember_previous_page, only: :index

  # @@app_id = "Chishaku-8e8f-48de-a23a-e1304518388d" # sandbox
  @@app_id = "Chishaku-0efe-4739-a2ff-dba4724f0514" # production

  @@amazon_affiliate_link = "http://www.amazon.com/?_encoding=UTF8&camp=1789&creative=9325&linkCode=ur2&tag=chishaku-20&linkId=AOXRRTZSW6246HKX"
  @@return_accespted_option = "ReturnsAccepted"
  @@refund_option = "MoneyBack"
  @@returns_within_option = "Days_30"
  @@refund_description = "If for any reason you are not satisfied with your order, simply send it back to us. You are responsible for return shipping. Once your return is processed, you will receive a refund for the amount paid for the returned item back to the original method of payment. Any outbound shipping charges paid will not be refunded if the order is returned. All merchandise must be the same condition it was received."

  # GET /product_to_sells
  # GET /product_to_sells.json
  def index
    set_categories

    @conditions = Array.new
    @orders = Array.new

    @conditions << "price >= #{params[:low_price]}" unless params[:low_price].blank?
    @conditions << "price <= #{params[:high_price]}" unless params[:high_price].blank?
    @conditions << "category = '#{params[:category]}'" unless params[:category].blank?
    @conditions << "listed = TRUE" if params[:listed] == "1"
    @conditions << "listed IS NOT TRUE" if params[:unlisted] == "1"

    if params[:sales_rank]
      @conditions << "sales_rank IS NOT NULL"
      @orders << "sales_rank ASC"
    end

    if params[:manufacturer]
      @conditions << "manufacturer = '#{params[:manufacturer]}'"
    end

    @orders = Array.new
    @orders << "products.category"
    @orders << "product_to_sells.created_at DESC"

    @product_to_sells = ProductToSell.joins(:product).where(@conditions.join(" AND ")).order(@orders.join(", ")).page params[:page]

    @profit_hash = Product.where(["id IN (?)", @product_to_sells.pluck(:product_id)]).inject(Hash.new(nil)) {|h, p|
      h[p.id] = (p.price * (1 - 0.1 - 0.039) - 0.3) * @exchange_rate - p.shipping_cost - p.cost if p.price && p.cost; h
    }

    set_ebay_data_for_multiple_products(@product_to_sells.pluck(:product_id))
  end

  # GET /product_to_sells/1
  # GET /product_to_sells/1.json
  def show
    @profit = (@product_to_sell.product.price * (1 - 0.1 - 0.039) - 0.3) * @exchange_rate - @product_to_sell.product.shipping_cost - @product_to_sell.product.cost  if @product_to_sell.product.price && @product_to_sell.product.shipping_cost && @product_to_sell.product.cost
    set_ebay_data_for_single_product(@product_to_sell.product.id)
    @profit = (@average * (1 - 0.1 - 0.039) - 0.3)*@exchange_rate - @product_to_sell.product.cost - @product_to_sell.product.shipping_cost if @average && @product_to_sell.product.cost && @product_to_sell.product.shipping_cost
  end

  # GET /product_to_sells/new
  def new
    @product_to_sell = ProductToSell.new
  end

  # GET /product_to_sells/1/edit
  def edit
    set_ebay_data_for_single_product(@product_to_sell.product.id)

    @start_price = (@product_to_sell.product.cost / @exchange_rate) * 1.3.ceil
    if @start_price > @product_to_sell.product.price
      @start_price = (@product_to_sell.product.price * 0.97).round(1)
    end

    @start_price = @average if @average && @average > @start_price
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

  # POST /product_to_sells/refresh
  # POST /product_to_sells/refresh.json
  def refresh
    ProductToSell.all.each_with_index do |p, i|
      lookup p.product.asin
    end
    redirect_to product_to_sells_path
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
    session[:previous_page] = request.env['HTTP_REFERER'] || product_to_sells_url
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
      descriptions << "Free international shipping from Japan"

      if start_price.blank?
        # start_price = (@product.price*0.95).round(0)
        start_price = @product.price.round(0)
      end
      condition_id = 1000
      listing_duration = "Days_5"
      listing_type = "Chinese"
      payment_methods = "PayPal"
      paypal_email = "crudo@hiroyukikondo.com"

      pictures = Array.new
      pictures << "<PictureURL>#{@product.image_url1}</PictureURL>" unless @product.image_url1.blank?
      pictures << "<PictureURL>#{@product.image_url2}</PictureURL>" unless @product.image_url2.blank?
      pictures << "<PictureURL>#{@product.image_url3}</PictureURL>" unless @product.image_url3.blank?
      pictures << "<PictureURL>#{@product.image_url4}</PictureURL>" unless @product.image_url4.blank?
      pictures << "<PictureURL>#{@product.image_url5}</PictureURL>" unless @product.image_url5.blank?

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
    <Country>JP</Country>
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
    <Location>Fukuoka</Location>
    <Quantity>1</Quantity>
    <ReturnPolicy>
      <ReturnsAcceptedOption>#{@@return_accespted_option}</ReturnsAcceptedOption>
      <RefundOption>#{@@refund_option}</RefundOption>
      <ReturnsWithinOption>#{@@returns_within_option}</ReturnsWithinOption>
      <Description>#{@@refund_description}</Description>
      <ShippingCostPaidByOption>Buyer</ShippingCostPaidByOption>
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

      puts hash

      if api_call_name == "VerifyAddItem"
        fees = 0
        if hash["VerifyAddItemResponse"] && hash["VerifyAddItemResponse"]["Fees"] && hash["VerifyAddItemResponse"]["Fees"]["Fee"]
          fees = hash["VerifyAddItemResponse"]["Fees"]["Fee"].inject(0) {|sum, i| sum += i["Fee"].to_f; sum}
          # hash["VerifyAddItemResponse"]["Fees"]["Fee"].each do |fee|
          #   fees += fee["Fee"].to_f
          # end
        end
        puts "TOTAL FEE: $#{fees}"

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
    <Country>JP</Country>
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
    <Location>Fukuoka</Location>
    <Quantity>1</Quantity>
    <ReturnPolicy>
      <ReturnsAcceptedOption>#{@@return_accespted_option}</ReturnsAcceptedOption>
      <RefundOption>#{@@refund_option}</RefundOption>
      <ReturnsWithinOption>#{@@returns_within_option}</ReturnsWithinOption>
      <Description>#{@@refund_description}</Description>
      <ShippingCostPaidByOption>Buyer</ShippingCostPaidByOption>
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

      # fees = 0
      if hash["VerifyAddItemResponse"] && hash["VerifyAddItemResponse"]["Fees"] && hash["VerifyAddItemResponse"]["Fees"]["Fee"]
        fees = hash["VerifyAddItemResponse"]["Fees"]["Fee"].inject(0) {|sum, i| sum += i["Fee"].to_f; sum}
        # hash["VerifyAddItemResponse"]["Fees"]["Fee"].each do |fee|
        #   fees += fee["Fee"].to_f
        # end
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
end
