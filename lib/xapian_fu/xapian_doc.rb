class Time #:nodoc:
  def to_xapian_fu_string
    utc.strftime("%Y%m%d%H%M%S")
  end
end

class Date #:nodoc:
  def to_xapian_fu_string
    strftime("%Y%m%d")
  end
end

require 'date'

class DateTime #:nodoc:
  def to_xapian_fu_string
    strftime("%Y%m%d%H%M%S")
  end
end

class Array #:nodoc:
  def to_xapian_fu_string
    join(" ")
  end
end

module XapianFu #:nodoc:
  require 'xapian_doc_value_accessor'

  # Raised whenever a XapianDb is needed but has not been provided,
  # such as when retrieving the terms list for a document
  class XapianDbNotSet < XapianFuError ; end
  # Raised if a given value cannot be stored in the database (anything
  # without a to_s method)
  class XapianTypeError < XapianFuError ; end

  # A XapianDoc represents a document in a XapianDb.  Searches return
  # XapianDoc objects and they are used internally when adding new
  # documents to the database.  You usually don't need to instantiate
  # them yourself unless you're doing something a bit advanced.
  class XapianDoc

    DEFAULT_APPROXIMATIONS = {
      "À"=>"A", "Á"=>"A", "Â"=>"A", "Ã"=>"A", "Ä"=>"A", "Å"=>"A", "Æ"=>"AE",
      "Ç"=>"C", "È"=>"E", "É"=>"E", "Ê"=>"E", "Ë"=>"E", "Ì"=>"I", "Í"=>"I",
      "Î"=>"I", "Ï"=>"I", "Ð"=>"D", "Ñ"=>"N", "Ò"=>"O", "Ó"=>"O", "Ô"=>"O",
      "Õ"=>"O", "Ö"=>"O", "×"=>"x", "Ø"=>"O", "Ù"=>"U", "Ú"=>"U", "Û"=>"U",
      "Ü"=>"U", "Ý"=>"Y", "Þ"=>"Th", "ß"=>"ss", "à"=>"a", "á"=>"a", "â"=>"a",
      "ã"=>"a", "ä"=>"a", "å"=>"a", "æ"=>"ae", "ç"=>"c", "è"=>"e", "é"=>"e",
      "ê"=>"e", "ë"=>"e", "ì"=>"i", "í"=>"i", "î"=>"i", "ï"=>"i", "ð"=>"d",
      "ñ"=>"n", "ò"=>"o", "ó"=>"o", "ô"=>"o", "õ"=>"o", "ö"=>"o", "ø"=>"o",
      "ù"=>"u", "ú"=>"u", "û"=>"u", "ü"=>"u", "ý"=>"y", "þ"=>"th", "ÿ"=>"y",
      "Ā"=>"A", "ā"=>"a", "Ă"=>"A", "ă"=>"a", "Ą"=>"A", "ą"=>"a", "Ć"=>"C",
      "ć"=>"c", "Ĉ"=>"C", "ĉ"=>"c", "Ċ"=>"C", "ċ"=>"c", "Č"=>"C", "č"=>"c",
      "Ď"=>"D", "ď"=>"d", "Đ"=>"D", "đ"=>"d", "Ē"=>"E", "ē"=>"e", "Ĕ"=>"E",
      "ĕ"=>"e", "Ė"=>"E", "ė"=>"e", "Ę"=>"E", "ę"=>"e", "Ě"=>"E", "ě"=>"e",
      "Ĝ"=>"G", "ĝ"=>"g", "Ğ"=>"G", "ğ"=>"g", "Ġ"=>"G", "ġ"=>"g", "Ģ"=>"G",
      "ģ"=>"g", "Ĥ"=>"H", "ĥ"=>"h", "Ħ"=>"H", "ħ"=>"h", "Ĩ"=>"I", "ĩ"=>"i",
      "Ī"=>"I", "ī"=>"i", "Ĭ"=>"I", "ĭ"=>"i", "Į"=>"I", "į"=>"i", "İ"=>"I",
      "ı"=>"i", "Ĳ"=>"IJ", "ĳ"=>"ij", "Ĵ"=>"J", "ĵ"=>"j", "Ķ"=>"K", "ķ"=>"k",
      "ĸ"=>"k", "Ĺ"=>"L", "ĺ"=>"l", "Ļ"=>"L", "ļ"=>"l", "Ľ"=>"L", "ľ"=>"l",
      "Ŀ"=>"L", "ŀ"=>"l", "Ł"=>"L", "ł"=>"l", "Ń"=>"N", "ń"=>"n", "Ņ"=>"N",
      "ņ"=>"n", "Ň"=>"N", "ň"=>"n", "ŉ"=>"'n", "Ŋ"=>"NG", "ŋ"=>"ng",
      "Ō"=>"O", "ō"=>"o", "Ŏ"=>"O", "ŏ"=>"o", "Ő"=>"O", "ő"=>"o", "Œ"=>"OE",
      "œ"=>"oe", "Ŕ"=>"R", "ŕ"=>"r", "Ŗ"=>"R", "ŗ"=>"r", "Ř"=>"R", "ř"=>"r",
      "Ś"=>"S", "ś"=>"s", "Ŝ"=>"S", "ŝ"=>"s", "Ş"=>"S", "ş"=>"s", "Š"=>"S",
      "š"=>"s", "Ţ"=>"T", "ţ"=>"t", "Ť"=>"T", "ť"=>"t", "Ŧ"=>"T", "ŧ"=>"t",
      "Ũ"=>"U", "ũ"=>"u", "Ū"=>"U", "ū"=>"u", "Ŭ"=>"U", "ŭ"=>"u", "Ů"=>"U",
      "ů"=>"u", "Ű"=>"U", "ű"=>"u", "Ų"=>"U", "ų"=>"u", "Ŵ"=>"W", "ŵ"=>"w",
      "Ŷ"=>"Y", "ŷ"=>"y", "Ÿ"=>"Y", "Ź"=>"Z", "ź"=>"z", "Ż"=>"Z", "ż"=>"z",
      "Ž"=>"Z", "ž"=>"z"
    }.freeze

    # A hash of the fields given to this object on initialize
    attr_reader :fields

    # An abitrary blob of data stored alongside the document in the
    # Xapian database.
    attr_reader :data

    # The search score of this document when returned as part of a
    # search result
    attr_reader :weight

    # The Xapian::Match object for this document when returned as part
    # of a search result.
    attr_reader :match

    # The unsigned integer "primary key" for this document in the
    # Xapian database.
    attr_accessor :id

    # The XapianDb object that this document was retrieved from, or
    # should be stored in.
    attr_accessor :db

    # Expects a Xapian::Document, a Hash-like object, or anything that
    # with a to_s method.  Anything else raises a XapianTypeError.
    # The <tt>:weight</tt> option sets the search weight when setting
    # up search results.  The <tt>:data</tt> option sets some
    # additional data to be stored with the document in the database.
    # The <tt>:xapian_db</tt> option sets the XapianDb to allow saves
    # and term enumeration.
    def initialize(doc, options = {})
      @options = options

      @fields = {}
      if doc.is_a? Xapian::Match
        match = doc
        doc = match.document
        @match = match
        @weight = @match.weight
      end

      # Handle initialisation from a Xapian::Document, which is
      # usually a search result from a Xapian database
      if doc.is_a?(Xapian::Document)
        @xapian_document = doc
        @id = doc.docid
      # Handle initialisation from a hash-like object
      elsif doc.respond_to?(:has_key?) and doc.respond_to?("[]")
        @fields = doc
        @id = doc[:id] if doc.has_key?(:id)
      # Handle initialisation from an object with a to_xapian_fu_string method
      elsif doc.respond_to?(:to_xapian_fu_string)
        @fields = { :content => doc.to_xapian_fu_string }
      # Handle initialisation from anything else that can be coerced
      # into a string
      elsif doc.respond_to? :to_s
        @fields = { :content => doc.to_s }
      else
        raise XapianTypeError, "Can't handle indexing a '#{doc.class}' object"
      end
      @weight = options[:weight] if options[:weight]
      @data = options[:data] if options[:data]
      @db = options[:xapian_db] if options[:xapian_db]
    end

    # The arbitrary data stored in the Xapian database with this
    # document.  Returns an empty string if none available.
    def data
      @data ||= xapian_document.data
    end

    # The XapianFu::XapianDocValueAccessor for accessing the values in
    # this document.
    def values
      @value_accessor ||= XapianDocValueAccessor.new(self)
    end

    # Return a list of terms that the db has for this document.
    def terms
      raise XapianFu::XapianDbNotSet unless db
      db.ro.termlist(id) if db.respond_to?(:ro) and db.ro and id
    end

    # Return a Xapian::Document ready for putting into a Xapian
    # database. Requires that the db attribute has been set up.
    def to_xapian_document
      raise XapianFu::XapianDbNotSet unless db
      xapian_document.data = data
      # Clear and add values
      xapian_document.clear_values
      add_values_to_xapian_document
      # Clear and add terms
      xapian_document.clear_terms
      generate_terms
      xapian_document
    end

    # The Xapian::Document for this XapianFu::Document.  If this
    # document was retrieved from a XapianDb then this will have been
    # initialized by Xapian, otherwise a new Xapian::Document.new is
    # allocated.
    def xapian_document
      @xapian_document ||= Xapian::Document.new
    end

    # Compare IDs with another XapianDoc
    def ==(b)
      if b.is_a?(XapianDoc)
        id == b.id && (db == b.db || db.dir == b.db.dir)
      else
        super(b)
      end
    end

    def inspect
      s = ["<#{self.class.to_s} id=#{id}"]
      s << "weight=%.5f" % weight if weight
      s << "db=#{db.nil? ? 'nil' : db}"
      s.join(' ') + ">"
    end

    # Add this document to the Xapian Database, or replace it if it
    # already has an id.
    def save
      id ? update : create
    end

    # Add this document to the Xapian Database
    def create
      self.id = db.rw.add_document(to_xapian_document)
    end

    # Update this document in the Xapian Database
    def update
      db.rw.replace_document(id, to_xapian_document)
    end

    # Set the stemmer to use for this document.  Accepts any string
    # that the Xapian::Stem class accepts (Either the English name for
    # the language or the two letter ISO639 code). Can also be an
    # existing Xapian::Stem object.
    def stemmer=(s)
      @stemmer = StemFactory.stemmer_for(s)
    end

    # Return the stemmer for this document.  If not set on initialize
    # by the :stemmer or :language option, it will try the database's
    # stemmer and otherwise defaults to an English stemmer.
    def stemmer
      if @stemmer
        @stemmer
      else
        @stemmer =
          if ! @options[:stemmer].nil?
            @options[:stemmer]
          elsif @options[:language]
            @options[:language]
          elsif db
            db.stemmer
          else
            :english
          end
        @stemmer = StemFactory.stemmer_for(@stemmer)
      end
    end

    # Return the stopper for this document.  If not set on initialize
    # by the :stopper or :language option, it will try the database's
    # stopper and otherwise default to an English stopper..
    def stopper
      if @stopper
        @stopper
      else
        @stopper =
          if ! @options[:stopper].nil?
            @options[:stopper]
          elsif @options[:language]
            @options[:language]
          elsif db
            db.stopper
          else
            :english
          end
        @stopper = StopperFactory.stopper_for(@stopper)
      end
    end

    STOPPER_STRATEGIES = {
      :none    => 0,
      :all     => 1,
      :stemmed => 2
    }

    def stopper_strategy
      if @stopper_strategy
        @stopper_strategy
      else
        @stopper_strategy =
          if ! @options[:stopper_strategy].nil?
            @options[:stopper_strategy]
          elsif db
            db.stopper_strategy
          else
            :stemmed
          end
      end
    end

    # Return this document's language which is set on initialize, inherited
    # from the database or defaults to :english
    def language
      if @language
        @language
      else
        @language =
          if ! @options[:language].nil?
            @options[:language]
          elsif db and db.language
            db.language
          else
            :english
          end
      end
    end

    private

    # Array of field names not to run through the TermGenerator
    def unindexed_fields
      db ? db.unindexed_fields : []
    end

    # Array of field names not to index with field names
    def fields_without_field_names
      db ? db.fields_without_field_names : []
    end

    # Array of field names to index with field names only
    def fields_with_field_names_only
      db ? db.fields_with_field_names_only : []
    end

    # Add all the fields to be stored as XapianDb values
    def add_values_to_xapian_document
      db.store_values.collect do |key|
        values[key] = fields[key]
        key
      end
    end

    # Run the Xapian term generator against this documents text
    def generate_terms
      tg = Xapian::TermGenerator.new
      tg.database = db.rw
      tg.document = xapian_document
      tg.stopper = stopper if stopper
      tg.stemmer = stemmer
      tg.set_stopper_strategy(XapianDoc::STOPPER_STRATEGIES.fetch(stopper_strategy, 2))
      flags = 0
      flags |= Xapian::TermGenerator::FLAG_SPELLING if db.spelling
      flags |= Xapian::TermGenerator::FLAG_CJK_NGRAM if db.cjk
      tg.set_flags flags
      index_method = db.index_positions ? :index_text : :index_text_without_positions
      fields.each do |k,o|
        next if unindexed_fields.include?(k)

        if db.fields[k] == Array
          values = Array(o)
        else
          values = [o]
        end

        values.each do |v|
          if v.respond_to?(:to_xapian_fu_string)
            v = v.to_xapian_fu_string
          else
            v = v.to_s
          end

          # get the custom term weight if a weights function exists
          weight = db.weights_function ? db.weights_function.call(k, v, fields).to_i : db.field_weights[k]
          # add value with field name
          tg.send(index_method, v, weight, 'X' + k.to_s.upcase) unless fields_without_field_names.include?(k)
          # add value without field name
          tg.send(index_method, v, weight) unless fields_with_field_names_only.include?(k)

          if db.field_options[k] && db.field_options[k][:exact]
            xapian_document.add_term("X#{k.to_s.upcase}#{v.to_s.downcase}", weight)
          end
        end
      end

      db.boolean_fields.each do |name|
        Array(fields[name]).each do |value|
          xapian_document.add_boolean_term("X#{name.to_s.upcase}#{value.to_s.downcase}")
        end
      end

      # Adding copies of terms without diacritics
      # NOTE: Terms are added without positional information. Also snippet highlight will not work for them.
      if db.process_diacritics
        diacritics = DEFAULT_APPROXIMATIONS.keys.join
        diacritics_terms = xapian_document.terms.select do |t|
          t.term.force_encoding(Encoding::UTF_8).scan(/\b(?=\w*[#{diacritics}])\p{M}*\p{L}*/).any?
        end
        diacritics_terms.each do |t|
          term_name = t.term.force_encoding(Encoding::UTF_8)
          xapian_document.add_term(term_name.gsub(/[#{diacritics}]/u, DEFAULT_APPROXIMATIONS), t.wdf)
        end
      end

      xapian_document
    end

  end


  class StemFactory
    # Return a Xapian::Stem object for the given option. Accepts any
    # string that the Xapian::Stem class accepts (Either the English
    # name for the language or the two letter ISO639 code).
    #
    # If given false or nil, will return a "none" stemmer.
    #
    # It will also accept and return an existing Xapian::Stem object.
    #
    def self.stemmer_for(stemmer)
      if stemmer.is_a? Xapian::Stem
        stemmer
      elsif stemmer.is_a?(String) or stemmer.is_a?(Symbol)
        Xapian::Stem.new(stemmer.to_s)
      else
        Xapian::Stem.new("none")
      end
    end
  end

end
