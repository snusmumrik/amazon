class EbayCategoriesController < ApplicationController
  # GET /ebay_categories/
  # GET /ebay_categories.json
  def index
    get_category

    limit = EbayCategory.select(:category_level).group(:category_level).order("category_level").last.category_level
    for i in 1..limit
      EbayCategory.where(["category_level = ?", i]).all.each do |p|
        puts "PARENT ID:#{p.id} CATEGORY_LEVEL:#{p.category_level} CATEGORY_NAME:#{p.category_name}"
        get_category(p)
      end
    end
  end

  private
  def get_category(parent_category = nil)
    api_call_name = "getCategories"

    @header = {
      "X-EBAY-API-DEV-NAME" => DEVID,
      "X-EBAY-API-APP-NAME" => APPID,
      "X-EBAY-API-CERT-NAME" => CERTID,
      "X-EBAY-API-CALL-NAME" => api_call_name,
      "X-EBAY-API-COMPATIBILITY-LEVEL" => API_COMPATIBILITY_LEVEL,
      "X-EBAY-API-SITEID" => EBAY_API_SITEID,
      "Content-Type" => "text/xml",
    }

    if parent_category
      xml ="
<?xml version='1.0' encoding='utf-8'?>
<GetCategoriesRequest xmlns='urn:ebay:apis:eBLBaseComponents'>
  <RequesterCredentials>
    <eBayAuthToken>#{TOKEN}</eBayAuthToken>
  </RequesterCredentials>
  <CategoryParent>#{parent_category.category_id}</CategoryParent>
  <DetailLevel>ReturnAll</DetailLevel>
  <LevelLimit>#{parent_category.category_level.to_i + 1}</LevelLimit>
</GetCategoriesRequest>
"
    else
      xml = "
<?xml version='1.0' encoding='utf-8'?>
<GetCategoriesRequest xmlns='urn:ebay:apis:eBLBaseComponents'>
  <RequesterCredentials>
    <eBayAuthToken>#{TOKEN}</eBayAuthToken>
  </RequesterCredentials>
  <DetailLevel>ReturnAll</DetailLevel>
  <LevelLimit>1</LevelLimit>
</GetCategoriesRequest>
"
    end

    response = Typhoeus::Request.post(URL, :body => xml, :headers => @header )
    # raise response.response_body.inspect

    begin
      Hash.from_xml(response.response_body)["GetCategoriesResponse"]["CategoryArray"]["Category"].each do |c|
        EbayCategory.create(
                            "category_id" => c["CategoryID"],
                            "category_level" => c["CategoryLevel"],
                            "category_name" => c["CategoryName"],
                            "category_parent_id" => c["CategoryParentID"],
                            "leaf_category" => c["LeafCategory"]
                            )
        puts "CHILD CATEGOR_ID:#{c['CategoryID']} CATEGORY_NAME:#{c['CategoryName']}"
      end
    rescue => ex
      warn ex.message
    end
  end
end
