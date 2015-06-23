# -*- coding: utf-8 -*-
class Product < ActiveRecord::Base
  has_many :ebay_items
  validates :asin, presence: true
  validates :asin, uniqueness: true
  acts_as_paranoid

  before_save :calculate_cost

  def calculate_cost
    exchange_rate = open("public/exchange_rate.txt", "r").read.to_i
    weight = self.weight.to_f / 100 * 0.454
    # 小形包装物
    #   長さ＋幅＋厚さ＝90cm ただし、長さの最大は60cm (許容差 2mm)
    # 巻物については
    #   長さ＋直径の2倍＝104cm ただし、長さの最大は90cm (許容差 2mm)

    # # 小形包装物 航空便
    # if weight * 1.1 <= 0.05
    #   self.shipping_cost = 150 + 410
    # elsif weight * 1.1 <= 0.1
    #   self.shipping_cost = 240 + 410
    # elsif weight * 1.1 <= 0.15
    #   self.shipping_cost = 330 + 410
    # elsif weight * 1.1 <= 0.2
    #   self.shipping_cost = 420 + 410
    # elsif weight * 1.1 <= 0.25
    #   self.shipping_cost = 510 + 410
    # elsif weight * 1.1 <= 0.3
    #   self.shipping_cost = 600 + 410
    # elsif weight * 1.1 <= 0.35
    #   self.shipping_cost = 690 + 410
    # elsif weight * 1.1 <= 0.4
    #   self.shipping_cost = 780 + 410
    # elsif weight * 1.1 <= 0.45
    #   self.shipping_cost = 870 + 410
    # elsif weight * 1.1 <= 0.5
    #   self.shipping_cost = 960 + 410
    # elsif weight * 1.1 <= 0.55
    #   self.shipping_cost = 1050 + 410
    # elsif weight * 1.1 <= 0.6
    #   self.shipping_cost = 1140 + 410
    # elsif weight * 1.1 <= 0.65
    #   self.shipping_cost = 1230 + 410
    # elsif weight * 1.1 <= 0.7
    #   self.shipping_cost = 1320 + 410
    # elsif weight * 1.1 <= 0.75
    #   self.shipping_cost = 1410 + 410
    # elsif weight * 1.1 <= 0.8
    #   self.shipping_cost = 1500 + 410
    # elsif weight * 1.1 <= 0.85
    #   self.shipping_cost = 1590 + 410
    # elsif weight * 1.1 <= 0.9
    #   self.shipping_cost = 1680 + 410
    # elsif weight * 1.1 <= 0.95
    #   self.shipping_cost = 1770 + 410
    # elsif weight * 1.1 <= 1
    #   self.shipping_cost = 1860 + 410
    # elsif weight * 1.1 <= 1.25
    #   self.shipping_cost = 2085 + 410
    # elsif weight * 1.1 <= 1.5
    #   self.shipping_cost = 2310 + 410
    # elsif weight * 1.1 <= 1.75
    #   self.shipping_cost = 2535 + 410
    # elsif weight * 1.1 <= 2
    #   self.shipping_cost = 2760 + 410

    # 小形包装物 SAL
    if weight * 1.1 <= 0.1
      self.shipping_cost = 180 + 410
    elsif weight * 1.1 <= 0.2
      self.shipping_cost = 280 + 410
    elsif weight * 1.1 <= 0.3
      self.shipping_cost = 380 + 410
    elsif weight * 1.1 <= 0.4
      self.shipping_cost = 480 + 410
    elsif weight * 1.1 <= 0.5
      self.shipping_cost = 580 + 410
    elsif weight * 1.1 <= 0.6
      self.shipping_cost = 680 + 410
    elsif weight * 1.1 <= 0.7
      self.shipping_cost = 780 + 410
    elsif weight * 1.1 <= 0.8
      self.shipping_cost = 880 + 410
    elsif weight * 1.1 <= 0.9
      self.shipping_cost = 980 + 410
    elsif weight * 1.1 <= 1
      self.shipping_cost = 1080 + 410
    elsif weight * 1.1 <= 1.1
      self.shipping_cost = 1180 + 410
    elsif weight * 1.1 <= 1.2
      self.shipping_cost = 1280 + 410
    elsif weight * 1.1 <= 1.3
      self.shipping_cost = 1380 + 410
    elsif weight * 1.1 <= 1.4
      self.shipping_cost = 1480 + 410
    elsif weight * 1.1 <= 1.5
      self.shipping_cost = 1580 + 410
    elsif weight * 1.1 <= 1.6
      self.shipping_cost = 1680 + 410
    elsif weight * 1.1 <= 1.7
      self.shipping_cost = 1780 + 410
    elsif weight * 1.1 <= 1.8
      self.shipping_cost = 1880 + 410
    elsif weight * 1.1 <= 1.9
      self.shipping_cost = 1980 + 410
    elsif weight * 1.1 <= 2
      self.shipping_cost = 2080 + 410

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
    else
      self.shipping_cost = 0
    end

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

    if self.price && self.cost
      self.profit = (self.price * (1 - 0.1 - 0.039) - 0.3) * exchange_rate - self.shipping_cost - self.cost
    else
      self.profit = nil
    end
  end
end
