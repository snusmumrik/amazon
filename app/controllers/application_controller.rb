class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def read_exchange_rate
    @exchange_rate = open("public/exchange_rate.txt", "r").read.to_f.round(2)
    # puts "EXCHANGE RATE FROM FILE:#{@exchange_rate}"
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
    if session[:categories]
      @categories = session[:categories]
    else
      @categories = Product.group(:category).order(:category).inject(Array.new) {|a, p| a << [p.category, p.category]; a}
      session[:categories] = @categories
    end
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
    @ebay_item_hash = ebay_items.inject(Hash.new {|hash, key| hash[key] = Array.new}) {|h, ei|
      h[ei.product_id] << ei.try(:current_price_value) if ei.current_price_currency_id == @locale; h
    }

    @sold_item_hash = ebay_items.inject(Hash.new {|hash, key| hash[key] = Array.new}) {|h, ei|
      h[ei.product_id] << ei.try(:current_price_value) if ei.current_price_currency_id == @locale && ei.selling_state == "EndedWithSales"; h
    }

    @average_hash = @sold_item_hash.inject(Hash.new {|hash, key| hash[key] = 0}) {|h, (key, value)| h[key] = (value.sum/value.size).round(2); h}
  end
end
