# -*- coding: utf-8 -*-
require "open-uri"
require "mechanize"
require "httpclient"
require "csv"
require "twitter"

# -*- coding: utf-8 -*-
class Product < ActiveRecord::Base
  has_many :ebay_items
  validates :asin, presence: true
  validates :asin, uniqueness: true
  acts_as_paranoid

  before_save :calculate_cost

  @@exchange_rate = open("public/exchange_rate.txt", "r").read.to_i

  def calculate_cost
    weight = self.weight.to_f / 100 * 0.454
    # 小形包装物
    #   長さ＋幅＋厚さ＝90cm ただし、長さの最大は60cm (許容差 2mm)
    # 巻物については
    #   長さ＋直径の2倍＝104cm ただし、長さの最大は90cm (許容差 2mm)

    # # 小形包装物 航空便
    # if weight * 1.1 <= 0.05
    #   self.shipping_cost = 150
    # elsif weight * 1.1 <= 0.1
    #   self.shipping_cost = 240
    # elsif weight * 1.1 <= 0.15
    #   self.shipping_cost = 330
    # elsif weight * 1.1 <= 0.2
    #   self.shipping_cost = 420
    # elsif weight * 1.1 <= 0.25
    #   self.shipping_cost = 510
    # elsif weight * 1.1 <= 0.3
    #   self.shipping_cost = 600
    # elsif weight * 1.1 <= 0.35
    #   self.shipping_cost = 690
    # elsif weight * 1.1 <= 0.4
    #   self.shipping_cost = 780
    # elsif weight * 1.1 <= 0.45
    #   self.shipping_cost = 870
    # elsif weight * 1.1 <= 0.5
    #   self.shipping_cost = 960
    # elsif weight * 1.1 <= 0.55
    #   self.shipping_cost = 1050
    # elsif weight * 1.1 <= 0.6
    #   self.shipping_cost = 1140
    # elsif weight * 1.1 <= 0.65
    #   self.shipping_cost = 1230
    # elsif weight * 1.1 <= 0.7
    #   self.shipping_cost = 1320
    # elsif weight * 1.1 <= 0.75
    #   self.shipping_cost = 1410
    # elsif weight * 1.1 <= 0.8
    #   self.shipping_cost = 1500
    # elsif weight * 1.1 <= 0.85
    #   self.shipping_cost = 1590
    # elsif weight * 1.1 <= 0.9
    #   self.shipping_cost = 1680
    # elsif weight * 1.1 <= 0.95
    #   self.shipping_cost = 1770
    # elsif weight * 1.1 <= 1
    #   self.shipping_cost = 1860
    # elsif weight * 1.1 <= 1.25
    #   self.shipping_cost = 2085
    # elsif weight * 1.1 <= 1.5
    #   self.shipping_cost = 2310
    # elsif weight * 1.1 <= 1.75
    #   self.shipping_cost = 2535
    # elsif weight * 1.1 <= 2
    #   self.shipping_cost = 2760

    # 小形包装物 SAL
    if weight * 1.1 <= 0.1
      self.shipping_cost = 180
    elsif weight * 1.1 <= 0.2
      self.shipping_cost = 280
    elsif weight * 1.1 <= 0.3
      self.shipping_cost = 380
    elsif weight * 1.1 <= 0.4
      self.shipping_cost = 480
    elsif weight * 1.1 <= 0.5
      self.shipping_cost = 580
    elsif weight * 1.1 <= 0.6
      self.shipping_cost = 680
    elsif weight * 1.1 <= 0.7
      self.shipping_cost = 780
    elsif weight * 1.1 <= 0.8
      self.shipping_cost = 880
    elsif weight * 1.1 <= 0.9
      self.shipping_cost = 980
    elsif weight * 1.1 <= 1
      self.shipping_cost = 1080
    elsif weight * 1.1 <= 1.1
      self.shipping_cost = 1180
    elsif weight * 1.1 <= 1.2
      self.shipping_cost = 1280
    elsif weight * 1.1 <= 1.3
      self.shipping_cost = 1380
    elsif weight * 1.1 <= 1.4
      self.shipping_cost = 1480
    elsif weight * 1.1 <= 1.5
      self.shipping_cost = 1580
    elsif weight * 1.1 <= 1.6
      self.shipping_cost = 1680
    elsif weight * 1.1 <= 1.7
      self.shipping_cost = 1780
    elsif weight * 1.1 <= 1.8
      self.shipping_cost = 1880
    elsif weight * 1.1 <= 1.9
      self.shipping_cost = 1980
    elsif weight * 1.1 <= 2
      self.shipping_cost = 2080

    # # e-packet
    # if weight * 1.1 <= 0.05
    #   self.shipping_cost = 560
    # elsif weight * 1.1 <= 0.1
    #   self.shipping_cost = 635
    # elsif weight * 1.1 <= 0.15
    #   self.shipping_cost = 710
    # elsif weight * 1.1 <= 0.2
    #   self.shipping_cost = 785
    # elsif weight * 1.1 <= 0.25
    #   self.shipping_cost = 860
    # elsif weight * 1.1 <= 0.3
    #   self.shipping_cost = 935
    # elsif weight * 1.1 <= 0.4
    #   self.shipping_cost = 1085
    # elsif weight * 1.1 <= 0.5
    #   self.shipping_cost = 1235
    # elsif weight * 1.1 <= 0.6
    #   self.shipping_cost = 1385
    # elsif weight * 1.1 <= 0.7
    #   self.shipping_cost = 1535
    # elsif weight * 1.1 <= 0.8
    #   self.shipping_cost = 1685
    # elsif weight * 1.1 <= 0.9
    #   self.shipping_cost = 1835
    # elsif weight * 1.1 <= 1.0
    #   self.shipping_cost = 1985
    # elsif weight * 1.1 <= 1.25
    #   self.shipping_cost = 2255
    # elsif weight * 1.1 <= 1.5
    #   self.shipping_cost = 2525
    # elsif weight * 1.1 <= 1.75
    #   self.shipping_cost = 2795
    # elsif weight * 1.1 <= 2.0
    #   self.shipping_cost = 3065
    # end

    #国際小包SAL便
    # elsif weight * 1.1 <= 1
    #   self.shipping_cost = 2700
    # elsif weight * 1.1 <= 2
    #   self.shipping_cost = 3850
    elsif weight * 1.1 <= 3
      self.shipping_cost = 5000
    elsif weight * 1.1 <= 4
      self.shipping_cost = 6150
    elsif weight * 1.1 <= 5
      self.shipping_cost = 7300
    elsif weight * 1.1 <= 6
      self.shipping_cost = 8350
    elsif weight * 1.1 <= 7
      self.shipping_cost = 9400
    elsif weight * 1.1 <= 8
      self.shipping_cost = 10450
    elsif weight * 1.1 <= 9
      self.shipping_cost = 11500
    elsif weight * 1.1 <= 10
      self.shipping_cost = 12550
    elsif weight * 1.1 <= 11
      self.shipping_cost = 13250
    elsif weight * 1.1 <= 12
      self.shipping_cost = 13950
    elsif weight * 1.1 <= 13
      self.shipping_cost = 14650
    elsif weight * 1.1 <= 14
      self.shipping_cost = 15350
    elsif weight * 1.1 <= 15
      self.shipping_cost = 16050
    elsif weight * 1.1 <= 16
      self.shipping_cost = 16750
    elsif weight * 1.1 <= 17
      self.shipping_cost = 17450
    elsif weight * 1.1 <= 18
      self.shipping_cost = 18150
    elsif weight * 1.1 <= 19
      self.shipping_cost = 18850
    elsif weight * 1.1 <= 20
      self.shipping_cost = 19550
    elsif weight * 1.1 <= 21
      self.shipping_cost = 20250
    elsif weight * 1.1 <= 22
      self.shipping_cost = 20950
    elsif weight * 1.1 <= 23
      self.shipping_cost = 21650
    elsif weight * 1.1 <= 24
      self.shipping_cost = 22350
    elsif weight * 1.1 <= 25
      self.shipping_cost = 23050
    elsif weight * 1.1 <= 26
      self.shipping_cost = 23750
    elsif weight * 1.1 <= 27
      self.shipping_cost = 24450
    elsif weight * 1.1 <= 28
      self.shipping_cost = 25150
    elsif weight * 1.1 <= 29
      self.shipping_cost = 25850
    elsif weight * 1.1 <= 30
      self.shipping_cost = 26550

    #ヤマト交際パーセルサービス
    # elsif weight * 1.1 <= 1
    #   self.shipping_cost = 1200
    # elsif weight * 1.1 <= 2
    #   self.shipping_cost = 2750
    # elsif weight * 1.1 <= 5
    #   self.shipping_cost = 4650
    # elsif weight * 1.1 <= 10
    #   self.shipping_cost = 8850
    # elsif weight * 1.1 <= 15
    #   self.shipping_cost = 15050
    # elsif weight * 1.1 <= 20
    #   self.shipping_cost = 20550
    # elsif weight * 1.1 <= 25
    #   self.shipping_cost = 26050
    end

    self.shipping_cost += 410 if self.price >= 50

    if self.price && self.cost
      begin
        self.profit = Product.calculate_profit_on_amazon(self)
      rescue => ex
        p ex.message
        self.profit = nil
      end
    end
  end

  def self.get_exchange_rate
    begin
      agent = Mechanize.new
      agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
      page = agent.get("https://www.google.com/finance/converter?a=1&from=USD&to=JPY")
      rate = page.search("span[class='bld']").text.sub!(" JPY", "").to_f
      p rate

      file = open("public/exchange_rate.txt", "w")
      file.puts rate
      file.close
    rescue => ex
      warn ex.message
    end
  end

  def self.search
    request = Vacuum.new()
    request.configure(
                      aws_access_key_id: AWS_ACCESS_KEY_ID,
                      aws_secret_access_key: AWS_SECRET_ACCESS_KEY,
                      associate_tag: ASSOCIATE_TAG
                      )
    SearchIndex.all.each_with_index do |search_index, i|
      search_index.sort_values.each do |sort_value|
        for i in 1..10
          parameters = {
            "SearchIndex" => search_index.name,
            "Keywords" => "japan",
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
  end

  def self.lookup(asin)
    Product.get_exchange_rate

    request = Vacuum.new()
    request.configure(aws_access_key_id: AWS_ACCESS_KEY_ID,
                      aws_secret_access_key: AWS_SECRET_ACCESS_KEY,
                      associate_tag: ASSOCIATE_TAG)
    parameters = {
      # "Condition" => "New",
      "ItemId" => asin,
      # "MerchantId" => "Amazon",
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

      if product = save_product(item)
        find_ebay_completed_items(product.title, product.id)

        average = product.ebay_items.inject(Array.new) {|a, ei|
          a << ei.current_price_value if ei.selling_state == "EndedWithSales";
          puts "SOLD ON EBAY AT:#{ei.current_price_value}"; a
        }

        if average.size > 0
          product.update_attribute(:ebay_average, average.inject{ |sum, el| sum + el }.to_f / average.size)
          puts "EBAY PROFIT: #{product.ebay_average}"
        end
      end
    else
      puts response["ItemLookupResponse"]["Items"]["Request"]["Errors"]
    end
  end

  def self.save_product(item)
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

    begin
      agent = Mechanize.new

      p "Scrape Amazon price form #{product.url}"

      page = agent.get(product.url)
      amazon_price = page.search("span[id='priceblock_ourprice']").text.sub!("$", "").to_f
      p "Amazon Price: #{amazon_price}"

      product.price = amazon_price
    rescue => ex
      warn ex.message
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

  def self.find_ebay_completed_items(keyword, product_id)
    # app_id = "Chishaku-8e8f-48de-a23a-e1304518388d" # sandbox
    app_id = "Chishaku-0efe-4739-a2ff-dba4724f0514" # production

    keyword.gsub!(/(japan|Japan|JAPAN|import|Import|IMPORT|new|New|NEW)/,"")
    p "Keyword: #{keyword}"

    url = "http://svcs.ebay.com/services/search/FindingService/v1?OPERATION-NAME=findCompletedItems&SERVICE-VERSION=1.0.0&SECURITY-APPNAME=#{app_id}&RESPONSE-DATA-FORMAT=JSON&REST-PAYLOAD&keywords=#{URI.escape(keyword)}"
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

  def self.import_from_csv
    file_path = "public/amazon_com_31.csv"
    CSV.open(file_path).each_with_index do |row, i|
      next if i <= 0
      asin = row[5]
      self.lookup(asin)
    end
  end

  def self.refresh(asin = nil)
    if asin
      Product.lookup asin
    else
      Product.find_each(batch_size: 10) do |p|
        Product.lookup p.asin
      end
    end
  end

  def self.calculate_profit_on_amazon(product)
    if product.shipping_cost && product.cost
      (product.price * (1 - 0.15) - 1) * @@exchange_rate - product.shipping_cost - product.cost
    end
  end

  def self.calculate_profit_on_ebay(product, price = product.price)
    if product.shipping_cost && product.cost
      (price * (1 - 0.1 - 0.039) - 0.3) * @@exchange_rate * 0.96 - product.shipping_cost - product.cost
    end
  end

  def self.check_profit_on_ebay(price, supply_cost, weight)
    exchange_rate = open("public/exchange_rate.txt", "r").read.to_f

    weight = weight.to_f / 100 * 0.454
    # 小形包装物 SAL
    if weight * 1.1 <= 0.1
      shipping_cost = 180
    elsif weight * 1.1 <= 0.2
      shipping_cost = 280
    elsif weight * 1.1 <= 0.3
      shipping_cost = 380
    elsif weight * 1.1 <= 0.4
      shipping_cost = 480
    elsif weight * 1.1 <= 0.5
      shipping_cost = 580
    elsif weight * 1.1 <= 0.6
      shipping_cost = 680
    elsif weight * 1.1 <= 0.7
      shipping_cost = 780
    elsif weight * 1.1 <= 0.8
      shipping_cost = 880
    elsif weight * 1.1 <= 0.9
      shipping_cost = 980
    elsif weight * 1.1 <= 1
      shipping_cost = 1080
    elsif weight * 1.1 <= 1.1
      shipping_cost = 1180
    elsif weight * 1.1 <= 1.2
      shipping_cost = 1280
    elsif weight * 1.1 <= 1.3
      shipping_cost = 1380
    elsif weight * 1.1 <= 1.4
      shipping_cost = 1480
    elsif weight * 1.1 <= 1.5
      shipping_cost = 1580
    elsif weight * 1.1 <= 1.6
      shipping_cost = 1680
    elsif weight * 1.1 <= 1.7
      shipping_cost = 1780
    elsif weight * 1.1 <= 1.8
      shipping_cost = 1880
    elsif weight * 1.1 <= 1.9
      shipping_cost = 1980
    elsif weight * 1.1 <= 2
      shipping_cost = 2080
    end

    # # e-packet
    # if weight * 1.1 <= 0.05
    #   shipping_cost = 560
    # elsif weight * 1.1 <= 0.1
    #   shipping_cost = 635
    # elsif weight * 1.1 <= 0.15
    #   shipping_cost = 710
    # elsif weight * 1.1 <= 0.2
    #   shipping_cost = 785
    # elsif weight * 1.1 <= 0.25
    #   shipping_cost = 860
    # elsif weight * 1.1 <= 0.3
    #   shipping_cost = 935
    # elsif weight * 1.1 <= 0.4
    #   shipping_cost = 1085
    # elsif weight * 1.1 <= 0.5
    #   shipping_cost = 1235
    # elsif weight * 1.1 <= 0.6
    #   shipping_cost = 1385
    # elsif weight * 1.1 <= 0.7
    #   shipping_cost = 1535
    # elsif weight * 1.1 <= 0.8
    #   shipping_cost = 1685
    # elsif weight * 1.1 <= 0.9
    #   shipping_cost = 1835
    # elsif weight * 1.1 <= 1.0
    #   shipping_cost = 1985
    # elsif weight * 1.1 <= 1.25
    #   shipping_cost = 2255
    # elsif weight * 1.1 <= 1.5
    #   shipping_cost = 2525
    # elsif weight * 1.1 <= 1.75
    #   shipping_cost = 2795
    # elsif weight * 1.1 <= 2.0
    #   shipping_cost = 3065
    # end

    shipping_cost += 410 if price >= 50

    p "Exchange Rate: #{exchange_rate}"
    p "Shipping Cost #{shipping_cost}"
    p "Supply Cost: #{supply_cost}"
    p "PayPal Cost: #{((price * (1 - 0.1 - 0.039) - 0.3) * exchange_rate * 0.04).round}"
    profit = ((price * (1 - 0.1 - 0.039) - 0.3) * exchange_rate * 0.96 - shipping_cost - supply_cost).round
    p "Profit: #{profit}"

    minimum_price = ((1.1 * (shipping_cost + supply_cost))/(0.96 * 0.861 * exchange_rate) + 0.3/0.861).round
    p "Minimum Price: #{minimum_price}"

    if price >= minimum_price
      "Sell it"
    else
      "Find another one"
    end
  end

  def self.get_amazon_images(url)
    @destination = "#{Etc.getpwuid.dir}/Downloads/amazon"
    unless File.exists?(@destination)
      Dir.mkdir @destination
    end

    if url != ""
      agent = Mechanize.new

      begin
        page = agent.get(url)
        title = page.search("#productTitle").text
        p title
        images = page.search("span[class='a-button-text'] img")
        images.each_with_index do |image, i|
          path = image.attr("src").sub!("._SS40_", "")
          p path
          /.+\.([a-z]+)$/ =~ path
          extention = $1
          get_content(path, title, "#{i}.#{extention}")
        end
      rescue TimeoutError
        warn "TimeoutError"
      rescue Mechanize::ResponseCodeError => ex
        case ex.response_code
        when "404" then
          warn "404: #{ex.page.uri} does not exist"
        when "503" then
          # follows RFC2616
          if @retryuri != url && sec = ex.page.header["Retry-After"]
            warn "503: will retry #{ex.page.uri} in #{sec}seconds"
            @retryuri = ex.page.uri
            sleep sec.to_i
            retry
          end
        when /\A5/ then
          warn "#{ex.response_code}: internal error"
        else
          warn ex.message
        end
      end
    end
  end

  def get_content(uri, folder, file_name)
    hc = HTTPClient.new
    begin
      content = hc.get_content(uri, :get, {})
    rescue
    end

    if content.nil? || content.size < 10
      p "file not found from #{uri}."
      return false
    else
      destination = "#{@destination}/#{folder.gsub('/', ' ')}"
      unless File.exists?(destination)
        Dir.mkdir destination
      end

      if File.exists?("#{destination}/#{file_name}")
        p "#{file_name} already exists."
        return
      end

      File.open("#{destination}/#{file_name}", "w") do |f|
        f.print content
        p "#{file_name} saved from #{uri}."
      end
    end
  end

def self.tweet
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = "pi372r3MegfGH4XbqKW2GgVCR"
      config.consumer_secret     = "mC9B356xFZs7EjQzPE5MQz1jWDNq9Dl1OX3p8OOFsfXSv6dVps"
      config.access_token        = "3269536514-rwiAuCrgJ3c3fk53IE7rEo9krRFwguBG7kmjxK8"
      config.access_token_secret = "lxqieZET0XgEHVqEgoeJHSvJpgrQk9ttsjXNElvQBr9PV"
    end

    product = Product.where("profit > 1000").order("RAND()").limit(1).first
    if product.price
      rate = open("public/exchange_rate.txt", "r").read.to_f.round(2)

      # tweet
      Bitly.use_api_version_3
      Bitly.configure do |config|
        config.api_version = 3
        config.access_token = "c7b6ba72ff78178e3e0cc063f4823820ba2dfb01"
      end
      url = Bitly.client.shorten("http://amazon.crudoe.com/products/#{product.id}").short_url
      # image_url = Bitly.client.shorten(product.image_url1).short_url

      text = "米国で$#{product.price}、日本では#{product.cost}円のこの商品は、諸経費を除いて#{product.profit}円の利益が見込めるようです。詳細はこちら => #{url}"
      tags = [" #amazon輸出", " #副業", " #ネットビジネス", " #せどり", " #オークション"]
      tags.each do |t|
        if text.size + t.size < 110
          text += t
        end
      end

      if product.image_url1
        if product.image_url5
          image = open(product.image_url5)
        elsif product.image_url4
          image = open(product.image_url4)
        elsif product.image_url3
          image = open(product.image_url3)
        elsif product.image_url2
          image = open(product.image_url2)
        elsif product.image_url1
          image = open(product.image_url1)
        end
        if image.is_a?(StringIO)
          ext = File.extname(url)
          name = File.basename(url, ext)
          Tempfile.new([name, ext])
        else
          image
        end
        client.update_with_media(text, image)
      else
        client.update(text)
      end
    else
      Product.tweet
    end
  end
end
