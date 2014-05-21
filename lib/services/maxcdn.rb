require "maxcdn"

class Service::MaxCDN < Service

  STATIC_EXTENSIONS = [
    :css, :js, :jpg, :jpeg, :gif, :ico, :png, :bmp,
    :pict, :csv, :doc, :pdf, :pls, :ppt, :tif, :tiff,
    :eps, :ejs, :swf, :midi, :mid, :txt, :ttf, :eot,
    :woff, :otf, :svg, :svgz, :webp, :docx, :xlsx,
    :xls, :pptx, :ps, :rss, :class, :jar
  ].freeze

  string        :alias,
                :key,
                :secret,
                :zone_id

  boolean       :static_only

  url           "http://docs.maxcdn.com/"
  logo_url      "http://www.maxcdn.com/wp-content/themes/maxcdnv4/img/png/maxcdn-colored-logo.png"

  maintained_by :github  => "jmervine",
                :email   => "joshua@mervine.net",
                :twitter => "@mervinej"

  supported_by  :web     => "http://support.maxcdn.com/",
                :email   => "support@maxcdn.com",
                :twitter => "@MaxCDN"

  def receive_push
    return unless payload["commits"]
    return if data["static_only"] and !has_static?

    begin
      maxcdn.purge data["zone_id"]
    rescue ::MaxCDN::APIException => e
      raise_config_error(e.message)
    end
  end

  def modified_files
    payload["commits"].map { |commit| commit["modified"] }.flatten!.uniq!
  end

  def extensions
    ::Service::MaxCDN::STATIC_EXTENSIONS
  end

  def has_static?
    files = modified_files.clone.select! do |file|
      matched = false
      extensions.each do |ext|
        matched = true if /#{ext}/.match(file)
      end
      matched
    end

    (files.size > 0)
  end

  def maxcdn
    @maxcdn ||= ::MaxCDN::Client.new(data["alias"], data["key"], data["secret"])
  end
end

