require 'pp'
require 'set'

class Corpuses # the class name is a tribute to a certain dump-corpuses Jenkins job and the ensuing corpuses vs corpora debate

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
  @verbose = true

  # source file = path to corpus dir
  # corpus      = :brown
  # subset      = not implemented
  # normalize   = false (no preprocessing), :strip_punctuation, :only_eos (leaves only [?!.] tokens)
  # downcase    = converts everything to lower case if set to true
  # sents       = TODO: not implemented. @tokens and @postags are arrays of arrays of sentence tokens rather than arrays of tokens.
  # verbose     = prints messages to stdout
  def initialize(source_dir: nil, corpus: nil, subset: nil, normalize: false, downcase: true, sents: false, verbose: false)
    start_time=Time.now
    @tokens = Hash.new
    @postags = Hash.new
    @conditional_counts = Hash.new # keys = tags, values = hashes whose keys are tokens and values the number of times they occur with the tag in the parent hash
    @tag_counts = Hash.new
    @info = corpus
    @verbose = verbose
    raise ("Unknown corpus") if corpus.nil?

    for singleText in source_dir do
      @tokens[File.basename(singleText)] = Hash.new; @tokens[File.basename(singleText)] = Array.new
      @postags[File.basename(singleText)] = Hash.new; @postags[File.basename(singleText)] = Array.new
    end

    for singleText in source_dir do
      corpus_file = File.read(singleText).encode('UTF-8', 'UTF-8', invalid: :replace, undef: :replace, replace: '@')
      case corpus
        when :brown
          # while next_match=corpus_file.match(/(?<token>.+)\/(?<tag>.+?)( |$)/, start_position)
          corpus_file.split.each { |arg|
            next_match = arg.match(/(?<token>.+)\/(?<tag>.+?)( |$)/) # has to be greedy to account for things like 12-1/2-inch/jj!
            normalizer = /['`,():\-]/ if normalize == :only_eos
            normalizer = /['`,():\-.]/ if normalize == :strip_punctuation
            next if normalize and next_match[:tag].match(normalizer)
            nt = next_match[:tag].gsub(/-tl|-hl|-nc|fw-/, "") # assume titles, headlines, emphasis and foreign words behave regularly
            nm = next_match[:token].strip()
            nm.downcase! if downcase
            setCC(nt, nm); countTags(nt)
            @tokens[File.basename(singleText)] << nm
            @postags[File.basename(singleText)] << nt
          }
        else
          raise "Unknown corpus"
      end
    end
    stop_time = Time.now
    puts "Corpus loaded and trained in #{stop_time - start_time} ms. Type = #{corpus}. # of texts = " + @tokens.size.to_s if verbose
  end

  private def setCC (tag, token)
    if @conditional_counts[tag].nil? then @conditional_counts[tag] = Hash.new; end
    if @conditional_counts[tag][token].nil? then @conditional_counts[tag][token]=1
    else @conditional_counts[tag][token] += 1
    end
  end

  private def countTags(tag)
    if @tag_counts[tag].nil? then @tag_counts[tag]=1
    else @tag_counts[tag] += 1
    end
  end

  # Calculates conditional probability P(word | tag)
  def emission_probability (tag, observation)

    # The two lines below are beautiful usage examples of reduce. Sadly, they are also slow on big corpi such as Brown. We're resorting to precomputed counts.
    #
    # number_of_tags=@postags.keys.reduce(0) {|acc, singleText| acc + @postags[singleText].select{|key| key==tag}.size}
    # occurrences = @tokens.keys.reduce(Array.new) {|acc, singleText| acc << @tokens[singleText].select.with_index {|key, idx| key==observation and @postags[singleText][idx]==tag} }.flatten.size

    number_of_tags = @tag_counts[tag]
    occurrences = @conditional_counts[tag][observation]
    printf "There are " + number_of_tags.to_s + " <" + tag + "> tags. Of those " + occurrences.to_s + " are \"" + observation + "\". " if @verbose
    printf "Emission probability P(" + observation + "|<" + tag + ">) = " + (occurrences.to_f/number_of_tags).to_s + "\n" if @verbose
    return occurrences.to_f/number_of_tags
  end

  # Returns an array of all tags with which the token is annotated in the corpus
  def get_tags_of_token (token)
    ret = Array.new
    @conditional_counts.each_key { |tag| ret.push(tag) if @conditional_counts[tag].has_key?(token) }
    return ret
  end

  def getTokens; return @tokens; end
  def getTags; return @postags; end
  def beQuiet; @verbose=false; end
end

  ########### MAIN
  allfiles = Dir.glob('/wymiana/Projekty/NLP/dumped-corpuses/brown/*').select { |f| FileTest.file? f }
  bc = Corpuses.new(source_dir: allfiles, corpus: :brown, normalize: :only_eos, verbose: true)

  # Uncomment the block below to print all corpus files with tags after normalization and loading into hashtables
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  #
  # for singleText in bc.getTokens.keys
  #   puts "Printing " + singleText + "\n****************************************************"
  #   tokens = bc.getTokens[singleText]
  #   tags = bc.getTags[singleText]
  #   for i in 0..tokens.length do
  #     puts tokens[i].to_s + " " + tags[i].to_s
  #   end
  # end

  # Demo of emission probabilities (cf. results in Figure 5.16 from J&M Ch. 5.5. on HMM POS tagging)
  bc.emission_probability('ppss', 'i')
  bc.emission_probability('vb', 'want')
  bc.emission_probability('nn', 'want')
  bc.emission_probability('to', 'to')
  bc.emission_probability('vb', 'race')
  bc.emission_probability('nn', 'race')

  # Demo of all tags for given tokens:
  puts "All tags for \"race\": " + bc.get_tags_of_token('race').to_s
  puts "All tags for \"want\": " + bc.get_tags_of_token('want').to_s

# alltags = Set.new
# bc.getTags.each_key {|key| bc.getTags[key].each {|tg| alltags.add(tg)} }
# puts "There are " + alltags.size.to_s + " unique tags in the Brown corpus."
# alltags.each {|s| puts s}


