require 'open-uri'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # @@app_id = "Chishaku-8e8f-48de-a23a-e1304518388d" # sandbox
  @@app_id = "Chishaku-0efe-4739-a2ff-dba4724f0514" # production
  @@categories = nil

  def get_exchange_rate
    begin
      file = open("public/exchange_rate.txt", "w")
      api = "http://www.freecurrencyconverterapi.com/api/v2/convert?q=USD_JPY&compact=y"
      source = open(api).read()
      json = JSON.parse(source)
      exchange_rate = json["USD_JPY"]["val"]
      file.puts exchange_rate

      # puts "EXCHANGE RATE FROM API:#{exchange_rate}"
    rescue => ex
      warn ex.message
    end
  end

  def read_exchange_rate
    @exchange_rate = open("public/exchange_rate.txt", "r").read.to_f.round(2)
    # puts "EXCHANGE RATE FROM FILE:#{@exchange_rate}"
  end

  def save_product(item)
    product = Product.new
    begin
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
    rescue => ex
      warn ex.message
    end

    puts "TITLE:#{product.title}"
    puts "URL:#{product.url}"

    if item["ImageSets"] && item["ImageSets"]["ImageSet"].instance_of?(Array)
      for j in 0..4
        if !item["ImageSets"]["ImageSet"][j].blank?
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
    elsif item["ImageSets"] && item["ImageSets"]["ImageSet"]
      product.image_url1 = item["ImageSets"]["ImageSet"]["LargeImage"]["URL"]
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
      saved_product
    else
      begin
        product.save
        Category.create(name: product.category) unless Category.where(["name = ?", product.category]).first
        product
      rescue => ex
        warn ex.message
      end
    end
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

      puts item

      product = save_product(item)
      find_ebay_completed_items(product.title, product.id)

      average = product.ebay_items.inject(Array.new) {|a, ei|
        a << ei.current_price_value if ei.selling_state == "EndedWithSales";
        puts "SOLD ON EBAY AT:#{ei.current_price_value}"; a
      }

      if average.size > 0
        product.update_attribute(:ebay_average, average.inject{ |sum, el| sum + el }.to_f / average.size)
        puts "EBAY PROFIT: #{product.ebay_average}"
      end
    else
      puts response["ItemLookupResponse"]["Items"]["Request"]["Errors"]
    end
  end

  def set_locale
    case params[:locale]
    when "USD"
      @locale = "USD"
    else
      @locale = "USD"
    end
  end

  def set_categories
    if @@categories.nil?
      @@categories = Product.group(:category).order(:category).inject(Array.new) {|a, p| a << [p.category, p.category]; a}
    end
    @categories = @@categories
  end

  def set_ebay_data_for_single_product(id)
    set_locale

    @ebay_items = EbayItem.where(["product_id = ?", id]).order("end_time DESC")
    @sold_items = EbayItem.where(["product_id = ? AND current_price_currency_id = ? AND selling_state = ?",
                                  id,
                                  @locale,
                                  "EndedWithSales"])
    @average = (@sold_items.pluck(:current_price_value).inject{ |sum, price| sum + price }.to_f / @sold_items.size).round(1) if @sold_items.count > 0
  end

  def set_ebay_data_for_multiple_products(id_array, condition = "current_price_value")
    set_locale
    ebay_items = EbayItem.where(["product_id IN (?)", id_array]).order(condition)
    @ebay_items = ebay_items.inject(Hash.new {|hash, key| hash[key] = Array.new}) {|h, ei|
      h[ei.product_id] << ei.try(:current_price_value) if ei.current_price_currency_id == @locale; h
    }

    @sold_items = ebay_items.inject(Hash.new {|hash, key| hash[key] = Array.new}) {|h, ei|
      h[ei.product_id] << ei.try(:current_price_value) if ei.current_price_currency_id == @locale && ei.selling_state == "EndedWithSales"; h
    }

    @averages = @sold_items.inject(Hash.new {|hash, key| hash[key] = 0}) {|h, (key, value)| h[key] = (value.sum/value.size).round(2); h}
  end
end
