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

    if weight <= 0.05*0.8
      self.shipping_cost = 150
    elsif weight <= 0.1*0.8
      self.shipping_cost = 240
    elsif weight <= 0.15*0.8
      self.shipping_cost = 330
    elsif weight <= 0.2*0.8
      self.shipping_cost = 420
    elsif weight <= 0.25*0.8
      self.shipping_cost = 510
    elsif weight <= 0.3*0.8
      self.shipping_cost = 600
    elsif weight <= 0.35*0.8
      self.shipping_cost = 690
    elsif weight <= 0.4*0.8
      self.shipping_cost = 780
    elsif weight <= 0.45*0.8
      self.shipping_cost = 870
    elsif weight <= 0.5*0.8
      self.shipping_cost = 960
    elsif weight <= 0.55*0.8
      self.shipping_cost = 1050
    elsif weight <= 0.6*0.8
      self.shipping_cost = 1140
    elsif weight <= 0.65*0.8
      self.shipping_cost = 1230
    elsif weight <= 0.7*0.8
      self.shipping_cost = 1320
    elsif weight <= 0.75*0.8
      self.shipping_cost = 1410
    elsif weight <= 0.8*0.8
      self.shipping_cost = 1500
    elsif weight <= 0.85*0.8
      self.shipping_cost = 1590
    elsif weight <= 0.9*0.8
      self.shipping_cost = 1680
    elsif weight <= 0.95*0.8
      self.shipping_cost = 1770
    elsif weight <= 1*0.8
      self.shipping_cost = 1860
    elsif weight <= 1.25*0.8
      self.shipping_cost = 2085
    elsif weight <= 1.5*0.8
      self.shipping_cost = 2310
    elsif weight <= 1.75*0.8
      self.shipping_cost = 2535
    elsif weight <= 2*0.8
      self.shipping_cost = 2760

    # if weight <= 0.1*0.8
    #   self.shipping_cost = 180
    # elsif weight <= 0.2*0.8
    #   self.shipping_cost = 280
    # elsif weight <= 0.3*0.8
    #   self.shipping_cost = 380
    # elsif weight <= 0.4*0.8
    #   self.shipping_cost = 480
    # elsif weight <= 0.5*0.8
    #   self.shipping_cost = 580
    # elsif weight <= 0.6*0.8
    #   self.shipping_cost = 680
    # elsif weight <= 0.7*0.8
    #   self.shipping_cost = 780
    # elsif weight <= 0.8*0.8
    #   self.shipping_cost = 880
    # elsif weight <= 0.9*0.8
    #   self.shipping_cost = 980
    # elsif weight <= 1*0.8
    #   self.shipping_cost = 1080
    # elsif weight <= 1.1*0.8
    #   self.shipping_cost = 1180
    # elsif weight <= 1.2*0.8
    #   self.shipping_cost = 1280
    # elsif weight <= 1.3*0.8
    #   self.shipping_cost = 1380
    # elsif weight <= 1.4*0.8
    #   self.shipping_cost = 1480
    # elsif weight <= 1.5*0.8
    #   self.shipping_cost = 1580
    # elsif weight <= 1.6*0.8
    #   self.shipping_cost = 1680
    # elsif weight <= 1.7*0.8
    #   self.shipping_cost = 1780
    # elsif weight <= 1.8*0.8
    #   self.shipping_cost = 1880
    # elsif weight <= 1.9*0.8
    #   self.shipping_cost = 1980
    # elsif weight <= 2*0.8
    #   self.shipping_cost = 2080

    # elsif weight <= 1*0.8
    #   self.shipping_cost = 2700
    # elsif weight <= 2*0.8
    #   self.shipping_cost = 3850

    elsif weight <= 3*0.8
      self.shipping_cost = 5000
    elsif weight <= 4*0.8
      self.shipping_cost = 6150
    elsif weight <= 5*0.8
      self.shipping_cost = 7300
    elsif weight <= 6*0.8
      self.shipping_cost = 8350
    elsif weight <= 7*0.8
      self.shipping_cost = 9400
    elsif weight <= 8*0.8
      self.shipping_cost = 10450
    elsif weight <= 9*0.8
      self.shipping_cost = 11500
    elsif weight <= 10*0.8
      self.shipping_cost = 12550
    elsif weight <= 11*0.8
      self.shipping_cost = 13250
    elsif weight <= 12*0.8
      self.shipping_cost = 13950
    elsif weight <= 13*0.8
      self.shipping_cost = 14650
    elsif weight <= 14*0.8
      self.shipping_cost = 15350
    elsif weight <= 15*0.8
      self.shipping_cost = 16050
    elsif weight <= 16*0.8
      self.shipping_cost = 16750
    elsif weight <= 17*0.8
      self.shipping_cost = 17450
    elsif weight <= 18*0.8
      self.shipping_cost = 18150
    elsif weight <= 19*0.8
      self.shipping_cost = 18850
    elsif weight <= 20*0.8
      self.shipping_cost = 19550
    elsif weight <= 21*0.8
      self.shipping_cost = 20250
    elsif weight <= 22*0.8
      self.shipping_cost = 20950
    elsif weight <= 23*0.8
      self.shipping_cost = 21650
    elsif weight <= 24*0.8
      self.shipping_cost = 22350
    elsif weight <= 25*0.8
      self.shipping_cost = 23050
    elsif weight <= 26*0.8
      self.shipping_cost = 23750
    elsif weight <= 27*0.8
      self.shipping_cost = 24450
    elsif weight <= 28*0.8
      self.shipping_cost = 25150
    elsif weight <= 29*0.8
      self.shipping_cost = 25850
    elsif weight <= 30*0.8
      self.shipping_cost = 26550
    else
      self.shipping_cost = 0
    end

    if self.price && self.cost
      self.profit = self.price * @@exchange_rate - self.shipping_cost - self.cost
    end
  end
end
