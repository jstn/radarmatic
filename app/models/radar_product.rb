class RadarProduct < ApplicationRecord
  has_many :radar_images, inverse_of: :radar_product

  scope :nexrad, -> {
    where(tdwr: false)
  }

  scope :tdwr, -> {
    where(tdwr: true)
  }

  def to_param
    awips_header
  end
end
