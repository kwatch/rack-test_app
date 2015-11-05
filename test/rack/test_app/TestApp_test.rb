# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2015 kuwata-lab.com all rights reserved $
### $License: MIT License $
###


require_relative '../../test_helper'


describe Rack::TestApp do


  describe '::RELEASE' do

    it "represents release version number." do
      expected = '$Release: 0.0.0 $'.split()[1]
      assert_equal expected, Rack::TestApp::RELEASE
    end

  end


end
