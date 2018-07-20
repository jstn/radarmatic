class RadarSite < ApplicationRecord
  has_many :radar_images, inverse_of: :radar_site

  scope :nexrad, -> {
    where(tdwr: false)
  }

  scope :tdwr, -> {
    where(tdwr: true)
  }

  def to_param
    call_sign
  end

  def products
    if tdwr
      RadarProduct.tdwr
    else
      RadarProduct.nexrad
    end
  end
end
