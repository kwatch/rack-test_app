# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2015 kuwata-lab.com all rights reserved $
### $License: MIT License $
###


require 'uri'
require 'digest/sha1'
require 'rack'


module Rack


  module TestApp

    VERSION = '$Release: 0.0.0 $'.split()[1]


    module Util

      module_function

      def percent_encode(str)
        #; [!a96jo] encodes string into percent encoding format.
        return URI.encode_www_form_component(str)
      end

      def percent_decode(str)
        #; [!kl9sk] decodes percent encoded string.
        return URI.decode_www_form_component(str)
      end

      def build_query_string(query)  # :nodoc:
        #; [!098ac] returns nil when argument is nil.
        #; [!z9ds2] returns argument itself when it is a string.
        #; [!m5yyh] returns query string when Hash or Array passed.
        #; [!nksh3] raises ArgumentError when passed value except nil, string, hash or array.
        case query
        when nil    ; return nil
        when String ; return query
        when Hash, Array
          return query.collect {|k, v| "#{percent_encode(k.to_s)}=#{percent_encode(v.to_s)}" }.join('&')
        else
          raise ArgumentError.new("Hash or Array expected but got #{query.inspect}.")
        end
      end

      def randstr_b64()
        #; [!yq0gv] returns random string, encoded with urlsafe base64.
        ## Don't use SecureRandom; entropy of /dev/random or /dev/urandom
        ## should be left for more secure-sensitive purpose.
        s = "#{rand()}#{rand()}#{rand()}#{Time.now.to_f}"
        binary = ::Digest::SHA1.digest(s)
        return [binary].pack('m').chomp("=\n").tr('+/', '-_')
      end

      def guess_content_type(filename, default='application/octet-stream')
        #; [!xw0js] returns content type guessed from filename.
        #; [!dku5c] returns 'application/octet-stream' when failed to guess content type.
        ext = ::File.extname(filename)
        return Rack::Mime.mime_type(ext, default)
      end

    end


  end


end
