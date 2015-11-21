# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2015 kuwata-lab.com all rights reserved $
### $License: MIT License $
###


require 'json'
require 'uri'
require 'stringio'
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

      COOKIE_KEYS = {
        'path'     => :path,
        'domain'   => :domain,
        'expires'  => :expires,
        'max-age'  => :max_age,
        'httponly' => :httponly,
        'secure'   => :secure,
      }

      def parse_set_cookie(set_cookie_value)
        #; [!hvvu4] parses 'Set-Cookie' header value and returns hash object.
        keys = COOKIE_KEYS
        d = {}
        set_cookie_value.split(/;\s*/).each do |string|
          #; [!h75uc] sets true when value is missing such as 'secure' or 'httponly' attribute.
          k, v = string.strip().split('=', 2)
          #
          if d.empty?
            d[:name]  = k
            d[:value] = v
          elsif (sym = keys[k.downcase])
            #; [!q1h29] sets true as value for Secure or HttpOnly attribute.
            #; [!50iko] raises error when attribute value specified for Secure or HttpOnly attirbute.
            if sym == :secure || sym == :httponly
              v.nil?  or
                raise TypeError.new("#{k}=#{v}: unexpected attribute value.")
              v = true
            #; [!sucrm] raises error when attribute value is missing when neighter Secure nor HttpOnly.
            else
              ! v.nil?  or
                raise TypeError.new("#{k}: attribute value expected but not specified.")
              #; [!f3rk7] converts string into integer for Max-Age attribute.
              #; [!wgzyz] raises error when Max-Age attribute value is not a positive integer.
              if sym == :max_age
                v =~ /\A\d+\z/  or
                  raise TypeError.new("#{k}=#{v}: positive integer expected.")
                v = v.to_i
              end
            end
            d[sym] = v
          #; [!8xg63] raises ArgumentError when unknown attribute exists.
          else
            raise TypeError.new("#{k}=#{v}: unknown cookie attribute.")
          end
        end
        return d
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


    class MultipartBuilder

      def initialize(boundary=nil)
        #; [!ajfgl] sets random string as boundary when boundary is nil.
        @boundary = boundary || Util.randstr_b64()
        @params = []
      end

      attr_reader :boundary

      def add(name, value, filename=nil, content_type=nil)
        #; [!tp4bk] detects content type from filename when filename is not nil.
        content_type ||= Util.guess_content_type(filename) if filename
        @params << [name, value, filename, content_type]
        self
      end

      def add_file(name, file, content_type=nil)
        #; [!uafqa] detects content type from filename when content type is not provided.
        content_type ||= Util.guess_content_type(file.path)
        #; [!b5811] reads file content and adds it as param value.
        add(name, file.read(), ::File.basename(file.path), content_type)
        #; [!36bsu] closes opened file automatically.
        file.close()
        self
      end

      def to_s
        #; [!61gc4] returns multipart form string.
        boundary = @boundary
        s = "".force_encoding('ASCII-8BIT')
        @params.each do |name, value, filename, content_type|
          s <<   "--#{boundary}\r\n"
          if filename
            s << "Content-Disposition: form-data; name=\"#{name}\"; filename=\"#{filename}\"\r\n"
          else
            s << "Content-Disposition: form-data; name=\"#{name}\"\r\n"
          end
          s <<   "Content-Type: #{content_type}\r\n" if content_type
          s <<   "\r\n"
          s <<   value.force_encoding('ASCII-8BIT')
          s <<   "\r\n"
        end
        s <<     "--#{boundary}--\r\n"
        return s
      end

    end


    ##
    ## Builds environ hash object.
    ##
    ## ex:
    ##   json = {"x"=>1, "y"=>2}
    ##   env = Rack::TestApp.new_env(:POST, '/api/entry?x=1', json: json)
    ##   p env['REQUEST_METHOD']    #=> 'POST'
    ##   p env['PATH_INFO']         #=> '/api/entry'
    ##   p env['QUERY_STRING']      #=> 'x=1'
    ##   p env['CONTENT_TYPE']      #=> 'application/json'
    ##   p JSON.parse(env['rack.input'].read())  #=> {"x"=>1, "y"=>2}
    ##
    def self.new_env(meth=:GET, path="/", query: nil, form: nil, multipart: nil, json: nil, input: nil, headers: nil, cookies: nil, env: nil)
      #uri = "http://localhost:80#{path}"
      #opts["REQUEST_METHOD"] = meth
      #env = Rack::MockRequest.env_for(uri, opts)
      #
      #; [!j879z] sets 'HTTPS' with 'on' when 'rack.url_scheme' is 'https'.
      #; [!vpwvu] sets 'HTTPS' with 'on' when 'HTTPS' is 'on'.
      https = env && (env['rack.url_scheme'] == 'https' || env['HTTPS'] == 'on')
      #
      err = proc {|a, b|
        ArgumentError.new("new_env(): not allowed both '#{a}' and '#{b}' at a time.")
      }
      ctype = nil
      #; [!2uvyb] raises ArgumentError when both query string and 'query' kwarg specified.
      if query
        arr = path.split('?', 2)
        arr.length != 2  or
          raise ArgumentError.new("new_env(): not allowed both query string and 'query' kwarg at a time.")
      #; [!8tq3m] accepts query string in path string.
      else
        path, query = path.split('?', 2)
      end
      #; [!d1c83] when 'form' kwarg specified...
      if form
        #; [!c779l] raises ArgumentError when both 'form' and 'json' are specified.
        ! json  or raise err.call('form', 'json')
        input = Util.build_query_string(form)
        #; [!5iv35] sets content type with 'application/x-www-form-urlencoded'.
        ctype = "application/x-www-form-urlencoded"
      end
      #; [!prv5z] when 'json' kwarg specified...
      if json
        #; [!2o0ph] raises ArgumentError when both 'json' and 'multipart' are specified.
        ! multipart  or raise err.call('json', 'multipart')
        input = json.is_a?(String) ? json : JSON.dump(json)
        #; [!ta24a] sets content type with 'application/json'.
        ctype = "application/json"
      end
      #; [!dnvgj] when 'multipart' kwarg specified...
      if multipart
        #; [!b1d1t] raises ArgumentError when both 'multipart' and 'form' are specified.
        ! form  or raise err.call('multipart', 'form')
        #; [!gko8g] 'multipart:' kwarg accepts Hash object (which is converted into multipart data).
        if multipart.is_a?(Hash)
          dict = multipart
          multipart = dict.each_with_object(MultipartBuilder.new) do |(k, v), mp|
            v.is_a?(::File) ? mp.add_file(k, v) : mp.add(k, v.to_s)
          end
        end
        input = multipart.to_s
        #; [!dq33d] sets content type with 'multipart/form-data'.
        m = /\A--(\S+)\r\n/.match(input)  or
          raise ArgumentError.new("invalid multipart format.")
        boundary = $1
        ctype = "multipart/form-data; boundary=#{boundary}"
      end
      #; [!iamrk] uses 'application/x-www-form-urlencoded' as default content type of input.
      if input && ! ctype
        ctype ||= headers['Content-Type'] || headers['content-type'] if headers
        ctype ||= env['CONTENT_TYPE'] if env
        ctype ||= "application/x-www-form-urlencoded"
      end
      #; [!7hfri] converts input string into binary.
      input ||= ""
      input = input.encode('ascii-8bit') if input.encoding != Encoding::ASCII_8BIT
      #; [!r3soc] converts query string into binary.
      query_str = Util.build_query_string(query || "")
      query_str = query_str.encode('ascii-8bit')
      #; [!na9w6] builds environ hash object.
      environ = {
        "rack.version"      => [1, 3],
        "rack.input"        => StringIO.new(input),
        "rack.errors"       => StringIO.new,
        "rack.multithread"  => true,
        "rack.multiprocess" => true,
        "rack.run_once"     => false,
        "rack.url_scheme"   => https ? "https" : "http",
        "REQUEST_METHOD"    => meth.to_s,
        "SERVER_NAME"       => "localhost",
        "SERVER_PORT"       => https ? "443" : "80",
        "QUERY_STRING"      => query_str,
        "PATH_INFO"         => path,
        "HTTPS"             => https ? "on" : "off",
        "SCRIPT_NAME"       => "",
        "CONTENT_LENGTH"    => (input ? input.bytesize.to_s : "0"),
        "CONTENT_TYPE"      => ctype,
      }
      #; [!ezvdn] unsets CONTENT_TYPE when not input.
      environ.delete("CONTENT_TYPE") if input.empty?
      #; [!r4jz8] copies 'headers' kwarg content into environ with 'HTTP_' prefix.
      #; [!ai9t3] don't add 'HTTP_' to Content-Length and Content-Type headers.
      excepts = ['CONTENT_LENGTH', 'CONTENT_TYPE']
      headers.each do |name, value|
        name =~ /\A[a-zA-Z0-9]+(?:-[a-zA-Z0-9]+)*\z/  or
          raise ArgumentError.new("invalid http header name: #{name.inspect}")
        value.is_a?(String)  or
          raise ArgumentError.new("http header value should be a string but got: #{value.inspect}")
        ## ex: 'X-Requested-With' -> 'HTTP_X_REQUESTED_WITH'
        k = name.upcase.gsub(/-/, '_')
        k = "HTTP_#{k}" unless excepts.include?(k)
        environ[k] = value
      end if headers
      #; [!a47n9] copies 'env' kwarg content into environ.
      env.each do |name, value|
        case name
        when /\Arack\./
          # ok
        when /\A[A-Z]+(_[A-Z0-9]+)*\z/
          value.is_a?(String)  or
            raise ArgumentError.new("rack env value should be a string but got: #{value.inspect}")
        else
          raise ArgumentError.new("invalid rack env key: #{name}")
        end
        environ[name] = value
      end if env
      #; [!pmefk] sets 'HTTP_COOKIE' when 'cookie' kwarg specified.
      if cookies
        s = cookies.is_a?(Hash) ? cookies.map {|k, v|
          #; [!qj7b8] cookie value can be {:name=>'name', :value=>'value'}.
          v = v[:value] if v.is_a?(Hash) && v[:value]
          "#{Util.percent_encode(k)}=#{Util.percent_encode(v)}"
        }.join('; ') : cookies.to_s
        s = "#{environ['HTTP_COOKIE']}; #{s}" if environ['HTTP_COOKIE']
        environ['HTTP_COOKIE'] = s
      end
      #; [!b3ts8] returns environ hash object.
      return environ
    end


    class Result

      def initialize(status, headers, body)
        #; [!3lcsj] accepts response status, headers and body.
        @status  = status
        @headers = headers
        @body    = body
        #; [!n086q] parses 'Set-Cookie' header.
        @cookies = {}
        raw_str = @headers['Set-Cookie'] || @headers['set-cookie']
        raw_str.split(/\r?\n/).each do |s|
          if s && ! s.empty?
            c = Util.parse_set_cookie(s)
            @cookies[c[:name]] = c
          end
        end if raw_str
      end

      attr_accessor :status, :headers, :body, :cookies

      def body_binary
        #; [!mb0i4] returns body as binary string.
        buf = []; @body.each {|x| buf << x }
        s = buf.join()
        @body.close() if @body.respond_to?(:close)
        return s
      end

      def body_text
        #; [!rr18d] error when 'Content-Type' header is missing.
        ctype = self.content_type  or
          raise TypeError.new("body_text(): missing 'Content-Type' header.")
        #; [!dou1n] converts body text according to 'charset' in 'Content-Type' header.
        if ctype =~ /; *charset=(\w[-\w]*)/
          charset = $1
        #; [!cxje7] assumes charset as 'utf-8' when 'Content-Type' is json.
        elsif ctype == "application/json"
          charset = 'utf-8'
        #; [!n4c71] error when non-json 'Content-Type' header has no 'charset'.
        else
          raise TypeError.new("body_text(): missing 'charset' in 'Content-Type' header.")
        end
        #; [!vkj9h] returns body as text string, according to 'charset' in 'Content-Type'.
        return body_binary().force_encoding(charset)
      end

      def body_json
        #; [!qnic1] returns Hash object representing JSON string.
        return JSON.parse(body_text())
      end

      def content_type
        #; [!40hcz] returns 'Content-Type' header value.
        return @headers['Content-Type'] || @headers['content-type']
      end

      def content_length
        #; [!5lb19] returns 'Content-Length' header value as integer.
        #; [!qjktz] returns nil when 'Content-Length' is not set.
        len = @headers['Content-Length'] || @headers['content-length']
        return len ? Integer(len) : len
      end

      def location
        #; [!8y8lg] returns 'Location' header value.
        return @headers['Location'] || @headers['location']
      end

      def cookie_value(name)
        #; [!neaf8] returns cookie value if exists.
        #; [!oapns] returns nil if cookie not exists.
        c = @cookies[name]
        return c ? c[:value] : nil
      end

    end


    ##
    ## Wrapper class to test Rack application.
    ## Use 'Rack::TestApp.wrap(app)' instead of 'Rack::TestApp::Wrapper.new(app)'.
    ##
    ## ex:
    ##   require 'rack/lint'
    ##   require 'rack/test_app'
    ##   http  = Rack::TestApp.wrap(Rack::Lint.new(app))
    ##   https = Rack::TestApp.wrap(Rack::Lint.new(app)), env: {'HTTPS'=>'on'})
    ##   resp = http.GET('/api/hello', query: {'name'=>'World'})
    ##   assert_equal 200, resp.status
    ##   assert_equal "application/json", resp.headers['Content-Type']
    ##   assert_equal {"message"=>"Hello World!"}, resp.body_json
    ##
    class Wrapper

      def initialize(app, env=nil)
        #; [!zz9yg] takes app and optional env objects.
        @app = app
        @env = env
        @last_env = nil
      end

      attr_reader :last_env

      ##
      ## helper method to create new wrapper object keeping cookies and headers.
      ##
      ## ex:
      ##   http  = Rack::TestApp.wrap(Rack::Lint.new(app))
      ##   r1 = http.POST('/api/login', form: {user: 'user', password: 'pass'})
      ##   http.with(cookies: r1.cookies, headers: {}) do |http_|
      ##     r2 = http_.GET('/api/content')    # request with r1.cookies
      ##     assert_equal 200, r2.status
      ##   end
      ##
      def with(headers: nil, cookies: nil, env: nil)
        tmp_env = TestApp.new_env(headers: headers, cookies: cookies, env: env)
        new_env = @env ? @env.dup : {}
        http_headers = tmp_env.each do |k, v|
          new_env[k] = v if k.start_with?('HTTP_')
        end
        new_wrapper = self.class.new(@app, new_env)
        #; [!mkdbu] yields with new wrapper object if block given.
        yield new_wrapper if block_given?
        #; [!0bk12] returns new wrapper object, keeping cookies and headers.
        new_wrapper
      end

      def request(meth, path, query: nil, form: nil, multipart: nil, json: nil, input: nil, headers: nil, cookies: nil, env: nil)
        #; [!r6sod] merges @env if passed for initializer.
        env = env ? env.merge(@env) : @env if @env
        #; [!4xpwa] creates env object and calls app with it.
        environ = TestApp.new_env(meth, path,
                                  query: query, form: form, multipart: multipart, json: json,
                                  input: input, headers: headers, cookies: cookies, env: env)
        @last_env = environ
        tuple = @app.call(environ)
        status, headers, body = tuple
        #; [!eb153] returns Rack::TestApp::Result object.
        return Result.new(status, headers, body)
      end

      def GET     path, kwargs={}; request(:GET    , path, kwargs); end
      def POST    path, kwargs={}; request(:POST   , path, kwargs); end
      def PUT     path, kwargs={}; request(:PUT    , path, kwargs); end
      def DELETE  path, kwargs={}; request(:DELETE , path, kwargs); end
      def HEAD    path, kwargs={}; request(:HEAD   , path, kwargs); end
      def PATCH   path, kwargs={}; request(:PATCH  , path, kwargs); end
      def OPTIONS path, kwargs={}; request(:OPTIONS, path, kwargs); end
      def TRACE   path, kwargs={}; request(:TRACE  , path, kwargs); end

      ## define aliases because ruby programmer prefers #get() rather than #GET().
      alias get     GET
      alias post    POST
      alias put     PUT
      alias delete  DELETE
      alias head    HEAD
      alias patch   PATCH
      alias options OPTIONS
      alias trace   TRACE

    end


    ## Use Rack::TestApp.wrap(app) instead of Rack::TestApp::Wrapper.new(app).
    def self.wrap(app, env=nil)
      #; [!grqlf] creates new Wrapper object.
      return Wrapper.new(app, env)
    end


  end


end
