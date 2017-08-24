# encoding: utf-8
##
## RNGTK - Ruby Ngram Toolkit
## Author: Hubert Karbowy (hk atsign hubertkarbowy.pl)
## See my blog on http://www.hubertkarbowy.pl
## Version: 0.96
## Requires Ruby 2.4.0 - won't work with lower versions
##
## For a demonstration run scratchpad.rb
## Please don't take Good-Turing discounted counts, discounted probabilities and Katz-backoff on faith. It is quite likely that is version still contains bugs.
## Comments and suggestions are more than welcome.
##
## CHANGELOG:
## 0.91 - fixed MLE probabilites
## 0.92 - fixed probabilities with Good-Turing discount
## 0.93a - started implementing Katz backoff (incomplete)
## 0.94 - Katz backoff complete + fixes in calculating probabilities
## 0.95 - fixed bad parameter names in calculate_mle_probability, added some documentation
## 0.96 - fixed errorneous zero counts in calculate_revised_probabilities: added .to_f, implemented Knesser-Ney smoothing
## 0.97 - started implementing distribution of leftover GT probability among OOV words (first attempt: just unigrams)
## 0.98 - leftover GT probability distributed evenly among OOV n-grams in all n-gram models
##
##
## TODO: Change verbose to @verbose in all subroutines
## TODO: Add :sentence mode to calculate_gt_probability a la MLE for convenience

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
  @leftover_probability=Hash.new # how much probability mass remains after discounting all unigram counts
  @oov_counts # this hash contains all out-of-vocabulary items with their counts. Set it using @set_oov before performing Good-Turing smoothing

  # corpus            filename 
  # max_ngram model   will generate ngrams up to the value passed here
  # k                 GT smoothing will be applied to ngrams with counts >=1 and <=k. If nil is passed, then it will apply regardless of raw counts.
  # normalize         :by_line - will treat each line as a sentence;   :by_token - will delimit sentences by tokens passed in :eostokens;     :force - will strip all non-alphabetical characters and end-of-line characters
  # strip_punctuation removes non-alphabetical chars
  # ignorecase        downcases everything
  # eostokens         regex containing sentence separators
  # verbose           will print messages to console if set to true. This parameter can be toggled with instance methods be_quiet and be_verbose
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
      k = @ngram_counts[i].values.max if k==nil
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
  
  ## Creates a hash with out-of-vocabulary unigrams and their counts so that the leftover probability can be distributed evenly between all oov items in calculate_gt_probability
  def set_oov testset: nil, max_ngram_model: 3, normalize: :by_line, strip_punctuation: true, ignorecase: true, eostokens: /[?.!]/, separator: " "
    raise "Ngram counts not set" if @ngram_counts.size==0
    
    case normalize
      when :force
        normalized_oov = testset.gsub(/[^a-z|A-Z|\s]/, "").gsub("\n", " ").delete("\r").gsub(/ +/, " ").downcase
      when :by_token
        normalized_oov = testset.split(eostokens).join("\n").gsub(/ +/, " ")
      when :by_line
        normalized_oov = testset
      else
        normalized_oov = testset
    end
    
    normalized_oov.gsub!(/[^a-z|A-Z|\s]/, "") if strip_punctuation
    normalized_oov.gsub!(/ +/, " ") if strip_punctuation
    normalized_oov.downcase! if ignorecase
    
    @oov_counts = Hash.new

    for i in 1..max_ngram_model # unigrams, bigrams etc.
      @oov_counts[i] = Hash.new
      normalized_oov.each_line do |sentence|
          temp_counts = sentence.split(" ").each_cons(i).reduce(Hash.new(0)) {|acc, word| acc[word].nil? ? acc[word]=1 : acc[word] += 1; acc }.map{|k,v| [k.join(" "), v]}.to_h
          temp_counts.each {|token, sentencecounts|
            if !@ngram_counts[i].has_key?(token)
              @oov_counts[i][token].nil? ? @oov_counts[i][token]=sentencecounts : @oov_counts[i][token]+=sentencecounts
            end
          }
        end
      puts "For #{i}-grams number of OOV in testset = #{@oov_counts[i].size}" if @verbose
    end


#    normalized_oov.each_line do |sentence|
 #       temp_counts = sentence.split(" ").each.reduce(Hash.new(0)) {|acc, word|
#          if !@ngram_counts[1].has_key?(word)
#            acc[word].nil? ? acc[word]=1 : acc[word] += 1
#          end
#          acc }
#        temp_counts.each {|token, sentencecounts| @oov_counts[token].nil? ? @oov_counts[token]=sentencecounts : @oov_counts[token]+=sentencecounts}
#    end
    @leftover_probability=Hash.new
    for i in 1..max_ngram_model do
      @leftover_probability[i] = 1 - @ngram_counts[i].reduce(0){|acc, (token, counts)| acc += calculate_gt_probability(next_ngram: token, ngram_model: i, separator: separator)}
      puts "Total number of unknown (oov) #{i}-grams in testset = #{@oov_counts[i].size} with leftover probability of #{@leftover_probability[i]}" if @verbose
    end

end
  
  ## Calculates raw counts (infers n-gram size) TODO: change to named parameters
  def get_raw_counts phrase, ngram_model=0, separator=" "
    ngram_model_inferred = ngram_model==0 ? phrase.split(separator).count : ngram_model
    return @ngram_counts[ngram_model_inferred][phrase]
  end
  
  ## Calculates revised counts using Good-Turing discounting
  def get_revised_counts next_ngram: nil, ngram_model: 0, ngram_counts: @ngram_counts, good_turing_bins: @good_turing_bins, separator: " "
    local_ngram_model = ngram_model==0 ? next_ngram.split(separator).count : ngram_model
    next_ngram_rawcount = ngram_counts[local_ngram_model][next_ngram].to_i
    if next_ngram_rawcount == 0
      raise "Revised counts for zero raw counts (#{next_ngram.green}) only make sense for unigrams with precomputed OOV set." unless !@oov_counts.nil? and local_ngram_model==1
      raise "Token #{next_ngram.red} not found in OOV set. Are you sure you used set_oov?" if !@oov_counts.has_key?(next_ngram)
      leftover_probability_per_oov_token = @leftover_probability/@oov_counts.values.sum
      return @oov_counts[next_ngram].to_f*leftover_probability_per_oov_token 
    elsif @k.nil?
      return (next_ngram_rawcount+1)*(good_turing_bins[local_ngram_model][next_ngram_rawcount+1].to_f/good_turing_bins[local_ngram_model][next_ngram_rawcount])
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

    local_ngram_model=ngram_model==0 ? next_ngram.split(separator).count : ngram_model
    if mode==:single
      rc=get_raw_counts(next_ngram,local_ngram_model)
      return rc.to_f/@good_turing_bins[ngram_model][0] # this is where we keep V
    elsif mode==:sentence
      return next_ngram.split(separator).each_cons(local_ngram_model).reduce(1) {|acc, word| (@ngram_counts[local_ngram_model][word.join(" ")].to_f/@good_turing_bins[local_ngram_model][0].to_f)*acc}
    else
      raise ('MLE: unknown mode [available modes are :single and :sentence]') if (mode != :single and mode != :sentence)
    end
  end
  
  ## Calculates Good-Turing probabilities for n-grams. Very basic version (Regression for Simple Good-Turing is not implemented).
  def calculate_gt_probability next_ngram: nil, ngram_model: 0, ngram_counts: @ngram_counts, good_turing_bins: @good_turing_bins, separator: " "
    local_ngram_model = ngram_model==0 ? next_ngram.split(separator).count : ngram_model
    next_ngram_rawcount = ngram_counts[local_ngram_model][next_ngram].to_i

    if next_ngram_rawcount == 0 # Distributing P*(unseen)
      return good_turing_bins[local_ngram_model][1].to_f/good_turing_bins[local_ngram_model][0] if @oov_counts.nil? # if no oov are set, we assign the whole probability mass to every missing token
      return (@leftover_probability[local_ngram_model]/@oov_counts[local_ngram_model].values.sum)*@oov_counts[local_ngram_model][next_ngram] # otherwise we assign only part of it
    else
      revised_counts = get_revised_counts next_ngram: next_ngram, ngram_model: local_ngram_model
      return revised_counts.to_f/good_turing_bins[local_ngram_model][0]
    end
  end
  
  ## Calculates Knesser-Ney interpolated discounted probabilities (discount is fixed for all ngram models, TODO: implement the modified version)
  def calculate_kn_probability next_ngram: nil, ngram_model: 0, discount: 0.25, ngram_counts: @ngram_counts, good_turing_bins: @good_turing_bins, separator: " "
    local_ngram_model = ngram_model==0 ? next_ngram.split(separator).count : ngram_model
    
    return calculate_mle_probability(next_ngram: next_ngram, separator: separator) if local_ngram_model==1 # Recursion stops at the unigram model

    prefix_regex = /^#{next_ngram.split(separator)[0..-2].join(separator)}\b/
    prefix = next_ngram.split(separator)[0..-2].join(separator)
    suffix = next_ngram.split(separator).last
    similar_ngrams = ngram_counts[local_ngram_model].select{|ngram, _| puts "Found #{prefix.green} #{ngram.split[1..-1].join(" ").brown}" if (@verbose and ngram.match(prefix_regex)); ngram.match(prefix_regex)}.count # Number of words which complete the current n-1 gram, e.g. for the n-gram "your house looks nice" we count "yhl ugly", "yhl fine" etc. Notice - we don't counts the number of occurences for "yhl ugly" etc but only the number of lower-order ngrams which complete the current ngram.
    puts "#{'Total of '.red + similar_ngrams.to_s.red + ' found.'.red} Now calculating counts." if @verbose
    similar_ngrams_total_counts = ngram_counts[local_ngram_model].reduce(0){|acc, (ngram, counts)| puts "Found #{prefix.green} #{ngram.split[1..-1].join(" ").brown} with raw count of #{counts}" if (@verbose and ngram.match?(prefix_regex)); if ngram.match(prefix_regex) then acc += counts; else acc; end} # It's here that we actually sum up the counts
    puts "#{'Total count is '.red + similar_ngrams_total_counts.to_s.red}"
    ngrams_with_fixed_suffix = ngram_counts[local_ngram_model].reduce(0){|acc, (ngram, counts)| puts "Found #{ngram.brown} / #{suffix.green} with raw count of #{counts}" if (@verbose and ngram.match?(/^#{suffix}\b/)); acc += counts if ngram.match?(/^#{suffix}\b/); acc}

    first_term = [get_raw_counts(next_ngram).to_f - discount, 0].max / similar_ngrams_total_counts.to_f
    second_term = discount * (similar_ngrams.to_f/ngrams_with_fixed_suffix.to_f)
    
    return first_term + (second_term * calculate_kn_probability(next_ngram: next_ngram.split(separator)[1..-1].join(separator)))
  end

  def calculate_conditional_probability posterior: nil, prior: nil, ngram_model: 0, ngram_counts: @ngram_counts, good_turing_bins: @good_turing_bins, discounted: false, separator: " "
    local_ngram_model = ngram_model==0 ? prior.split(separator).count + 1 : ngram_model # plus one because of the posterior
    raise "N-gram #{prior}: conditional probabilities for unigrams don't make sense" if local_ngram_model==1
    prior_counts = ngram_counts[local_ngram_model-1][prior].to_i
    raise "#{prior}: Unable to calculate conditional probability for prior counts = 0. Perhaps you meant to use Katz-backoff?" if prior_counts==0
    ngram_raw_counts = ngram_counts[local_ngram_model][prior+separator+posterior].to_f
    
    if discounted
      ngram_discounted_counts = get_revised_counts(next_ngram: prior+separator+posterior, ngram_model: local_ngram_model)
      return ngram_discounted_counts.to_f/prior_counts
    else
      return ngram_raw_counts/prior_counts
    end
  end

  def ccp next_ngram: nil, separator: " ", discounted: false # Convenience method for calculate_conditional probability - splits next_ngram into posterior and prior automatically
    next_ngram_as_arr = next_ngram.split(separator)
    prior = next_ngram_as_arr[0..-2].join(separator)
    posterior = next_ngram_as_arr.last
    return calculate_conditional_probability posterior: posterior, prior: prior, discounted: discounted
  end
  
  def p_cond phrase: nil, separator: " " # Convenience method for printing out strings like "P(word | context words)" if the input phrase is "context words word"
    arr=phrase.split(separator)
    return ("P(#{arr.last} | #{arr[0..-2].join(separator)})")
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
      puts "        * β(#{prefix.green}) = #{beta}" if @verbose
      
      return beta if local_ngram_model==2 # for bigrams
      
      puts "       Now moving on to lower-order n-grams #{backoff_ngram.split(separator)[0..-2].join(" ").brown+' ●'.brown}" if @verbose
      all_similar = ngram_counts[local_ngram_model-1].select {|k,v| k.match(/^#{backoff_ngram.split(separator)[0..-2].join(separator)}\b/)} # .map{|k| k.split.last} # e.g. IN HER FORTIES, IN HER HOUSE, IN HER JEANS
      all_similar.delete_if {|k,v| !ngram_counts[local_ngram_model][prefix+" "+k.split(separator).last].nil? }
      similar_ngram_gt_probabilities = 0
      # revised_count_of_backoff_ngram = get_revised_counts(next_ngram: backoff_ngram, ngram_model: local_ngram_model-1, separator: separator)
      all_similar.each do |alt_phrase, rawcount| 
        similar_ngram = "#{alt_phrase}" # IN HER FORTIES, IN HER JEANS, IN HER HOUSE...
        similar_ngram_gt_probabilities += calculate_conditional_probability(posterior: alt_phrase.split(separator).last, prior: alt_phrase.split(separator)[0..-2].join(separator), discounted: true)
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

  def get_gt_bins; return @good_turing_bins; end
  def get_ngram_counts; return @ngram_counts; end
  def get_oov_counts; return @oov_counts; end
  def clear_oov_counts; @leftover_probability=nil; @oov_counts=nil; end
  def get_leftover_probability; return @leftover_probability; end
  def be_quiet; @verbose=false; end
  def be_verbose; @verbose=true; end
end