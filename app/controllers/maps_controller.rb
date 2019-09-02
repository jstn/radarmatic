class MapsController < ApplicationController
  def map
    @radar_sites = RadarSite.order(call_sign: :asc)
    unless @radar_sites.present?
      head 500
      return
    end

    @radar_sites_json = Rails.cache.fetch(@radar_sites.cache_key) do
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

    expires_in(1.year, public: true, must_revalidate:true)
  end
end
