class Corpuses          # the class name is a tribute to a certain dump-corpuses Jenkins job and the ensuing corpuses vs corpora debate

  # The @tokens and @postags hashes fields store the actual data as follows:
  #   key = corpus name
  #   value = a hash containing another hash with the data:
  #           key = text name (since one corpus might consist of several texts)
  #           value = an array containing tokens (in @tokens) and their corresponding part of speech tags (@postags).
  #                   Indices in both arrays should unambiguously point to the same token-pos tag pair, therefore
  #                   both arrays must have equal length or the array in @postags must be zero length if the text is untagged.

  @name                 # Name, e.g. "My corpuses collection"
  @tokens=Hash.new
  @postags=Hash.new
  @info                 # Suppplementary information - reserved for future use

  # source file = path to corpus dir
  # corpus      = :brown
  # subset      = not implemented
  # normalize   = false (no preprocessing), :strip_punctuation, :only_eos (leaves only [?!.] tokens)
  # downcase    = converts everything to lower case if set to true
  # sents       = @tokens and @postags are arrays of arrays of sentence tokens rather than arrays of tokens
  # verbose     = prints messages to stdout
  def initialize(source_dir: nil, corpus: nil, subset: nil, normalize: false, downcase: true, sents: false, verbose: true)
    start_time=Time.now
    @tokens = Hash.new
    @postags = Hash.new
    @info = corpus
    raise ("Unknown corpus") if corpus.nil?

    for singleText in source_dir do
      @tokens[File.basename(singleText)] = Hash.new; @tokens[File.basename(singleText)] = Array.new
      @postags[File.basename(singleText)] = Hash.new; @postags[File.basename(singleText)] = Array.new
    end

    # ## TEMP
    #     @tokens[:brown] = Hash.new; @tokens[:brown]['ca01'] = Array.new
    #     @postags[:brown] = Hash.new; @postags[:brown]['ca01'] = Array.new
    ##

    for singleText in source_dir do
      corpus_file = File.read(singleText).encode('UTF-8', 'UTF-8', invalid: :replace, undef: :replace, replace: '@')
      start_position=0
      counter=0;
      case corpus
        when :brown
          while next_match=corpus_file.match(/(?<token>.+?)\/(?<tag>.+?)(\s|$)/, start_position)
           #while next_match=corpus_file.match(/(?<token>.)/, start_position)
            start_position=$~.end(0)
            normalizer = /['`,()]/ if normalize == :only_eos
            normalizer = /['`,().]/ if normalize == :strip_punctuation
            next if normalize and next_match[:tag].match(normalizer)
            nm = next_match[:token].strip()
            nm.downcase! if downcase
            @tokens[File.basename(singleText)] << nm
            @postags[File.basename(singleText)] << next_match[:tag]
          end
      end
    end
  end

  def getTokens; return @tokens; end
  def getTags; return @postags; end
end

  ########### MAIN
  allfiles = Dir.glob('/wymiana/Projekty/NLP/dumped-corpuses/brown/*').select { |f| FileTest.file? f }
  bc = Corpuses.new(source_dir: allfiles, corpus: :brown, normalize: :only_eos)

  for singleText in bc.getTokens.keys
    puts "Printing " + singleText + "\n****************************************************"
    tokens = bc.getTokens[singleText]
    tags = bc.getTags[singleText]
    for i in 0..tokens.length do
      puts tokens[i].to_s + " " + tags[i].to_s
    end
  end