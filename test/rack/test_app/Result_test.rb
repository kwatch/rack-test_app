# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2015-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###


require_relative '../../test_helper'


describe Rack::TestApp::Result do


  describe '#initialize()' do

    it "[!3lcsj] accepts response status, headers and body." do
      r = Rack::TestApp::Result.new(200, {"Content-Type"=>"text/plain"}, ["Hello"])
      assert 200, r.status
      assert({"Content-Type"=>"text/plain"}, r.headers)
      assert ["Hello"], r.body
    end

    it "[!n086q] parses 'Set-Cookie' header." do
      headers = {
        "Content-Type"=>"text/plain",
        "Set-Cookie"=>("key1=value1; Path=/; Domain=example.com; HttpOnly; Secure\n" +
                       "key2=value2"),
      }
      expected = {
        'key1' => {
          :name     => 'key1',
          :value    => 'value1',
          :path     => '/',
          :domain   => 'example.com',
          :httponly => true,
          :secure   => true,
        },
        'key2' => {
          :name     => 'key2',
          :value    => 'value2',
        },
      }
      r = Rack::TestApp::Result.new(200, headers, ["Hello"])
      assert_equal expected, r.cookies
    end

  end


  describe '#body_binary' do

    it "[!mb0i4] returns body as binary string." do
      r = Rack::TestApp::Result.new(200, {}, ["Hello"])
      assert_equal "Hello", r.body_binary
    end

  end


  describe '#body_text' do

    it "[!vkj9h] returns body as text string, according to 'charset' in 'Content-Type'." do
      headers = {'Content-Type' => 'text/plain; charset=utf-8'}
      r = Rack::TestApp::Result.new(200, headers, ["Hello"])
      assert_equal "Hello", r.body_text
    end

    it "[!rr18d] error when 'Content-Type' header is missing." do
      headers = {}
      r = Rack::TestApp::Result.new(200, headers, ["Hello"])
      ex = assert_raises(TypeError) { r.body_text }
      assert_equal "body_text(): missing 'Content-Type' header.", ex.message
    end

    it "[!dou1n] converts body text according to 'charset' in 'Content-Type' header." do
      headers = {'Content-Type' => 'text/plain; charset=utf-8'}
      binary = "\u3042\u3044\u3046\u3048\u304A"
      assert_equal binary, "あいうえお".encode('utf-8')
      r = Rack::TestApp::Result.new(200, headers, [binary])
      assert_equal "あいうえお", r.body_text
      assert_equal 'UTF-8', r.body_text.encoding.name
    end

    it "[!cxje7] assumes charset as 'utf-8' when 'Content-Type' is json." do
      headers = {'Content-Type' => 'application/json'}
      binary = %Q`{"msg":"\u3042\u3044\u3046\u3048\u304A"}`
      assert_equal binary, %Q`{"msg":"あいうえお"}`.encode('utf-8')
      r = Rack::TestApp::Result.new(200, headers, [binary])
      assert_equal %Q`{"msg":"あいうえお"}`, r.body_text
      assert_equal 'UTF-8', r.body_text.encoding.name
    end

    it "[!n4c71] error when non-json 'Content-Type' header has no 'charset'." do
      headers = {'Content-Type' => 'text/plain'}
      binary = "\u3042\u3044\u3046\u3048\u304A"
      assert_equal binary, "あいうえお".encode('utf-8')
      r = Rack::TestApp::Result.new(200, headers, [binary])
      ex = assert_raises(TypeError) { r.body_text }
      assert_equal "body_text(): missing 'charset' in 'Content-Type' header.", ex.message
    end

  end


  describe '#body_json' do

    it "[!qnic1] returns Hash object representing JSON string." do
      headers = {'Content-Type' => 'application/json'}
      binary = %Q`{"msg":"\u3042\u3044\u3046\u3048\u304A"}`
      assert_equal binary, %Q`{"msg":"あいうえお"}`.encode('utf-8')
      r = Rack::TestApp::Result.new(200, headers, [binary])
      assert_equal({"msg"=>"あいうえお"}, r.body_json)
    end

  end


  describe '#content_type' do

    it "[!40hcz] returns 'Content-Type' header value." do
      headers = {'Content-Type' => 'application/json'}
      r = Rack::TestApp::Result.new(200, headers, [])
      assert_equal "application/json", r.content_type
      #
      headers = {'content-type' => 'application/json'}
      r = Rack::TestApp::Result.new(200, headers, [])
      assert_equal "application/json", r.content_type
    end

  end


  describe '' do

    it "[!5lb19] returns 'Content-Length' header value as integer." do
      headers = {'Content-Length' => '123'}
      r = Rack::TestApp::Result.new(200, headers, [])
      assert_equal 123, r.content_length
      #
      headers = {'content-length' => '123'}
      r = Rack::TestApp::Result.new(200, headers, [])
      assert_equal 123, r.content_length
    end

    it "[!qjktz] returns nil when 'Content-Length' is not set." do
      headers = {'Content-Type' => 'text/plain'}
      r = Rack::TestApp::Result.new(200, headers, ["Hello"])
      assert_nil r.content_length
    end

  end


  describe '#location' do

    it "[!8y8lg] returns 'Location' header value." do
      headers = {'Location' => '/foo'}
      r = Rack::TestApp::Result.new(302, headers, [])
      assert_equal '/foo', r.location
    end

  end


  describe '#cookie_value' do

    it "[!neaf8] returns cookie value if exists." do
      headers = {'Set-Cookie' => 'name1=value1'}
      r = Rack::TestApp::Result.new(200, headers, [])
      assert_equal 'value1', r.cookie_value('name1')
    end

    it "[!oapns] returns nil if cookie not exists." do
      headers = {'Set-Cookie' => 'name1=value1'}
      r = Rack::TestApp::Result.new(200, headers, [])
      assert_nil r.cookie_value('name2')
    end

  end


end
