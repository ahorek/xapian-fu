# encoding: utf-8
require 'xapian'
require File.expand_path('../lib/xapian_fu.rb', File.dirname(__FILE__))
include XapianFu
require 'fileutils'

describe StopperFactory do
  describe "stopper_for" do
    it "should return a SimpleStopper loaded with the given languages stop words" do
      stopper = StopperFactory.stopper_for(:english)
      stopper.should be_a_kind_of Xapian::SimpleStopper
      stopper.call("and").should be_truthy
      stopper.call("theremin").should_not be_truthy
    end

    it "should return the given stopper unmodified if given a Xapian::Stopper object" do
      stopper = Xapian::SimpleStopper.new
      StopperFactory.stopper_for(stopper).should === stopper
    end

    it "should return false when given false" do
      stopper = StopperFactory.stopper_for(false)
      stopper.should == false
    end
  end

  describe "stop_words_for" do

    it "should return an array of words for the given language" do
      words = StopperFactory.stop_words_for(:english)
      words.should be_a_kind_of Array
      words.should_not be_empty
      words.should include 'and'
      words.should include "they're"
    end

    %w(danish dutch english finnish french german hungarian italian norwegian portuguese russian spanish swedish).each do |lang|
      describe lang do
        it "should return an array of words" do
          words = StopperFactory.stop_words_for(lang.to_sym)
          words.should_not be_empty
        end

        it "should return an array with no empty strings, nils or pipes" do
          StopperFactory.stop_words_for(lang.to_sym).should_not include ''
          StopperFactory.stop_words_for(lang.to_sym).should_not include nil
          StopperFactory.stop_words_for(lang.to_sym).should_not include '|'
        end
      end
    end

    it "should return empty Xapian::SimpleStopper if there is no data for the given language" do
      StopperFactory.stopper_for(:no_existy).description.should === Xapian::SimpleStopper.new.description
    end

    it "should return characters in utf8" do
      words = StopperFactory.stop_words_for(:russian)
      words.should include "человек"
    end

  end
end
