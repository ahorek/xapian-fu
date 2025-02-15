require 'xapian'
require File.expand_path('../lib/xapian_fu.rb', File.dirname(__FILE__))
include XapianFu

describe QueryParser do
  describe "parse_query" do
    it "should use the database's stopper" do
      xdb = XapianDb.new(:stopper => :french)
      qp = QueryParser.new(:database => xdb)
      terms = qp.parse_query("avec and").terms.collect { |t| t.term }
      terms.should_not include "Zavec"
      terms.should include "Zand"
    end

    it "should use the database's stemmer" do
      xdb = XapianDb.new(:stemmer => :french)
      qp = QueryParser.new(:database => xdb)
      terms = qp.parse_query("contournait fishing").terms.collect { |t| t.term }
      terms.should include "Zcontourn"
      terms.should_not include "Zfish"
    end

    it "should use stopper from options" do
      xdb = XapianDb.new(stemmer: :english)
      qp = QueryParser.new(database: xdb, language: :french)
      terms = qp.parse_query("avec and").terms.collect { |t| t.term }
      terms.should_not include "Zavec"
      terms.should include "Zand"
    end

    it "should use stemmer from options" do
      xdb = XapianDb.new(stemmer: :english)
      qp = QueryParser.new(database: xdb, language: :french)
      terms = qp.parse_query("contournait fishing").terms.collect { |t| t.term }
      terms.should include "Zcontourn"
      terms.should_not include "Zfish"
    end

    it "should use the :fields option to set field names" do
      qp = QueryParser.new(:fields => [:name, :age])
      terms = qp.parse_query("name:john age:30").terms.collect { |t| t.term }
      terms.should include "XNAMEjohn"
      terms.should_not include "john"
      terms.should include "XAGE30"
      terms.should_not include "30"
    end

    it "should use the database's field names as prefixes" do
      xdb = XapianDb.new(:fields => [:name], :stemmer => :none)
      qp = QueryParser.new(:database => xdb)
      terms = qp.parse_query("name:john").terms.collect { |t| t.term }
      terms.should include "XNAMEjohn"
      terms.should_not include "john"
    end

    it "should turn :all into a query with no terms" do
      qp = QueryParser.new
      qp.parse_query(:all).terms.should == []
      qp.parse_query(:all).empty?.should be_falsey
      qp.parse_query(:nothing).empty?.should be_truthy
    end

    it "should use cjk ngram parser" do
      qp = QueryParser.new(cjk: true)
      terms = qp.parse_query("生日快乐").terms.collect { |t| t.term }
      terms.should include "生日".force_encoding('ASCII-8BIT')
      terms.should include "快乐".force_encoding('ASCII-8BIT')
      terms.should include "生".force_encoding('ASCII-8BIT')
      terms.should include "乐".force_encoding('ASCII-8BIT')
    end

    it "should use the database's cjk flag" do
      xdb = XapianDb.new(cjk: true)
      qp = QueryParser.new(database: xdb)
      terms = qp.parse_query("生日快乐").terms.collect { |t| t.term }
      terms.should include "生日".force_encoding('ASCII-8BIT')
      terms.should include "快乐".force_encoding('ASCII-8BIT')
      terms.should include "生".force_encoding('ASCII-8BIT')
      terms.should include "乐".force_encoding('ASCII-8BIT')
    end

    it "should use the database's partial flag" do
      xdb = XapianDb.new(partial: true)
      qp = QueryParser.new(database: xdb)
      expect(qp.xapian_flags & Xapian::QueryParser::FLAG_PARTIAL).not_to be_zero
    end

    it "should use the query's partial flag" do
      qp = QueryParser.new(partial: true)
      expect(qp.xapian_flags & Xapian::QueryParser::FLAG_PARTIAL).not_to be_zero

      qp = QueryParser.new(partial: false)
      expect(qp.xapian_flags & Xapian::QueryParser::FLAG_PARTIAL).to be_zero
    end

    it "should prefer the query's partial flag" do
      xdb = XapianDb.new(partial: true)
      qp = QueryParser.new(database: xdb, partial: false)
      expect(qp.xapian_flags & Xapian::QueryParser::FLAG_PARTIAL).to be_zero

      xdb = XapianDb.new(partial: false)
      qp = QueryParser.new(database: xdb, partial: true)
      expect(qp.xapian_flags & Xapian::QueryParser::FLAG_PARTIAL).not_to be_zero
    end

  end

end

