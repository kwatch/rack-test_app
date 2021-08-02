# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2015 kuwata-lab.com all rights reserved $
### $License: MIT License $
###


require_relative '../../test_helper'


describe Rack::TestApp do

  class << self
    alias context describe       # minitest doesn't provide 'context' method
  end


  describe '::VERSION' do

    it "represents release version number." do
      expected = '$Release: 0.0.0 $'.split()[1]
      assert_equal expected, Rack::TestApp::VERSION
    end

  end


  describe '.new_env()' do

    it "[!b3ts8] returns environ hash object." do
      env = Rack::TestApp.new_env()
      assert_kind_of Hash, env
      assert_equal 'GET', env['REQUEST_METHOD']
      assert_equal '/',   env['PATH_INFO']
    end

    it "[!j879z] sets 'HTTPS' with 'on' when 'rack.url_scheme' is 'https'." do
      env = Rack::TestApp.new_env(env: {'rack.url_scheme'=>'https'})
      assert_equal 'on', env['HTTPS']
      assert_equal 'https', env['rack.url_scheme']
    end

    it "[!vpwvu] sets 'HTTPS' with 'on' when 'HTTPS' is 'on'." do
      env = Rack::TestApp.new_env(env: {'HTTPS'=>'on'})
      assert_equal 'on', env['HTTPS']
      assert_equal 'https', env['rack.url_scheme']
    end

    it "[!2uvyb] raises ArgumentError when both query string and 'query' kwarg specified." do
      ex = assert_raises(ArgumentError) do
        Rack::TestApp.new_env(:GET, '/path?x=1', query: {'y'=>2})
      end
      assert_equal "new_env(): not allowed both query string and 'query' kwarg at a time.", ex.message
    end

    it "[!8tq3m] accepts query string in path string." do
      env = Rack::TestApp.new_env(:GET, '/path?x=1')
      assert_equal 'x=1', env['QUERY_STRING']
    end

    context "[!d1c83] when 'form' kwarg specified..." do

      it "[!c779l] raises ArgumentError when both 'form' and 'json' are specified." do
        ex = assert_raises(ArgumentError) do
          Rack::TestApp.new_env(form: {}, json: {})
        end
        assert_equal "new_env(): not allowed both 'form' and 'json' at a time.", ex.message
      end

      it "[!5iv35] sets content type with 'application/x-www-form-urlencoded'." do
        env = Rack::TestApp.new_env(form: {'x'=>1})
        assert_equal 'application/x-www-form-urlencoded', env['CONTENT_TYPE']
      end

    end

    context "[!prv5z] when 'json' kwarg specified..." do

      it "[!2o0ph] raises ArgumentError when both 'json' and 'multipart' are specified." do
        ex = assert_raises(ArgumentError) do
          Rack::TestApp.new_env(json: {}, multipart: {})
        end
        assert_equal "new_env(): not allowed both 'json' and 'multipart' at a time.", ex.message
      end

      it "[!ta24a] sets content type with 'application/json'." do
        env = Rack::TestApp.new_env(json: {'x'=>1})
        assert_equal 'application/json', env['CONTENT_TYPE']
      end

    end

    context "[!dnvgj] when 'multipart' kwarg specified..." do

      it "[!b1d1t] raises ArgumentError when both 'multipart' and 'form' are specified." do
        ex = assert_raises(ArgumentError) do
          Rack::TestApp.new_env(multipart: {}, form: {})
        end
        assert_equal "new_env(): not allowed both 'multipart' and 'form' at a time.", ex.message
      end

      it "[!dq33d] sets content type with 'multipart/form-data'." do
        env = Rack::TestApp.new_env(multipart: {})
        rexp = /\Amultipart\/form-data; boundary=\S+\z/
        assert_match rexp, env['CONTENT_TYPE']
      end

      it "[!gko8g] 'multipart:' kwarg accepts Hash object (which is converted into multipart data)." do
        fpath = File.join(File.dirname(__FILE__), "data", "example1.jpg")
        file = File.open(fpath, 'rb')
        env = Rack::TestApp.new_env(multipart: {
          "value"  => 123,
          "upload" => file,
        })
        assert_equal true, file.closed?
        req = Rack::Request.new(env)
        params = req.POST
        assert_equal "123",           params['value']
        assert_equal "upload",        params['upload'][:name]
        assert_equal "example1.jpg",  params['upload'][:filename]
        assert_equal "image/jpeg",    params['upload'][:type]
        assert_kind_of Tempfile,      params['upload'][:tempfile]
      end

    end

    it "[!iamrk] uses 'application/x-www-form-urlencoded' as default content type of input." do
      env = Rack::TestApp.new_env(:POST, '/', input: 'x=1')
      assert_equal 'application/x-www-form-urlencoded', env['CONTENT_TYPE']
    end

    it "[!7hfri] converts input string into binary." do
      form = {"x"=>"あいうえお"}
      env = Rack::TestApp.new_env(:POST, '/api/hello', form: form)
      s = env['rack.input'].read()
      assert_equal Encoding::ASCII_8BIT, s.encoding
    end

    it "[!r3soc] converts query string into binary." do
      query = {"x"=>"あいうえお"}
      env = Rack::TestApp.new_env(:POST, '/api/hello', query: query)
      s = env['QUERY_STRING']
      assert_equal Encoding::ASCII_8BIT, s.encoding
    end

    it "[!na9w6] builds environ hash object." do
      env = Rack::TestApp.new_env(:POST, '/api/session?q=test')
      #
      assert_equal Rack::VERSION   , env['rack.version']
      assert_kind_of Array         , env['rack.version']
      assert_match(/\A\[1, \d+\]\z/, env['rack.version'].inspect)
      assert_kind_of StringIO      , env['rack.input']
      assert_kind_of StringIO      , env['rack.errors']
      assert_equal true            , env['rack.multithread']
      assert_equal true            , env['rack.multiprocess']
      assert_equal false           , env['rack.run_once']
      assert_equal 'http'          , env['rack.url_scheme']
      #
      assert_equal 'POST'          , env['REQUEST_METHOD']
      assert_equal 'q=test'        , env['QUERY_STRING']
      assert_equal 'localhost'     , env['SERVER_NAME']
      assert_equal '80'            , env['SERVER_PORT']
      assert_equal 'q=test'        , env['QUERY_STRING']
      assert_equal '/api/session'  , env['PATH_INFO']
      assert_equal 'off'           , env['HTTPS']
      assert_equal ''              , env['SCRIPT_NAME']
      assert_equal '0'             , env['CONTENT_LENGTH']
      assert_equal nil             , env['CONTENT_TYPE']
    end

    it "[!ezvdn] unsets CONTENT_TYPE when not input." do
      env = Rack::TestApp.new_env(:POST, '/api/session?q=test')
      assert_nil env['CONTENT_TYPE']
      assert_equal false, env.key?('CONTENT_TYPE')
    end

    it "[!r4jz8] copies 'headers' kwarg content into environ with 'HTTP_' prefix." do
      headers = {
        'If-Modified-Since'      => 'Mon, 02 Feb 2015 19:05:06 GMT',
        'X-Requested-With'       => 'XMLHttpRequest'
      }
      env = Rack::TestApp.new_env(:PUT, '/', headers: headers)
      assert_equal 'Mon, 02 Feb 2015 19:05:06 GMT', env['HTTP_IF_MODIFIED_SINCE']
      assert_equal 'XMLHttpRequest', env['HTTP_X_REQUESTED_WITH']
    end

    it "[!ai9t3] don't add 'HTTP_' to Content-Length and Content-Type headers." do
      headers = {
        'Content-Type'           => 'application/json',
        'Content-Length'         => '123',
      }
      env = Rack::TestApp.new_env(:PUT, '/', headers: headers)
      assert_equal 'application/json', env['CONTENT_TYPE']
      assert_equal '123',              env['CONTENT_LENGTH']
      assert_equal false, env.key?('HTTP_CONTENT_TYPE')
      assert_equal false, env.key?('HTTP_CONTENT_LENGTH')
    end

    it "[!a47n9] copies 'env' kwarg content into environ." do
      environ = {
        'rack.session' => {'k1'=>'v1'},
      }
      env = Rack::TestApp.new_env(:PUT, '/', env: environ)
      expected = {'k1'=>'v1'}
      assert_equal expected, env['rack.session']
    end

    it "[!pmefk] sets 'HTTP_COOKIE' when 'cookie' kwarg specified." do
      env = Rack::TestApp.new_env(cookies: 'c1=v1')
      assert_equal 'c1=v1', env['HTTP_COOKIE']
      env = Rack::TestApp.new_env(cookies: {'c2'=>'v2'})
      assert_equal 'c2=v2', env['HTTP_COOKIE']
    end

    it "[!qj7b8] cookie value can be {:name=>'name', :value=>'value'}." do
      env = Rack::TestApp.new_env(cookies: {'c3'=>{name: 'c3', value: 'v3'}})
      assert_equal 'c3=v3', env['HTTP_COOKIE']
    end

  end


  describe '.wrap()' do

    it "[!grqlf] creates new Wrapper object." do
      app = proc {|env| [200, {}, []] }
      env = {"HTTPS"=>"on"}
      wrapper = Rack::TestApp.wrap(app, env)
      assert_kind_of Rack::TestApp::Wrapper, wrapper
      assert_equal app, wrapper.instance_variable_get('@app')
      assert_equal env, wrapper.instance_variable_get('@env')
    end

  end


end
