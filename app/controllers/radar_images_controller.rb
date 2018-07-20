class RadarImagesController < ApplicationController
  def product
    @radar_site = RadarSite.find_by_call_sign(params[:site])
    @radar_product = RadarProduct.find_by_awips_header(params[:product])

    unless @radar_site.present? && @radar_product.present?
      head 404
      return
    end

    begin
      @radar_image = RadarImage.find_or_create_by!(
        radar_site: @radar_site,
        radar_product: @radar_product
      )
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    unless @radar_image.present?
      head 500
      return
    end

    time_remaining = @radar_image.time_remaining

    if time_remaining > 0
      expires_in time_remaining, must_revalidate: true
    else
      expires_now
    end

    if time_remaining <= 0 || stale?(@radar_image)
      if data = @radar_image.cached_data
        render json: data
      else
        head 503
      end
    end
  end
end
