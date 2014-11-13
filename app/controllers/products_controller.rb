class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  # GET /products
  # GET /products.json
  def index
    @products = Product.order("profit DESC").page params[:page]
    @exchange_rate = 115
    @shipping_cost = 1080
  end

  # GET /products/1
  # GET /products/1.json
  def show
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
    request = Vacuum.new()
    request.configure(
                      aws_access_key_id: AWS_ACCESS_KEY_ID,
                      aws_secret_access_key: AWS_SECRET_ACCESS_KEY,
                      associate_tag: ASSOCIATE_TAG
                      )
    SearchIndex.all.each do |search_index|
      search_index.sort_values.each do |sort_value|
        puts "SEARCH_INDEX:#{search_index.name}, SORT_VALUE:#{sort_value.name}"
        for i in 1..10
          parameters = {
            "SearchIndex" => search_index.name,
            "Keywords" => params[:search],
            "ResponseGroup" => "Medium",
            "Sort" => sort_value.name,
            "ItemPage" => i
          }

          begin
            response = request.item_search(query: parameters).to_h
          rescue TimeoutError
            warn "TimeoutError"
          rescue  => ex
            case ex
              # when "404" then
              #   warn "404: #{ex.page.uri} does not exist"
            when "Excon::Errors::ServiceUnavailable: Expected(200) <=> Actual(503 Service Unavailable)" then
              # follows RFC2616
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

          response["ItemSearchResponse"]["Items"]["Item"].each do |item|
            # puts item

            product = Product.new
            product.asin = item["ASIN"]
            product.group = item["ItemAttributes"]["ProductGroup"]
            product.manufacturer = item["ItemAttributes"]["Manufacturer"]
            product.model = item["ItemAttributes"]["Model"]
            product.title = item["ItemAttributes"]["Title"]
            product.color = item["ItemAttributes"]["Color"]
            product.size = item["ItemAttributes"]["Size"]
            product.features = item["ItemAttributes"]["Feature"].join(",") if item["ItemAttributes"]["Feature"].class == "Array"
            product.sales_rank = item["SalesRank"]
            product.url = item["DetailPageURL"]
            
            puts "TITLE:#{product.title}"
            puts "URL:#{product.url}"

            for i in 0..4
              begin
                if item["ImageSets"]["ImageSet"][i]
                  case i
                  when 0
                    product.image_url1 = item["ImageSets"]["ImageSet"][0]["LargeImage"]["URL"]
                  when 1
                    product.image_url2 = item["ImageSets"]["ImageSet"][1]["LargeImage"]["URL"]
                  when 2
                    product.image_url3 = item["ImageSets"]["ImageSet"][2]["LargeImage"]["URL"]
                  when 3
                    product.image_url4 = item["ImageSets"]["ImageSet"][3]["LargeImage"]["URL"]
                  when 4
                    product.image_url5 = item["ImageSets"]["ImageSet"][4]["LargeImage"]["URL"]
                  end
                end
              rescue => ex
                warn ex.message
              end
            end

            begin
              product.currency = item["OfferSummary"]["LowestNewPrice"]["CurrencyCode"]
              product.price = (item["OfferSummary"]["LowestNewPrice"]["Amount"].to_f/100).round(2)
            rescue => ex
              warn ex.message
            end

            sleep 1

            request2 = Vacuum.new("JP")
            request2.configure(
                               aws_access_key_id: AWS_ACCESS_KEY_ID,
                               aws_secret_access_key: AWS_SECRET_ACCESS_KEY,
                               associate_tag: ASSOCIATE_TAG
                               )
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
                # follows RFC2616
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

            begin
              if response2["ItemLookupResponse"]["Items"]["Item"]
                product.url_jp = response2["ItemLookupResponse"]["Items"]["Item"]["DetailPageURL"]
                product.cost = response2["ItemLookupResponse"]["Items"]["Item"]["OfferSummary"]["LowestNewPrice"]["Amount"]
                product.shipping_cost = @shipping_cost
                product.profit = product.price*@exchange_rate - @shipping_cost - product.cost

                puts "COST:#{product.cost}"
              end
            rescue => ex
              warn ex.message
            end

            if saved_product = Product.where(["asin = ?", product.asin]).first
              saved_product.update_attributes(:sales_rank => product.sales_rank,
                                              :price => product.price,
                                              :cost => product.cost)
            else
              product.save
            end
            sleep 1
          end
        end
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def product_params
      params.require(:product).permit(:asin, :group, :manufacturer, :model, :title, :color, :size, :features, :sales_rank, :url, :url_jp, :image_url1, :image_url2, :image_url3, :image_url4, :image_url5, :currency, :price, :cost, :shipping_cost, :profit, :deleted_at)
    end
end
