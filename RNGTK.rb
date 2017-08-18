# encoding: utf-8
##
## RNGTK - Ruby Ngram Toolkit
## Author: Hubert Karbowy (hk atsign hubertkarbowy.pl)
## See my blog on http://www.hubertkarbowy.pl
## Version: 0.93a
## Requires Ruby 2.4.0 - might work with 2.3 and 2.2, won't work with lower versions
##
## For a demonstration run scratchpad.rb
## Please don't take Good-Turing discounted counts and discounted probabilities on faith. It is quite likely that is version still contains bugs.
##
## CHANGELOG:
## 0.91 - fixed MLE probabilites
## 0.92 - fixed probabilities with Good-Turing discount
## 0.93a - started implementing Katz backoff (incomplete)
## 0.94 - Katz backoff complete + fixes in calculating probabilities

# class to color output in verbose mode
class String
    def black;          "\e[30m#{self}\e[0m" end
    def red;            "\e[31m#{self}\e[0m" end
    def green;          "\e[32m#{self}\e[0m" end
    def brown;          "\e[33m#{self}\e[0m" end
    def blue;           "\e[34m#{self}\e[0m" end
    def magenta;        "\e[35m#{self}\e[0m" end
    def cyan;           "\e[36m#{self}\e[0m" end
    def gray;           "\e[37m#{self}\e[0m" end
  end

class Ngrams
  @k
  @ngram_counts
  @good_turing_bins
  @verbose=false

  # corpus - filename, max_ngram model - self-explanatory, k - for GT smoothing
  # strip_punctuation - removes non-alphabetical chars
  # ignorecase - downcases everything
  def initialize(corpus: nil, max_ngram_model: 3, k: 5, normalize: :by_line, strip_punctuation: true, ignorecase: true, eostokens: /[?.!]/, verbose: true)
    start_time=Time.now

    corpus_file = File.read(corpus).encode('UTF-8', 'UTF-8', invalid: :replace, undef: :replace, replace: '@')
    corpus_file = corpus_file.gsub("\n", " ").delete("\r").gsub(/ +/, " ") unless normalize == :by_line

    case normalize
      when :force
        normalized_corpus = corpus_file.gsub(/[^a-z|A-Z|\s]/, "").gsub("\n", " ").delete("\r").gsub(/ +/, " ").downcase
      when :by_token
        normalized_corpus = corpus_file.split(eostokens).join("\n").gsub(/ +/, " ")
      when :by_line
        normalized_corpus = corpus_file
      else
        normalized_corpus = corpus_file
    end

    normalized_corpus.gsub!(/[^a-z|A-Z|\s]/, "") if strip_punctuation
    normalized_corpus.gsub!(/ +/, " ") if strip_punctuation
    normalized_corpus.downcase! if ignorecase
    
    # N-grams
    @ngram_counts = Hash.new
    for i in 1..max_ngram_model # unigrams, bigrams etc.
      @ngram_counts[i] = Hash.new
      normalized_corpus.each_line do |sentence|
        temp_counts = sentence.split(" ").each_cons(i).reduce(Hash.new(0)) {|acc, word| acc[word].nil? ? acc[word]=1 : acc[word] += 1; acc }.map{|k,v| [k.join(" "), v]}.to_h
        temp_counts.each {|token, sentencecounts| @ngram_counts[i][token].nil? ? @ngram_counts[i][token]=sentencecounts : @ngram_counts[i][token]+=sentencecounts}
      end
      puts "For #{i}-grams number of types (unique tokens) = #{@ngram_counts[i].size}" if verbose
    end

    #Good-Turing bins (N1, N2 etc.)
    gt_bins = []
    gt_bins[0] = [@ngram_counts[1].values.sum]
    for i in 1..max_ngram_model # bins for unigrams, bigrams etc.
      gt_bins[i] = []
      gt_bins[i][0]=@ngram_counts[i].values.sum # we will keep the number of ngrams in the zeroeth index and denote is as N0.
      (1..k+1).each {|j| gt_bins[i][j] = @ngram_counts[i].select {|_, counts| counts==j}.values.size}
    end

    if verbose
      for i in 1..max_ngram_model
        puts "Good-Turing bins for #{i}-grams:"
        for j in 0..k+1
          puts "N#{j} = #{gt_bins[i][j]}"
        end
      end
    end

    @good_turing_bins=gt_bins
    @k=k
    @verbose=verbose
    stop_time=Time.now
    puts "RNGTK ready. Model loaded model in #{stop_time-start_time} s." if verbose
  end
  
  ## Calculates back-off counts with Good-Turing discount
  def get_revised_counts next_ngram: nil, ngram_model: 0, ngram_counts: @ngram_counts, good_turing_bins: @good_turing_bins, separator: " "
    local_ngram_model = ngram_model==0 ? next_ngram.split(separator).count : ngram_model
    next_ngram_rawcount = ngram_counts[local_ngram_model][next_ngram].to_i
    if next_ngram_rawcount == 0
      raise "Revised counts for zero raw counts don't make sense #{next_ngram}"
    elsif next_ngram_rawcount <= @k
      ordinary_gt = (next_ngram_rawcount+1)*(good_turing_bins[local_ngram_model][next_ngram_rawcount+1].to_f/good_turing_bins[local_ngram_model][next_ngram_rawcount])
      mle_provision = (next_ngram_rawcount*(@k+1)*good_turing_bins[local_ngram_model][@k+1].to_f)/good_turing_bins[local_ngram_model][1]
      normalization = 1 - ((@k+1)*good_turing_bins[local_ngram_model][@k+1].to_f)/good_turing_bins[local_ngram_model][1]
      warn "Good-Turing discounting with a parameter is numerically unstable. Negative revised counts were detected for #{next_ngram}." if (@verbose and ((ordinary_gt-mle_provision)/normalization)<0)
      return (ordinary_gt-mle_provision)/normalization # This is equation 4.31 from JM
    else
      return (next_ngram_rawcount)
    end
  end

  ## Calculates Maximum Likelihood Estimate for n-grams
  ## This method guesses the ngram model if not explicitly provided. It works in two modes:
  ## When mode is set to :single (default) - the phrase is assumed to be an n-gram already (n is inferred from separator)
  ## When mode is set to :sentence - the phrase is split into n-grams and their MLEs are multiplied.
  ## Todo: Consider removing mode parameter - it might interfere with external calls
  def calculate_mle_probability next_ngram: nil, ngram_model: 0, separator: " ", mode: :single
    raise ('MLE: ngram_model must be set explicitly in sentence mode') if (ngram_model==0 and mode == :sentence)

    local_ngram_model=ngram_model==0 ? phrase.split(separator).count : ngram_model
    if mode==:single
      rc=get_raw_counts(phrase,local_ngram_model)
      return rc.to_f/@good_turing_bins[ngram_model][0] # this is where we keep V
    elsif mode==:sentence
      return phrase.split(separator).each_cons(local_ngram_model).reduce(1) {|acc, word| (@ngram_counts[local_ngram_model][word.join(" ")].to_f/@good_turing_bins[local_ngram_model][0].to_f)*acc}
    else
      raise ('MLE: unknown mode [available modes are :single and :sentence]') if (mode != :single and mode != :sentence)
    end
  end
  
  ## Calculates Good-Turing probabilities for n-grams
  def calculate_gt_probability next_ngram: nil, ngram_model: 0, ngram_counts: @ngram_counts, good_turing_bins: @good_turing_bins, separator: " "
    local_ngram_model = ngram_model==0 ? next_ngram.split(separator).count : ngram_model
    next_ngram_rawcount = ngram_counts[local_ngram_model][next_ngram].to_i

    if next_ngram_rawcount == 0
      return good_turing_bins[local_ngram_model][1].to_f/good_turing_bins[local_ngram_model][0]
    else
      revised_counts = get_revised_counts next_ngram: next_ngram, ngram_model: local_ngram_model
      return revised_counts.to_f/good_turing_bins[local_ngram_model][0]
    end
  end

  def calculate_conditional_probability posterior: nil, prior: nil, ngram_model: 0, ngram_counts: @ngram_counts, good_turing_bins: @good_turing_bins, discounted: false, separator: " "
    local_ngram_model = ngram_model==0 ? prior.split(separator).count + 1 : ngram_model # plus one because of the posterior
    raise "N-gram #{prior}: conditional probabilities for unigrams don't make sense" if local_ngram_model==1
    prior_counts = ngram_counts[local_ngram_model-1][prior].to_i
    raise "#{prior}: Unable to calculate conditional probability for prior counts = 0. Perhaps you meant to use Katz-backoff?" if prior_counts==0
    ngram_raw_counts = ngram_counts[local_ngram_model][prior+separator+posterior].to_f
    
    if discounted and ngram_raw_counts<=@k
      ngram_discounted_counts = get_revised_counts(next_ngram: prior+separator+posterior, ngram_model: local_ngram_model)
      return ngram_discounted_counts/prior_counts
    else
      return ngram_raw_counts/prior_counts
    end
  end
  
  def calculate_alpha next_ngram: nil, ngram_model:0, ngram_counts: @ngram_counts, good_turing_bins: @good_turing_bins, separator: " "
      local_ngram_model = ngram_model==0 ? next_ngram.split(separator).count : ngram_model
      backoff_ngram = next_ngram.split(separator)[1..-1].join(separator) # e.g. "Your house looks ugly" ---> "house looks ugly"
      prefix_regex = /^#{next_ngram.split(separator)[0..-2].join(separator)}\b/
      prefix = next_ngram.split(separator)[0..-2].join(separator)
      puts "  Prefix: #{prefix}. Calculating α(#{prefix})" if @verbose

      return 1 if ngram_counts[local_ngram_model-1][prefix].to_i==0
      
      raise "Nothing to sum for N=1" if local_ngram_model==1
      puts "      Calculating β(#{prefix.to_s})" if @verbose
      beta_sum_of_probabilities = 0
      all_cond_ngrams = ngram_counts[local_ngram_model].keys.select {|k| k.match(prefix_regex)}.map{|k| k.split(separator).last} # e.g. (in her) FORTIES, (in her) HOUSE, (in her) JEANS - returns only the words in parentheses      
      all_cond_ngrams.each do |last_word|
          cond_ngram = prefix + separator + last_word
          printf "       > Considering #{p_cond(phrase: cond_ngram).green}" if @verbose
          last_word_cond_probability = calculate_conditional_probability(posterior: last_word, prior: prefix, discounted: true)
          beta_sum_of_probabilities += last_word_cond_probability
          printf " = #{last_word_cond_probability}\n" if @verbose
      end

      beta = 1 - beta_sum_of_probabilities
      puts "        * Sum of revised probabilities #{p_cond(phrase: prefix+' ●').green}: " if @verbose
      puts "        * β(#{prefix.green}) = #{beta}"
      
      return beta if local_ngram_model==2 # for bigrams
      
      puts "       Now moving on to lower-order n-grams #{backoff_ngram.split(separator)[0..-2].join(" ").brown+' ●'.brown}" if @verbose
      all_similar = ngram_counts[local_ngram_model-1].select {|k,v| k.match(/^#{backoff_ngram.split(separator)[0..-2].join(separator)}\b/)} # .map{|k| k.split.last} # e.g. IN HER FORTIES, IN HER HOUSE, IN HER JEANS
      all_similar.delete_if {|k,v| !ngram_counts[local_ngram_model][prefix+" "+k.split(separator).last].nil? }
      sum_of_backoff_counts = 0
      similar_ngram_gt_probabilities = 0
      # revised_count_of_backoff_ngram = get_revised_counts(next_ngram: backoff_ngram, ngram_model: local_ngram_model-1, separator: separator)
      all_similar.each do |alt_phrase, rawcount| 
        similar_ngram = "#{alt_phrase}" # IN HER FORTIES, IN HER JEANS, IN HER HOUSE...
        similar_ngram_gt_probabilities += calculate_conditional_probability(posterior: alt_phrase.split(separator).last, prior: alt_phrase.split(separator)[0..-2].join(separator), discounted: true) 
        #similar_ngram_rawcount += rawcount
        similar_ngram_revised_count = get_revised_counts(next_ngram: similar_ngram)
        # sum_of_backoff_counts += similar_ngram_revised_count
        puts "       Considering #{p_cond(phrase: alt_phrase).brown}, P* = #{calculate_conditional_probability(posterior: alt_phrase.split(separator).last, prior: alt_phrase.split(separator)[0..-2].join(separator), discounted: true)}" if @verbose
      end
      puts "         * Sum of revised probabilities #{p_cond(phrase: backoff_ngram.split(separator)[0..-2].join(" ")+' ●').brown} is #{similar_ngram_gt_probabilities}" if @verbose
      puts "         * α = #{beta/1-similar_ngram_gt_probabilities}" if @verbose
      return beta / (1-similar_ngram_gt_probabilities)
  end

  def calculate_katz_probability next_ngram: nil, ngram_model:0, ngram_counts: @ngram_counts, good_turing_bins: @good_turing_bins, separator: " "
    local_ngram_model = ngram_model==0 ? next_ngram.split(separator).count : ngram_model
    next_ngram_rawcount = ngram_counts[local_ngram_model][next_ngram].to_i

    return calculate_gt_probability(next_ngram: next_ngram, ngram_model: 1) if local_ngram_model==1

    if next_ngram_rawcount>0
      prior = next_ngram.split(separator)[0..-2].join(separator)
      posterior = next_ngram.split(separator)[-1]
      return calculate_conditional_probability(posterior: posterior, prior: prior, ngram_model: local_ngram_model, discounted: true, separator: separator)
    else
      backoff_ngram=next_ngram.split(separator)[1..-1].join(separator)
      prior = next_ngram.split(separator)[1..-2].join(separator)
      posterior = next_ngram.split(separator)[-1]
      alpha = calculate_alpha(next_ngram: next_ngram, ngram_model: local_ngram_model)
      puts "          BACKING OFF TO: #{backoff_ngram}\n\n" if @verbose 
      return alpha*calculate_katz_probability(next_ngram: backoff_ngram, ngram_model: local_ngram_model-1, separator: separator)
    end

  end

  ## Calculates raw counts (infers n-gram size)
  def get_raw_counts phrase, ngram_model=0, separator=" "
    ngram_model_inferred = ngram_model==0 ? phrase.split(separator).count : ngram_model
    return @ngram_counts[ngram_model_inferred][phrase]
  end
  
  def p_cond phrase: nil
    arr=phrase.split
    return ("P(#{arr.last} | #{arr[0..-2].join(" ")})")
  end

  def get_gt_bins; return @good_turing_bins; end
  def get_ngram_counts; return @ngram_counts; end
  def be_quiet; @verbose=false; end
  def be_verbose; @verbose=true; end
end