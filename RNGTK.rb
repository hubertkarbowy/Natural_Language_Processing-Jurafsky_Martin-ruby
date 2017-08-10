# encoding: utf-8
##
## RNGTK - Ruby Ngram Toolkit
## Author: Hubert Karbowy (hk atsign hubertkarbowy.pl)
## Version: 0.9
##
## Todo: Implement Katz back-off
##       Named parameters
##
## See my blog on http://www.hubertkarbowy.pl
##

class Ngrams
  @k
  @ngram_counts
  @good_turing_bins
  
  def initialize(corpus, max_ngram_model: 3, k: 5, force_normalize: true, verbose: true)
    start_time=Time.now
    # corpus_file = File.read(corpus).encode('UTF-8', 'UTF-8', invalid: :replace, undef: :replace, replace: '')
    corpus_file = File.read(corpus).encode('UTF-8', 'UTF-8', invalid: :replace, replace: '')
    normalized_corpus = force_normalize==true ? corpus_file.gsub(/[^a-z|A-Z|\s]/, "").gsub("\n", " ").delete("\r").gsub(/ +/, " ").downcase : corpus_file
    
    # N-grams
    @ngram_counts = Hash.new
    for i in 1..max_ngram_model # unigrams, bigrams etc.
      @ngram_counts[i] = Hash.new
      @ngram_counts[i] = normalized_corpus.split(" ").each_cons(i).reduce(Hash.new(0)) {|acc, word| acc[word] += 1; acc }.map{|k,v| [k.join(" "), v]}.to_h
      puts "For #{i}-grams number of types (unique tokens) = #{@ngram_counts[i].size}" unless !verbose
    end
    
    #Good-Turing bins (N1, N2 etc.)
    gt_bins = []
    gt_bins[0] = [normalized_corpus.split.count]
    gt_bins[0] = [normalized_corpus.each_line {|line| line.split.count}.sum]
    for i in 1..max_ngram_model # bins for unigrams, bigrams etc.
      gt_bins[i] = []
      gt_bins[i][0]=normalized_corpus.split.count - i + 1 # we will keep the number of ngrams in the zeroeth index and denote is as N0. The formula for a given ngram model is: number of tokens in the corpus - (number of ngrams + 1)
      (1..k+1).each {|j| gt_bins[i][j] = @ngram_counts[i].values.reduce(0) {|acc, cnt| cnt==j ? 1+acc : acc} }
    end
    
    unless !verbose
        for i in 1..max_ngram_model
        puts "Good-Turing bins for #{i}-grams:"
        for j in 0..k-1 
          puts "N#{j} = #{gt_bins[i][j]}"
        end 
      end
    end

    @good_turing_bins=gt_bins
    @k=k
    stop_time=Time.now
    puts "RNGTK ready. Model loaded model in #{stop_time-start_time} s." unless !verbose
  end
  
  ## Calculates back-off counts with Good-Turing discount. Todo: infer model
  def get_revised_counts next_ngram:, ngram_model: 0, ngram_counts: @ngram_counts, good_turing_bins: @good_turing_bins, separator: " "
    local_ngram_model = ngram_model==0 ? next_ngram.split(separator).count : ngram_model
    next_ngram_rawcount = ngram_counts[local_ngram_model][next_ngram].to_i
    if next_ngram_rawcount == 0
      raise "Revised counts for zero raw counts don't make sense"
    elsif next_ngram_rawcount < @k
      return (next_ngram_rawcount+1)*(good_turing_bins[local_ngram_model][next_ngram_rawcount+1].to_f/good_turing_bins[local_ngram_model][next_ngram_rawcount])
    else
      return (next_ngram_rawcount)
    end
  end
  
  ## Calculates Good-Turing probabilities for n-grams # Todo: Guess ngram model
  def calculate_gt_probability next_ngram:, ngram_model: 0, ngram_counts: @ngram_counts, good_turing_bins: @good_turing_bins, separator: " "
    local_ngram_model = ngram_model==0 ? next_ngram.split(separator).count : ngram_model
    next_ngram_rawcount = ngram_counts[local_ngram_model][next_ngram].to_i
    
    if next_ngram_rawcount == 0
      return good_turing_bins[local_ngram_model][1].to_f/good_turing_bins[local_ngram_model][0]
    else
      revised_counts = next_ngram_rawcount > @k ? next_ngram_rawcount : (next_ngram_rawcount+1)*(good_turing_bins[local_ngram_model][next_ngram_rawcount+1].to_f/good_turing_bins[local_ngram_model][next_ngram_rawcount])
      return revised_counts.to_f/good_turing_bins[local_ngram_model][0] 
    end
  end
  
  ## Calculates Maximum Likelihood Estimate for n-grams
  def calculate_mle_probabilitity phrase, ngram_model
    rc=get_raw_counts(phrase, ngram_model)
    return rc.to_f/@good_turing_bins[ngram_model][0] # this is where we keep V
  end
  
  ## This overloaded method guesses the ngram model by the number of spaces # Todo: separator
  def calculate_mle_probabilitity phrase
    ngram_model=phrase.split(" ").count
    return phrase.split(" ").each_cons(ngram_model).reduce(1) {|acc, word| (@ngram_counts[ngram_model][word.join(" ")].to_f/@good_turing_bins[ngram_model][0].to_f)*acc}
  end
  
  ## Calculates raw counts (infers n-gram size)
  def get_raw_counts phrase, ngram_model=0, separator=" "
    ngram_model_inferred = ngram_model==0 ? phrase.split(separator).count : ngram_model
    return @ngram_counts[ngram_model_inferred][phrase]
  end

  def get_gt_bins; return @good_turing_bins; end;
  
end