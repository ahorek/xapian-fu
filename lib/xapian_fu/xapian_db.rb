module XapianFu
  class XapianFuError < StandardError ; end

  require 'xapian'
  require 'xapian_doc'
  require 'thread'

  class ConcurrencyError < XapianFuError ; end
  class DocNotFound < XapianFuError ; end

  class XapianDb
    attr_reader :dir, :db_flag, :query_parser
    attr_reader :store_fields, :store_values

    def initialize( options = { } )
      @dir = options[:dir]
      @db_flag = Xapian::DB_OPEN
      @db_flag = Xapian::DB_CREATE_OR_OPEN if options[:create]
      @db_flag = Xapian::DB_CREATE_OR_OVERWRITE if options[:overwrite]
      @store_fields = Array.new(1, options[:store]).compact
      @store_values = Array.new(1, options[:sortable]).compact
      @store_values += Array.new(1, options[:collapsible]).compact
      rw.flush if options[:create]
      @tx_mutex = Mutex.new
    end

    # Return the writable Xapian database
    def rw
      @rw ||= setup_rw_db
    end

    # Return the read-only Xapian database
    def ro
      @ro ||= setup_ro_db
    end

    # Return the number of docs in the Xapian database
    def size
      ro.doccount
    end

    # Return the XapianDocumentsAccessor for this database
    def documents
      @documents_accessor ||= XapianDocumentsAccessor.new(self)
    end

    # Add a document to the index. A document can be just a hash, the
    # keys representing field names and their values the data to be
    # indexed.  Or it can be a XapianDoc, or any object with a to_s method.
    # 
    # If the document object reponds to the method :data, whatever it
    # returns is marshalled and stored in the  Xapian database.  Any
    # arbitrary data up to Xmeg can be stored here.
    #
    # Currently, all fields are stored in the database. This will
    # change to store only those fields requested to be stored.
    def add_doc(doc)
      doc = XapianDoc.new(doc) unless doc.is_a? XapianDoc
      doc.db = self
      xdoc = doc.to_xapian_document
      tg = Xapian::TermGenerator.new
      tg.database = rw
      tg.document = xdoc
      tg.index_text( doc.text )
      if doc.id
        rw.replace_document(doc.id, xdoc)
      else
        doc.id = rw.add_document(xdoc)
      end
      doc
    end
    alias_method "<<", :add_doc

    # Conduct a search on the Xapian database, returning an array of 
    # XapianDoc objects for the matches
    def search(q, options = {})
      defaults = { :page => 1, :per_page => 10, :reverse => false }
      options = defaults.merge(options)
      page = options[:page].to_i rescue 1
      page = page > 1 ? page - 1 : 0
      per_page = options[:per_page].to_i rescue 10
      offset = page * per_page
      query = query_parser.parse_query(q, Xapian::QueryParser::FLAG_WILDCARD && Xapian::QueryParser::FLAG_LOVEHATE)
      if options[:order]
        enquiry.sort_by_value!(options[:order].to_s.hash, options[:reverse])
      end
      if options[:collapse]
        enquiry.collapse_key = options[:collapse].to_s.hash
      end
      enquiry.query = query
      enquiry.mset(offset, per_page).matches.collect { |m| XapianDoc.new(m) }
    end

    # Run the given block in a XapianDB transaction.  Any changes to the 
    # Xapian database made in the block will be atomically committed at the end.
    # 
    # If an exception is raised by the block, all changes are discarded and the
    # exception re-raised.
    # 
    # Xapian does not support multiple concurrent transactions on the
    # same Xapian database. Any attempts at this will be serialized by
    # XapianFu, which is not perfect but probably better than just
    # kicking up an exception.
    #
    def transaction
      @tx_mutex.synchronize do
        rw.begin_transaction
        yield
        rw.commit_transaction
      end
    rescue Exception => e
      rw.cancel_transaction
      raise e
    end

    # Flush any changes to disk and reopen the read-only database.
    # Raises ConcurrencyError if a transaction is in process
    def flush
      raise ConcurrencyError if @tx_mutex.locked?
      rw.flush
      ro.reopen
    end

    def query_parser
      unless @query_parser
        @query_parser = Xapian::QueryParser.new
        @query_parser.database = ro
      end
      @query_parser
    end 

    def enquiry
      @enquiry ||= Xapian::Enquire.new(ro)
    end

    private

    def setup_rw_db
      if dir
        @rw = Xapian::WritableDatabase.new(dir, db_flag)
      else
        # In memory database
        @rw = Xapian::inmemory_open
      end
    end

    def setup_ro_db
      if dir
        @ro = Xapian::Database.new(dir)
      else
        # In memory db
        @ro = rw
      end
    end

    #
    class XapianDocumentsAccessor
      def initialize(xdb)
        @xdb = xdb
      end

      # Return the document with the given id from the
      # database. Raises a XapianFu::DocNotFoundError exception 
      # if it doesn't exist.
      def find(doc_id)
        xdoc = @xdb.ro.document(doc_id)
        XapianDoc.new(xdoc)
      rescue RuntimeError => e
        raise e.to_s =~ /^DocNotFoundError/ ? XapianFu::DocNotFound : e
      end

      # Return the document with the given id from the database or nil
      # if it doesn't exist
      def [](doc_id)
        find(doc_id)
      rescue XapianFu::DocNotFound
        nil
      end

      # Delete the given document from the database and return the
      # document id, or nil if it doesn't exist
      def delete(doc)
        if doc.respond_to?(:to_i)
          @xdb.rw.delete_document(doc.to_i)
          doc.to_i
        end
      rescue RuntimeError => e
        raise e unless e.to_s =~ /^DocNotFoundError/
      end
    end
  end

end
