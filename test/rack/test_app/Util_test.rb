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
      expected = nil
      assert_equal expected, Rack::TestApp::Util.build_query_string(nil)
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


  describe '.#randstr_b64()' do

    it "[!yq0gv] returns random string, encoded with urlsafe base64." do
      arr = (1..1000).map { Rack::TestApp::Util.randstr_b64() }
      assert_equal 1000, arr.sort.uniq.length
      arr.each do |s|
        assert_match /\A[-\w]+\z/, s
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
