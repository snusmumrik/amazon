class CreateSearchIndices < ActiveRecord::Migration
  def change
    create_table :search_indices do |t|
      t.string :name
      t.datetime :deleted_at
    end

    search_indeces = ["Apparel",
                      "Appliances",
                      "ArtsAndCrafts",
                      "Automotive",
                      "Baby",
                      "Beauty",
                      "Blended",
                      "Books",
                      "Classical",
                      "Collectibles",
                      "DigitalMusic",
                      "Grocery",
                      "DVD",
                      "Electronics",
                      "HealthPersonalCare",
                      "HomeGarden",
                      "Industrial",
                      "Jewelry",
                      "KindleStore",
                      "Kitchen",
                      "LawnGarden",
                      "Magazines",
                      "Marketplace",
                      "Merchants",
                      "Miscellaneous",
                      "MobileApps",
                      "MP3Downloads",
                      "Music",
                      "MusicalInstruments",
                      "MusicTracks",
                      "OfficeProducts",
                      "OutdoorLiving",
                      "PCHardware",
                      "PetSupplies",
                      "Photo",
                      "Shoes",
                      "Software",
                      "SportingGoods",
                      "Tools",
                      "Toys",
                      "UnboxVideo",
                      "VHS",
                      "Video",
                      "VideoGames",
                      "Watches",
                      "Wireless",
                      "WirelessAccessories"]
    search_indeces.each do |index|
      SearchIndex.create(:name => index)
    end
  end
end
