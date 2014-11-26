class ProductToSellsController < ApplicationController
  before_action :set_product_to_sell, only: [:show, :edit, :update, :destroy]
  before_action :read_exchange_rate
  after_action :list_to_ebay, only: :create

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
    @@shipping_cost = 1080
    @exchange_rate = @@exchange_rate

    list_to_ebay
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
      params.require(:product_to_sell).permit(:product_id)
    end

  def read_exchange_rate
    @@exchange_rate = open("public/exchange_rate.txt", "r").read.to_i
    puts "@@EXCHANGE RATE:#{@@exchange_rate}"
  end

  def list_to_ebay
    # sandbox
    devid = "c193d86d-bd4f-4670-bd4a-303ced8aee4e"
    appid = "Chishaku-8e8f-48de-a23a-e1304518388d"
    certid = "920aabb1-6a0a-42c7-9cae-f0c96ea51bdc"
    token = "AgAAAA**AQAAAA**aAAAAA**V050VA**nY+sHZ2PrBmdj6wVnY+sEZ2PrA2dj6wFk4GhDZCDpQudj6x9nY+seQ**aB4DAA**AAMAAA**nKG1aXn3b+ebkdeQGHr8iyCXByqN2/CAMFZWsH+1qmVV8owROn5grbgei2yuDUPA3sIbfVHL9Svt1qJ1N8X5TpV0K0LDBkLtInXRzZE/iq9w+omCM0+mqxkW7qZzpc4Db5aU7n+5OS6GeK52JHcURTF9isfA+sGUSwkyBquI1MZ9nXq9OczubElwMrUJxQRrJBfeoj+Gy0FyCbJq1Venar3SNmxckjSiA8JiESZMdiEC/p7z4yTU+MUDALKncELBd8h1i4eFmW9RZ5XUs8ZMxxqGATZgYzfgw1NK+m7+4xpmh5FEN0kNpgarOBp0gzkDPYHmqLL035pdSBxxmzjWOP7JKqrdHlvmx9PzsIMUnjsMR8Bfb17TongERHucuUL8TwQ0GROzPIr6BnEY2ZX88GSrOcyzGq4yueMG1fg6lf3QoYMlzZKOlBaUeL/rdztQRaJ31fJf67EcOHMcvciyJ7wcPfIExkEOYPmOKCH07Nl7bzkbl8Yfn6SBBC+qhSg/ccluJoLhNHniMwl+0iEOySeBR894oPh8Kpa64yudAPkwMXn4VwZs70O2klivlN7lGIXkPqsAfaUaTC3qStFUbadPc7zA8hfV6Qp9eVQw4ztx9kmuN4mXF9HAzPf/1Iv38MHVENGS1Lb7VMx2gWy6VvENoeRDTQLgvQ57OAo+8x/wLjJQPOrOyd6zQSXX1zKfd3rSAPgIZgSW/kA8IVf90I7H8DEiLwniY44JS7BDxEF6HmVNLkGQlFdmLWiAezcF"

    # production
    # devid = "c193d86d-bd4f-4670-bd4a-303ced8aee4e"
    # appid = "Chishaku-0efe-4739-a2ff-dba4724f0514"
    # certid = "84ee65c2-56f3-4c73-82f3-12ef0c330250"
    # token = "AgAAAA**AQAAAA**aAAAAA**rk50VA**nY+sHZ2PrBmdj6wVnY+sEZ2PrA2dj6wMlIOjC5GFoQydj6x9nY+seQ**EpICAA**AAMAAA**WeFqWR8Xcwe61xgJGPIqEqeOhmqlTro1JSFa7Khy/064GcQ1kR122TvjmH0IlHAJdkHtoPMjIEjPTVut5WGmgHTT+csZtPPVjeeOTUg/wyvCrVTjYMwmCikpD4snm8i5mefRz5dOj1izdj20aopGTGDJMLYGCC7QAMeI7MxybwpIrN+eUjHyEduayth2VcgJOtY2fxlIHd9kKsgiV5eZm3oojH/fKYHME3RYwpELsdKBEbIWLsJ8pQOlIXkfwUd3d29sbkwp7m7Fc1nFB81Cki4WOstMe3W1q37virBkZHCk3CZDE4vvXs6LoBvf5qpHFE47gBrn5469dOgyBOH8hvNgb7/pgLDehqIPjQI1mDdBop4rd7sKzyFFvenKm/gQTrSEvvlTMz/CNrqsDQKSkb0SuhpavNLnmJDoxvjhEbKD9ptDO+6VSjO3auGyOuHoRpneJRXM+CiqE6RiGR+T0fd2Y2UPielC5wT/82Y+KOE+bhhte5efDhAr+ddSxG8ihk7cusPtf1ykq78pHURkPTSELtIiiteNHhkloBpNiTPvoc5MQUH6B/+qZmebkBCEs5bk698HJhbABGjNLYs31pCuXlIJZ0KOhuJEKVyEgFONrogSIhCdWzc5xozh3Q/EmwHV5/hchrAIzo8TZ5zBWWYVhXbPjaV6yS5hqQRE1bZNUWG11kcxhXNBh/Lg7YwLMBYo72pnrovf8lm6ZOgjJUcFWx7+8Xr/RJFESyh0YxPppruPTkEOhskfb79H9Xao"
    
  end
end
