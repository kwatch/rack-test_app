# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2015 kuwata-lab.com all rights reserved $
### $License: MIT License $
###


require_relative '../../test_helper'


describe Rack::TestApp::Util do


  describe '.#percent_encode()' do

    it "[!a96jo] encodes string into percent encoding format." do
      expected = "%5Bxxx%5D"
      assert_equal expected, Rack::TestApp::Util.percent_encode('[xxx]')
    end

  end


  describe '.#percent_decode()' do

    it "[!kl9sk] decodes percent encoded string." do
      expected = "[xxx]"
      assert_equal expected, Rack::TestApp::Util.percent_decode('%5Bxxx%5D')
    end

  end


  describe '.#build_query_string()' do

    it "[!098ac] returns nil when argument is nil." do
      assert_nil Rack::TestApp::Util.build_query_string(nil)
    end

    it "[!z9ds2] returns argument itself when it is a string." do
      query = "a=10&b=20"
      expected = query
      assert_equal expected, Rack::TestApp::Util.build_query_string(query)
    end

    it "[!m5yyh] returns query string when Hash or Array passed." do
      query = {a: 10, b: 20}
      expected = "a=10&b=20"
      assert_equal expected, Rack::TestApp::Util.build_query_string(query)
      #
      query = [[:a, 10], ["b", 20]]
      expected = "a=10&b=20"
      assert_equal expected, Rack::TestApp::Util.build_query_string(query)
    end

    it "[!nksh3] raises ArgumentError when passed value except nil, string, hash or array." do
      ex = assert_raises ArgumentError do
        Rack::TestApp::Util.build_query_string(123)
      end
      assert_equal ex.message, "Hash or Array expected but got 123."
    end

  end


  describe '.#parse_set_cookie()' do

    it "[!hvvu4] parses 'Set-Cookie' header value and returns hash object." do
      set_cookie = "name1=value1; Domain=localhost; Path=/; Expires=Monday, 15-Aug-2005 15:52:01 UTC; Max-Age=3600; Secure; HttpOnly"
      expected = {
        :name     => "name1",
        :value    => "value1",
        :domain   => "localhost",
        :path     => "/",
        :expires  => "Monday, 15-Aug-2005 15:52:01 UTC",
        :max_age  => 3600,
        :secure   => true,
        :httponly => true,
      }
      actual = Rack::TestApp::Util.parse_set_cookie(set_cookie)
      assert_equal expected, actual
    end

    it "[!q1h29] sets true as value for Secure or HttpOnly attribute." do
      set_cookie = "name1=value1; secure; httponly"
      expected = {
        :name     => "name1",
        :value    => "value1",
        :secure   => true,
        :httponly => true,
      }
      actual = Rack::TestApp::Util.parse_set_cookie(set_cookie)
      assert_equal expected, actual
    end

    it "[!50iko] raises error when attribute value specified for Secure or HttpOnly attirbute." do
      set_cookie = "name1=value1; Secure=1"
      ex = assert_raises(TypeError) { Rack::TestApp::Util.parse_set_cookie(set_cookie) }
      assert_equal "Secure=1: unexpected attribute value.", ex.message
      #
      set_cookie = "name1=value1; HttpOnly=1"
      ex = assert_raises(TypeError) { Rack::TestApp::Util.parse_set_cookie(set_cookie) }
      assert_equal "HttpOnly=1: unexpected attribute value.", ex.message
    end

    it "[!sucrm] raises error when attribute value is missing when neighter Secure nor HttpOnly." do
      set_cookie = "name1=value1; Path"
      ex = assert_raises(TypeError) { Rack::TestApp::Util.parse_set_cookie(set_cookie) }
      assert_equal "Path: attribute value expected but not specified.", ex.message
    end

    it "[!f3rk7] converts string into integer for Max-Age attribute." do
      set_cookie = "name1=value1; Max-Age=3600"
      c = Rack::TestApp::Util.parse_set_cookie(set_cookie)
      assert_equal 3600, c[:max_age]
      assert_kind_of Fixnum, c[:max_age]
    end

    it "[!wgzyz] raises error when Max-Age attribute value is not a positive integer." do
      set_cookie = "name1=value1; Max-Age=30sec"
      ex = assert_raises(TypeError) { Rack::TestApp::Util.parse_set_cookie(set_cookie) }
      assert_equal "Max-Age=30sec: positive integer expected.", ex.message
    end

    it "[!8xg63] raises ArgumentError when unknown attribute exists." do
      set_cookie = "name1=value1; MaxAge=3600"
      ex = assert_raises(TypeError) { Rack::TestApp::Util.parse_set_cookie(set_cookie) }
      assert_equal "MaxAge=3600: unknown cookie attribute.", ex.message
    end

  end


  describe '.#randstr_b64()' do

    it "[!yq0gv] returns random string, encoded with urlsafe base64." do
      arr = (1..1000).map { Rack::TestApp::Util.randstr_b64() }
      assert_equal 1000, arr.sort.uniq.length
      arr.each do |s|
        assert_match(/\A[-\w]+\z/, s)
        assert_equal 27, s.length
      end
    end

  end


  describe '.#guess_content_type()' do

    it "[!xw0js] returns content type guessed from filename." do
      assert_equal "text/html"       , Rack::TestApp::Util.guess_content_type("foo.html")
      assert_equal "image/jpeg"      , Rack::TestApp::Util.guess_content_type("foo.jpg")
      assert_equal "application/json", Rack::TestApp::Util.guess_content_type("foo.json")
      assert_equal "application/vnd.ms-excel", Rack::TestApp::Util.guess_content_type("foo.xls")
    end

    it "[!dku5c] returns 'application/octet-stream' when failed to guess content type." do
      assert_equal "application/octet-stream", Rack::TestApp::Util.guess_content_type("foo.rbc")
      assert_equal "application/octet-stream", Rack::TestApp::Util.guess_content_type("foo")
    end

  end


end
