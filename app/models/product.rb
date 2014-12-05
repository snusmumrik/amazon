# -*- coding: utf-8 -*-
class Product < ActiveRecord::Base
  has_many :ebay_items
  validates :asin, presence: true
  validates :asin, uniqueness: true
  acts_as_paranoid

  before_save :calculate_cost
  before_update :calculate_cost

  def calculate_cost
    @@exchange_rate = open("public/exchange_rate.txt", "r").read.to_i
    weight = self.weight.to_f / 100 * 0.454
    # 小形包装物
    #   長さ＋幅＋厚さ＝90cm
    #   ただし、長さの最大は60cm
    #   (許容差 2mm)
    #   巻物については
    #   長さ＋直径の2倍＝104cm
    #   ただし、長さの最大は90cm
    #   (許容差 2mm)
    if weight <= 0.1
      self.shipping_cost = 180
    elsif weight <= 0.2
      self.shipping_cost = 280
    elsif weight <= 0.3
      self.shipping_cost = 380
    elsif weight <= 0.4
      self.shipping_cost = 480
    elsif weight <= 0.5
      self.shipping_cost = 580
    elsif weight <= 0.6
      self.shipping_cost = 680
    elsif weight <= 0.7
      self.shipping_cost = 780
    elsif weight <= 0.8
      self.shipping_cost = 880
    elsif weight <= 0.9
      self.shipping_cost = 980
    elsif weight <= 1
      self.shipping_cost = 1080
    elsif weight <= 1.1
      self.shipping_cost = 1180
    elsif weight <= 1.2
      self.shipping_cost = 1280
    elsif weight <= 1.3
      self.shipping_cost = 1380
    elsif weight <= 1.4
      self.shipping_cost = 1480
    elsif weight <= 1.5
      self.shipping_cost = 1580
    elsif weight <= 1.6
      self.shipping_cost = 1680
    elsif weight <= 1.7
      self.shipping_cost = 1780
    elsif weight <= 1.8
      self.shipping_cost = 1880
    elsif weight <= 1.9
      self.shipping_cost = 1980
    elsif weight <= 2
      self.shipping_cost = 2080
    # elsif weight <= 1
    #   self.shipping_cost = 2700
    # elsif weight <= 2
    #   self.shipping_cost = 3850
    elsif weight <= 3
      self.shipping_cost = 5000
    elsif weight <= 4
      self.shipping_cost = 6150
    elsif weight <= 5
      self.shipping_cost = 7300
    elsif weight <= 6
      self.shipping_cost = 8350
    elsif weight <= 7
      self.shipping_cost = 9400
    elsif weight <= 8
      self.shipping_cost = 10450
    elsif weight <= 9
      self.shipping_cost = 11500
    elsif weight <= 10
      self.shipping_cost = 12550
    elsif weight <= 11
      self.shipping_cost = 13250
    elsif weight <= 12
      self.shipping_cost = 13950
    elsif weight <= 13
      self.shipping_cost = 14650
    elsif weight <= 14
      self.shipping_cost = 15350
    elsif weight <= 15
      self.shipping_cost = 16050
    elsif weight <= 16
      self.shipping_cost = 16750
    elsif weight <= 17
      self.shipping_cost = 17450
    elsif weight <= 18
      self.shipping_cost = 18150
    elsif weight <= 19
      self.shipping_cost = 18850
    elsif weight <= 20
      self.shipping_cost = 19550
    elsif weight <= 21
      self.shipping_cost = 20250
    elsif weight <= 22
      self.shipping_cost = 20950
    elsif weight <= 23
      self.shipping_cost = 21650
    elsif weight <= 24
      self.shipping_cost = 22350
    elsif weight <= 25
      self.shipping_cost = 23050
    elsif weight <= 26
      self.shipping_cost = 23750
    elsif weight <= 27
      self.shipping_cost = 24450
    elsif weight <= 28
      self.shipping_cost = 25150
    elsif weight <= 29
      self.shipping_cost = 25850
    elsif weight <= 30
      self.shipping_cost = 26550
    else
      self.shipping_cost = 0
    end

    if self.price && self.cost
      self.profit = self.price * @@exchange_rate - self.shipping_cost - self.cost
    end
  end
end
