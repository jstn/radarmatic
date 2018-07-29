require "net/http"

class RadarImage < ApplicationRecord
  belongs_to :radar_site, inverse_of: :radar_images
  belongs_to :radar_product, inverse_of: :radar_images

  MAX_AGE = 5.minutes

  def age
    (Time.current - updated_at).seconds
  end

  def time_remaining
    tr = MAX_AGE - age
    (tr <= 0 ? 0 : tr).seconds
  end

  def fresh?
    data.present? && age <= MAX_AGE
  end

  def cached_data
    data_cache_key = "#{cache_key}/data"

    unless fresh?
      download_data
      if data.present?
        Rails.cache.write(data_cache_key, data)
      end
    end

    Rails.cache.fetch(data_cache_key) do
      data
    end
  end

  private

    def download_data
      dir = radar_product.directory
      sid = radar_site.call_sign.downcase
      last_url = "#{Rails.configuration.base_radar_url}/DS.#{dir}/SI.#{sid}/sn.last"
      response = Net::HTTP.get_response(URI(last_url))
      return nil unless (response.code.to_i == 200 && response.body.length > 0)

      parser = RadarImageParser.new(response.body, radar_site.call_sign)
      if json = parser.data.to_json
        self.data = json
        save
      end
    end
end
