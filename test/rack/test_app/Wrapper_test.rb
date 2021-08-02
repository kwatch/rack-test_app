# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2015 kuwata-lab.com all rights reserved $
### $License: MIT License $
###


require_relative '../../test_helper'


describe Rack::TestApp::Wrapper do

  app = proc {|env|
    text = "#{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
    text << "?#{env['QUERY_STRING']}" unless env['QUERY_STRING'].to_s.empty?
    text = "" if env['REQUEST_METHOD'] == 'HEAD'
    [200, {"Content-Type"=>"text/plain;charset=utf-8"}, [text]]
  }
  app = Rack::Lint.new(app)


  describe '#initialize()' do

    it "[!zz9yg] takes app and optional env objects." do
      env = {"HTTPS"=>"on"}
      wrapper = Rack::TestApp::Wrapper.new(app, env)
      assert_equal app, wrapper.instance_variable_get('@app')
      assert_equal env, wrapper.instance_variable_get('@env')
      #
      wrapper = Rack::TestApp::Wrapper.new(app)
      assert_equal app, wrapper.instance_variable_get('@app')
      assert_nil        wrapper.instance_variable_get('@env')
    end

  end


  describe '#with()' do

    it "[!0bk12] returns new wrapper object, keeping cookies and headers." do
      wrapper = Rack::TestApp::Wrapper.new(app)
      cookies = {'k1'=>{name: 'k1', value: 'v1'}}
      headers = {'X-Requested-With'=>'XMLHttpRequest'}
      new_wrapper = wrapper.with(cookies: cookies, headers: headers)
      assert_kind_of Rack::TestApp::Wrapper, new_wrapper
      expected = {"HTTP_X_REQUESTED_WITH"=>"XMLHttpRequest", "HTTP_COOKIE"=>"k1=v1"}
      assert_equal expected, new_wrapper.instance_variable_get('@env')
    end

    it "[!mkdbu] yields with new wrapper object if block given." do
      wrapper = Rack::TestApp::Wrapper.new(app)
      cookies = {'k1'=>{name: 'k1', value: 'v1'}}
      headers = {'X-Requested-With'=>'XMLHttpRequest'}
      wrapper.with(cookies: cookies, headers: headers) do |new_wrapper|
        assert_kind_of Rack::TestApp::Wrapper, new_wrapper
        expected = {"HTTP_X_REQUESTED_WITH"=>"XMLHttpRequest", "HTTP_COOKIE"=>"k1=v1"}
        assert_equal expected, new_wrapper.instance_variable_get('@env')
      end
    end

  end


  describe '#request()' do

    it "[!eb153] returns Rack::TestApp::Result object." do
      wrapper = Rack::TestApp::Wrapper.new(app)
      r = wrapper.request(:POST, '/hello')
      assert_kind_of Rack::TestApp::Result, r
    end

    it "[!4xpwa] creates env object and calls app with it." do
      wrapper = Rack::TestApp::Wrapper.new(app)
      wrapper.request(:POST, '/hello')
      assert_equal 'POST',   wrapper.last_env['REQUEST_METHOD']
      assert_equal '/hello', wrapper.last_env['PATH_INFO']
    end

    it "[!r6sod] merges @env if passed for initializer." do
      wrapper = Rack::TestApp::Wrapper.new(app, {"HTTPS"=>"on"})
      wrapper.request(:POST, '/hello')
      assert_equal 'on', wrapper.last_env['HTTPS']
      #
      wrapper = Rack::TestApp::Wrapper.new(app)
      wrapper.request(:POST, '/hello')
      assert_equal 'off', wrapper.last_env['HTTPS']
    end

  end


  describe '#GET()' do

    it "requests with GET method." do
      wrapper = Rack::TestApp::Wrapper.new(app)
      r = wrapper.GET('/api/foo', query: {"id"=>123})
      assert_equal "GET /api/foo?id=123", r.body_text
    end

  end


  describe '#POST()' do

    it "requests with POST method." do
      wrapper = Rack::TestApp::Wrapper.new(app)
      r = wrapper.POST('/api/foo', form: {"id"=>123})
      assert_equal "POST /api/foo", r.body_text
    end

  end


  describe '#PUT()' do

    it "requests with PUT method." do
      wrapper = Rack::TestApp::Wrapper.new(app)
      r = wrapper.PUT('/api/foo', form: {"id"=>123})
      assert_equal "PUT /api/foo", r.body_text
    end

  end


  describe '#DELETE()' do

    it "requests with DELETE method." do
      wrapper = Rack::TestApp::Wrapper.new(app)
      r = wrapper.DELETE('/api/foo', form: {"id"=>123})
      assert_equal "DELETE /api/foo", r.body_text
    end

  end


  describe '#HEAD()' do

    it "requests with HEAD method." do
      wrapper = Rack::TestApp::Wrapper.new(app)
      r = wrapper.HEAD('/api/foo', query: {"id"=>123})
      assert_equal "", r.body_text
    end

  end


  describe '#PATCH()' do

    it "requests with PATCH method." do
      wrapper = Rack::TestApp::Wrapper.new(app)
      r = wrapper.PATCH('/api/foo', form: {"id"=>123})
      assert_equal "PATCH /api/foo", r.body_text
    end

  end


  describe '#OPTIONS()' do

    it "requests with OPTIONS method." do
      wrapper = Rack::TestApp::Wrapper.new(app)
      r = wrapper.OPTIONS('/api/foo', form: {"id"=>123})
      assert_equal "OPTIONS /api/foo", r.body_text
    end

  end


  describe '#TRACE()' do

    it "requests with TRACE method." do
      wrapper = Rack::TestApp::Wrapper.new(app)
      r = wrapper.TRACE('/api/foo', form: {"id"=>123})
      assert_equal "TRACE /api/foo", r.body_text
    end

  end


end
