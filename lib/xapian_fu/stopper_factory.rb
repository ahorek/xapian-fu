module XapianFu
  class StopperFactory
    @stoppers = { }

    # Return a SimpleStopper loaded with stop words for the given language
    def self.stopper_for(lang)
      case lang
      when Xapian::Stopper
        lang
      when false
        false
      else
        lang = lang.to_s.downcase.strip
        if @stoppers[lang]
          @stoppers[lang]
        else
          stopper = Xapian::SimpleStopper.new
          stop_words_for(lang).each { |word| stopper.add(word) }
          @stoppers[lang] = stopper
        end
      end
    end

    # Return the full path to the stop words file for the given language
    def self.stop_words_filename(lang)
      File.join(File.dirname(__FILE__), 'stopwords', lang.to_s.downcase + '.txt')
    end

    # Read and parse the stop words file for the given language, returning an array of words
    def self.stop_words_for(lang)
      return [] unless File.exists?(stop_words_filename(lang))

      words = []
      # Open files with correct encoding
      open_args = [stop_words_filename(lang), "r:UTF-8"]
      open(*open_args) do |f|
        while line = f.readline rescue nil
          words << line.split(" ", 2).first.downcase.strip  unless line =~ /^ +|^$|^\|/
        end
      end
      words
    end
  end
end
