require 'mime/types'
require 'net/http'
require 'cgi'

module Multipart #:nodoc:
  # From: http://deftcode.com/code/flickr_upload/multipartpost.rb
  ## Helper class to prepare an HTTP POST request with a file upload
  ## Mostly taken from
  #http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/113774
  ### WAS:
  ## Anything that's broken and wrong probably the fault of Bill Stilwell
  ##(bill@marginalia.org)
  ### NOW:
  ## Everything wrong is due to keith@oreilly.com

  class Param #:nodoc:
    attr_accessor :k, :v
    def initialize(k, v)
      @k = k
      @v = v
    end

    def to_multipart
      "Content-Disposition: form-data; name=\"#{k}\"\r\n\r\n#{v}\r\n"
    end
  end

  class FileParam #:nodoc:
    attr_accessor :k, :filename, :content
    def initialize(k, filename, content)
      @k = k
      @filename = filename
      @content = content
    end

    def to_multipart
      "Content-Disposition: form-data; name=\"#{k}\"; filename=\"#{filename}\"\r\n" +
        "Content-Transfer-Encoding: binary\r\n" +
        "Content-Type: #{MIME::Types.type_for(@filename)}\r\n\r\n" +
        @content + "\r\n"
    end
  end

  class MultipartPost #:nodoc:
    BOUNDARY = 'campfire-is-awesome'
    HEADER = {"Content-type" => "multipart/form-data, boundary=" + BOUNDARY + " "}
    TIMEOUT_SECONDS = 30

    attr_accessor :params, :query, :headers
    def initialize(params)
      @params = params
      @query = {}
      self.prepare_query
    end

    def prepare_query()
      @query = @params.map do |k,v|
        param = v.respond_to?(:read) ? FileParam.new(k, v.path, v.read) : Param.new(k, v)
        "--#{BOUNDARY}\r\n#{param.to_multipart}"
      end.join("") + "--#{BOUNDARY}--"
    end
  end
end
