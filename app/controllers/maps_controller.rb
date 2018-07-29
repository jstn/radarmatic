class MapsController < ApplicationController
  def map
    @radar_sites = RadarSite.order(call_sign: :asc)
    json_cache_key = "#{@radar_sites.cache_key}/json"

    @radar_sites_json = Rails.cache.fetch(json_cache_key) do
      sites = Hash.new
      @radar_sites.each do |site|
        sites[site["call_sign"].to_sym] = {
          name: site.name,
          tdwr: site.tdwr,
          ele: site.elevation,
          lat: site.latitude,
          lng: site.longitude
        }
      end
      JSON.generate(sites)
    end

    expires_in(1.hour, must_revalidate: true, public: true)
  end
end
