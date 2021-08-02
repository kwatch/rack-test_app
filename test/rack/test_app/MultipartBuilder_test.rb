# -*- coding: utf-8 -*-

###
### $Release: 1.1.0 $
### $Copyright: copyright(c) 2015-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###


require_relative '../../test_helper'

require 'tempfile'
require 'rack/multipart'
require 'rack/mock'
require 'rack/request'


describe Rack::TestApp::MultipartBuilder do


  describe '#initialize()' do

    it "[!ajfgl] sets random string as boundary when boundary is nil." do
      arr = []
      1000.times do
        mp = Rack::TestApp::MultipartBuilder.new(nil)
        refute_nil mp.boundary
        assert_kind_of String, mp.boundary
        arr << mp.boundary
      end
      assert_equal 1000, arr.sort.uniq.length
    end

  end


  describe '#add()' do

    it "[!tp4bk] detects content type from filename when filename is not nil." do
      mp = Rack::TestApp::MultipartBuilder.new
      mp.add("name1", "value1")
      mp.add("name2", "value2", "foo.csv")
      mp.add("name3", "value3", "bar.csv", "text/plain")
      expected = [
        ["name1", "value1", nil, nil],
        #["name2", "value2", "foo.csv", "text/comma-separated-values"],
        ["name2", "value2", "foo.csv", "text/csv"],
        ["name3", "value3", "bar.csv", "text/plain"],
      ]
      assert_equal expected, mp.instance_variable_get('@params')
    end

  end


  describe '#add_file()' do

    data_dir = File.join(File.dirname(__FILE__), 'data')
    filename1 = File.join(data_dir, 'example1.png')
    filename2 = File.join(data_dir, 'example1.jpg')
    datafile  = File.join(data_dir, 'multipart.form')
    multipart_data = File.open(datafile, 'rb') {|f| f.read }

    it "[!uafqa] detects content type from filename when content type is not provided." do
      file1 = File.open(filename1)
      file2 = File.open(filename2)
      begin
        mp = Rack::TestApp::MultipartBuilder.new
        mp.add_file('image1', file1)
        mp.add_file('image2', file2)
        params = mp.instance_variable_get('@params')
        assert_equal "example1.png" , params[0][2]
        assert_equal "image/png"    , params[0][3]
        assert_equal "example1.jpg" , params[1][2]
        assert_equal "image/jpeg"   , params[1][3]
      ensure
        [file1, file2].each {|f| f.close() unless f.closed? }
      end
    end

    it "[!b5811] reads file content and adds it as param value." do
      file1 = File.open(filename1)
      file2 = File.open(filename2)
      begin
        boundary = '---------------------------68927884511827559971471404947'
        mp = Rack::TestApp::MultipartBuilder.new(boundary)
        mp.add('text1', "test1")
        mp.add('text2', "日本語\r\nあいうえお\r\n")
        mp.add_file('file1', file1)
        mp.add_file('file2', file2)
        expected = multipart_data
        assert expected, mp.to_s
      ensure
        [file1, file2].each {|f| f.close() unless f.closed? }
      end
    end

    it "[!36bsu] closes opened file automatically." do
      file1 = File.open(filename1)
      file2 = File.open(filename2)
      begin
        assert_equal false, file1.closed?
        assert_equal false, file2.closed?
        mp = Rack::TestApp::MultipartBuilder.new()
        mp.add_file('file1', file1)
        mp.add_file('file2', file2)
        assert_equal true, file1.closed?
        assert_equal true, file2.closed?
      ensure
        [file1, file2].each {|f| f.close() unless f.closed? }
      end
    end

  end


  describe '#to_s()' do

    it "[!61gc4] returns multipart form string." do
      mp = Rack::TestApp::MultipartBuilder.new("abc123")
      mp.add("name1", "value1")
      mp.add("name2", "value2", "foo.txt", "text/plain")
      s = mp.to_s
      expected = [
        "--abc123\r\n",
        "Content-Disposition: form-data; name=\"name1\"\r\n",
        "\r\n",
        "value1\r\n",
        "--abc123\r\n",
        "Content-Disposition: form-data; name=\"name2\"; filename=\"foo.txt\"\r\n",
        "Content-Type: text/plain\r\n",
        "\r\n",
        "value2\r\n",
        "--abc123--\r\n",
      ].join()
      s = mp.to_s
      assert_equal expected, s
      #
      opts = {
        :method => "POST",
        :input  => s,
        "CONTENT_TYPE"   => "multipart/form-data; boundary=abc123",
        "CONTENT_LENGTH" => s.bytesize,
      }
      env = Rack::MockRequest.env_for('http://localhost/form', opts)
      req = Rack::Request.new(env)
      params = req.POST
      assert_equal "value1",     params["name1"]
      assert_equal "name2",      params["name2"][:name]
      assert_equal "foo.txt",    params["name2"][:filename]
      assert_equal "text/plain", params["name2"][:type]
      assert_kind_of Tempfile,   params["name2"][:tempfile]
    end

  end


end
