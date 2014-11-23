class EbayItemsController < ApplicationController
  before_action :set_ebay_item, only: [:show, :edit, :update, :destroy]

  # GET /ebay_items
  # GET /ebay_items.json
  def index
    @ebay_items = EbayItem.all
  end

  # GET /ebay_items/1
  # GET /ebay_items/1.json
  def show
  end

  # GET /ebay_items/new
  def new
    @ebay_item = EbayItem.new
  end

  # GET /ebay_items/1/edit
  def edit
  end

  # POST /ebay_items
  # POST /ebay_items.json
  def create
    @ebay_item = EbayItem.new(ebay_item_params)

    respond_to do |format|
      if @ebay_item.save
        format.html { redirect_to @ebay_item, notice: 'Ebay item was successfully created.' }
        format.json { render :show, status: :created, location: @ebay_item }
      else
        format.html { render :new }
        format.json { render json: @ebay_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ebay_items/1
  # PATCH/PUT /ebay_items/1.json
  def update
    respond_to do |format|
      if @ebay_item.update(ebay_item_params)
        format.html { redirect_to @ebay_item, notice: 'Ebay item was successfully updated.' }
        format.json { render :show, status: :ok, location: @ebay_item }
      else
        format.html { render :edit }
        format.json { render json: @ebay_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ebay_items/1
  # DELETE /ebay_items/1.json
  def destroy
    @ebay_item.destroy
    respond_to do |format|
      format.html { redirect_to ebay_items_url, notice: 'Ebay item was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ebay_item
      @ebay_item = EbayItem.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def ebay_item_params
      params.require(:ebay_item).permit(:product_id, :item_id, :title, :global_id, :category_name, :gallery_url, :view_item_url, :shipping_service_cost_currency_id, :shipping_service_cost_value, :shipping_type, :handling_time, :current_price_currency_id, :current_price_value, :bid_count, :selling_state, :best_offer_enabled, :buy_it_now_available, :start_time, :end_time, :listing_type, :returns_accepted, :condition_display_name)
    end
end
