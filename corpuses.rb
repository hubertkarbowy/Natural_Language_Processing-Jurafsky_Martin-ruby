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

  def initialize(source_file: nil, corpus: nil, subset: nil, normalize: true, verbose: true)
    start_time=Time.now

    ## TEMP
        @tokens = Hash.new; @tokens[:brown] = Hash.new; @tokens[:brown]['ca01'] = Array.new
        @postags = Hash.new; @postags[:brown] = Hash.new; @postags[:brown]['ca01'] = Array.new
    ##

    corpus_file = File.read(source_file).encode('UTF-8', 'UTF-8', invalid: :replace, undef: :replace, replace: '@')
    start_position=0
    counter=0;
    case corpus
      when :brown
        while next_match=corpus_file.match(/(?<token>.+?)\/(?<tag>.+?)(\s|$)/, start_position)
         #while next_match=corpus_file.match(/(?<token>.)/, start_position)
          @tokens[:brown]['ca01'] << next_match[:token]
          @postags[:brown]['ca01'] << next_match[:tag]
          start_position=$~.end(0)
        end
    end
  end

  def getTokens; return @tokens; end
  def getTags; return @postags; end
end

  ########### MAIN

  bc = Corpuses.new(source_file: '/wymiana/Projekty/NLP/dumped-corpuses/brown/ca01', corpus: :brown)
  tk= bc.getTokens[:brown]['ca01']
  tt= bc.getTags[:brown]['ca01']

  for i in 0..tk.length do
    puts tk[i].to_s + " " + tt[i].to_s
  end