class RadarImagesController < ApplicationController
  def image
    @radar_site = RadarSite.find_by_call_sign(radar_params[:site])
    @radar_product = RadarProduct.find_by_awips_header(radar_params[:product])

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
    expires_in time_remaining, must_revalidate: true, public: true

    if time_remaining <= 0 || stale?(@radar_image)
      if data = @radar_image.cached_data
        render json: data
      else
        head 503
      end
    end
  end

  def range
    raise "stub"
  end

  private

    def radar_params
      params.permit(
        :format,
        :site,
        :product
      )
    end
end
