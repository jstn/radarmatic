require "rbzip2"

class RadarImageParser
  SUPPORTED_CODES = [ 19, 20, 94, 181, 186 ]
  SYMBOLOGY_BLOCK_ID = 1
  BLOCK_DIVIDER = -1
  LAYER_DIVIDER = -1
  NO_VALUE = -33

  attr_reader :data

  def initialize(io_or_string, call_sign)
    @io = io_or_string.is_a?(String) ? StringIO.new(io_or_string, "rb") : io_or_string
    parse(call_sign)
    @io = nil
  end

  private

    def parse(call_sign)
      @data = Hash.new

      @data[:message_header] = {
        call_sign:          call_sign,
        wmo_header:         string,
        awips_header:       string,
        message_code:       halfword,                      # HW 1
        message_time:       unixtime,                      # HW 2-4
        length_of_message:  fullword,                      # HW 5-6
        source_id:          halfword,                      # HW 7
        destination_id:     halfword,                      # HW 8
        number_of_blocks:   halfword                       # HW 9
      }

      unless halfword == BLOCK_DIVIDER
        raise "expected product description block"         # HW 10
      end

      @data[:product_description] = {
        radar_latitude:           fullword.to_f / 1000,    # HW 11-12
        radar_longitude:          fullword.to_f / 1000,    # HW 12-13
        radar_height:             halfword,                # HW 15
        product_code:             halfword,                # HW 16
        operational_mode:         halfword,                # HW 17
        volume_coverage_pattern:  halfword,                # HW 18
        sequence_number:          halfword,                # HW 19
        volume_scan_number:       halfword,                # HW 20
        volume_scan_time:         unixtime,                # HW 21-23
        generation_time:          unixtime,                # HW 24-26
        product_halfword_27:      halfword,                # HW 27
        product_halfword_28:      halfword,                # HW 28
        elevation_number:         halfword,                # HW 29
        elevation_angle:          halfword.to_f / 10       # HW 30
      }

      @product_code = @data[:product_description][:product_code]

      unless SUPPORTED_CODES.include? @product_code
        raise "product #{@product_code} not supported"
      end

      if @product_code == 94 || @product_code == 186
        @data[:product_description].merge!(
          threshold_dbz_min_value:    halfword.to_f / 10,  # HW 31
          threshold_dbz_increment:    halfword.to_f / 10,  # HW 32
          threshold_number_of_levels: halfword             # HW 33
        )
        @io.read(26)                                       # HW 34-46
      else
        16.times do |i|                                    # HW 31-46
          msb = byte
          lsb = byte
          threshold = ""

          if msb & 0b10000000 > 0
            threshold += case lsb
              when  1 then "TH"
              when  2 then "ND" # Below Threshold
              when  3 then "RF" # Range Folded
              when  4 then "BI" # Biological
              when  5 then "GC" # AP/Ground Clutter
              when  6 then "IC" # Ice Crystals
              when  7 then "GR" # Graupel
              when  8 then "WS" # Wet Snow
              when  9 then "DS" # Dry Snow
              when 10 then "RA" # Light and Moderate Rain
              when 11 then "HR" # Heavy Rain
              when 12 then "BD" # Big Drops
              when 13 then "HA" # Hail and Rain Mixed
              when 14 then "UK" # Unknown
              when 15 then "LH" # Large Hail
              when 16 then "GH" # Giant Hail
              else ""
            end
          else
            if    msb & 0b00001000 > 0
              threshold += ">"
            elsif msb & 0b00000100 > 0
              threshold += "<"
            elsif msb & 0b00000010 > 0
              threshold += "+"
            elsif msb & 0b00000001 > 0
              threshold += "-"
            end

            if    msb & 0b01000000 > 0
              threshold += lsb.to_f / 100
            elsif msb & 0b00100000 > 0
              threshold += lsb.to_f / 20
            elsif msb & 0b00010000 > 0
              threshold += lsb.to_f / 10
            else
              threshold += lsb.to_s
            end
          end

          @data[:product_description]["threshold_#{i + 1}".to_sym] = threshold
        end
      end

      if @product_code == 19 || @product_code == 20 || @product_code == 181
        @data[:product_description].merge!(
          max_reflectivity:         halfword, # HW 47
          product_halfword_48:      halfword, # HW 48
          product_halfword_49:      halfword, # HW 49
          product_halfword_50:      halfword, # HW 50
          calibration_constant:     float,    # HW 51-52
          product_halfword_53:      halfword  # HW 53
        )
      elsif @product_code == 94 || @product_code == 186
        @data[:product_description].merge!(
          max_reflectivity:         halfword, # HW 47
          product_halfword_48:      halfword, # HW 48
          product_halfword_49:      halfword, # HW 49
          product_halfword_50:      halfword, # HW 50
          compression_method:       halfword, # HW 51
          uncompressed_size:        fullword  # HW 52-53
        )
      else
        (47..53).each do |i| # HW 47-53
          @data[:product_description]["product_halfword_#{i}".to_sym] = halfword
        end
      end

      @data[:product_description].merge!(
        version:             byte,     # HW 54
        spot_blank:          byte,     # HW 54.5
        offset_to_symbology: fullword, # HW 55-56
        offset_to_graphic:   fullword, # HW 57-58
        offset_to_tabular:   fullword  # HW 59-60
      )

      if @data[:product_description][:max_reflectivity] == NO_VALUE
        @data[:product_description][:max_reflectivity] = nil
      end

      @data[:product_description].delete_if do |key|
        key.to_s.include?("halfword") || key.to_s.include?("offset")
      end

      if @data[:product_description][:compression_method] == 1
        @io = StringIO.new(RBzip2.default_adapter::Decompressor.new(@io).read)
      end

      unless halfword == BLOCK_DIVIDER && halfword == SYMBOLOGY_BLOCK_ID
        raise "expected product symbology block"
      end

      @data[:product_symbology] = {
        length_of_block:   fullword,
        number_of_layers:  halfword,
        layers:            Array.new
      }

      @data[:product_symbology][:number_of_layers].times do
        raise "expected data layer" unless halfword == LAYER_DIVIDER

        length_of_data_layer = fullword
        packet_code_msb = byte
        packet_code_lsb = byte

        run_length_encoded = if packet_code_msb == 0xAF && packet_code_lsb == 0x1F
          true
        elsif packet_code_msb == 0x0 && packet_code_lsb == 0x10
          false
        else
          raise "unknown packet code"
        end

        layer = {
          index_of_first_range_bin: halfword,
          number_of_range_bins:     halfword,
          i_center_of_sweep:        halfword,
          j_center_of_sweep:        halfword,
          range_scale_factor:       halfword.to_f / 1000,
          number_of_radials:        halfword,
          radials:                  Array.new
        }

        layer[:number_of_radials].times do
          number_of_bytes = halfword * (run_length_encoded ? 2 : 1)
          radial = {
            angle_start: halfword.to_f / 10,
            angle_delta: halfword.to_f / 10
          }

          bin_bytes = @io.read(number_of_bytes)

          if run_length_encoded
            range_bins = Array.new
            bin_bytes.each_byte do |byte|
              run_length = byte >> 4
              bin = byte & 0b00001111
              scaled = ((bin.to_f / 15) * 255).round
              range_bins.concat Array.new(run_length, scaled)
            end
            bin_bytes = range_bins.pack("C*")
          end

          radial[:range_bins] = bin_bytes

          layer[:radials] << radial
        end

        layer[:radials].sort! do |a, b|
          a[:angle_start] <=> b[:angle_start]
        end

        @data[:product_symbology][:layers] << layer
      end

      layer = @data[:product_symbology][:layers].first
      radial_count = layer[:number_of_radials]
      bins_per_radial = layer[:number_of_range_bins]
      texture_width = 2 ** Math.log(bins_per_radial, 2).ceil(0)
      texture_height = 2 ** Math.log(radial_count, 2).ceil(0)
      texture_bytes = Array.new(texture_width * texture_height, 0)

      for i in 0...radial_count
        radial = layer[:radials][i]

        x = 0
        y_offset = texture_width * i
        radial.delete(:range_bins).each_byte do |b|
          texture_bytes[x + y_offset] = b
          x += 1
        end

        x = i
        y_offset = texture_width * radial_count
        angle_start_enc = ((radial[:angle_start] * 10) - (x * 10)).to_i
        angle_delta_enc = (radial[:angle_delta] * 10).to_i
        texture_bytes[x + y_offset] = angle_start_enc # decode(x) { x + (enc / 10) }
        texture_bytes[x + y_offset + texture_width] = angle_delta_enc # decode(x) { enc / 10 }
      end

      layer.delete(:radials)

      @data[:texture] = {
        width: texture_width,
        height: texture_height,
        base64: Base64.strict_encode64(texture_bytes.pack("C*"))
      }
    end

    def byte
      @io.getbyte
    end

    def string
      @io.gets.strip
    end

    def halfword
      @io.read(2).unpack("s>").first
    end

    def fullword
      @io.read(4).unpack("l>").first
    end

    def float
      @io.read(4).unpack("g").first
    end

    def unixtime
      days = halfword.days - 1.day
      seconds = fullword.seconds
      Time.zone.at(days + seconds).iso8601
    end
end
