class MapsController < ApplicationController
  def map
    @radar_sites_json = Rails.cache.fetch("radar_sites_json") do
      sites = Hash.new
      RadarSite.order(call_sign: :asc).each do |site|
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

    expires_in 1.day, must_revalidate: true, public: true

    render layout: "map"
  end
end
