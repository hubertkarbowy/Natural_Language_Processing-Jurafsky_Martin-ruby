# encoding: utf-8
# Jurafsky and Martin - ex. 4.7

# Author: Hubert Karbowy (hk atsign hubertkarbowy.pl)

# This program calculates the Katz-backoff smoothed probabilities for N-grams
# Note: This is a work in progress (doesn't calculate anything yet)
# Tested with Ruby 2.2.1 - will not work with 1.9.3
require 'pp'

$ngram_model=2

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

corpus = File.read("/wymiana/Projekty/NLP/persuasion.txt").encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '').gsub!(/[^a-z|A-Z|\s]/, "").gsub(/\n/, " ").downcase
=begin
corpus = "SOS buy the book EOS
SOS buy the book EOS
SOS buy the book EOS
SOS buy the book EOS
SOS sell the book EOS
SOS buy the house EOS
SOS buy the house EOS
SOS paint the house EOS"
=end

def calculate_revised_counts next_ngram, local_ngram_model, ngram_counts, good_turing_bins
  next_ngram_rawcount = ngram_counts[local_ngram_model][next_ngram].to_i
  if next_ngram_rawcount == 0
    raise ("Revised count for raw zero counts doesn't make sense")
  else
    return (next_ngram_rawcount+1)*(good_turing_bins[local_ngram_model][next_ngram_rawcount+1].to_f/good_turing_bins[local_ngram_model][next_ngram_rawcount])
  end
end

def calculate p_star word given
end

def katz_backoff next_ngram, ngram_counts, local_ngram_model, good_turing_bins, indent=0
    next_ngram_count = ngram_counts[local_ngram_model].fetch(next_ngram, 0)
    next_ngram_as_arr=next_ngram.split
    prefix = /^#{next_ngram.split[-local_ngram_model..-2].join(" ")}\b/
    backoff_ngram = next_ngram_as_arr[(-local_ngram_model+1)..-1].join(" ") if local_ngram_model>1 # = Wn-N+1...Wn-1, i.e. if next_n_gram was a trigram, we back off to a bigram
    backoff_order_ngram_count = ngram_counts[local_ngram_model-1].fetch(backoff_ngram, 0) if local_ngram_model>1 # part of backoff
    alpha=0.0
    beta=0.0
    
    puts "#{' '*(indent+1)}Calculating P(#{next_ngram.split[-1]}#{local_ngram_model>1 ? ' | ' : ''}#{next_ngram.split[-local_ngram_model..-2].join(" ")}). Raw count = #{next_ngram_count}"
    if (local_ngram_model==1) # end of recursion: we've backed off to unigrams because even bigram were absent from the corpus
        return good_turing_bins[local_ngram_model][next_ngram_count+1].to_f/good_turing_bins[local_ngram_model][0] if next_ngram_count==0
        if good_turing_bins[local_ngram_model][next_ngram_count+1].to_f == 0 
          revised_counts = next_ngram_count
        else
          revised_counts = (ngram_counts[local_ngram_model][next_ngram]+1) * (good_turing_bins[local_ngram_model][next_ngram_count+1].to_f/good_turing_bins[local_ngram_model][next_ngram_count])
        end
        # puts "#{' '*(indent+1)}Output probability = #{next_ngram_gt_probability}" 
        return revised_counts.to_f/good_turing_bins[0][0]    
    elsif local_ngram_model==2
        if backoff_order_ngram_count==0
          alpha=1.0
        else
          revised_counts = calculate_revised_counts(next_ngram, local_ngram_model, ngram_counts, good_turing_bins)
          alpha=revised_counts.to_f/backoff_order_ngram_count
    else
        if backoff_order_ngram_count==0
          alpha=1
          p_katz2
        else
          
        end
        
        
        return alpha*katz_backoff(backoff_ngram, ngram_counts, local_ngram_model-1, good_turing_bins, indent+3)
           
    end
    
    
    
    
    if next_ngram_count > 0
      if good_turing_bins[local_ngram_model][next_ngram_count+1].to_f == 0.0
        revised_counts = next_ngram_count
      else
        revised_counts = (next_ngram_count+1).to_f * (good_turing_bins[local_ngram_model][next_ngram_count+1].to_f/good_turing_bins[local_ngram_model][next_ngram_count])
      end
        prefix = next_ngram.match(prefix).to_s
        prefix_counts = ngram_counts[local_ngram_model-1][prefix]
        puts "OK, no more recursion. N#{next_ngram_count}=#{good_turing_bins[local_ngram_model][next_ngram_count]}, N#{next_ngram_count+1}=#{good_turing_bins[local_ngram_model][next_ngram_count+1]} , Revised counts = #{revised_counts} P* = #{revised_counts.to_f/prefix_counts}, prefix = #{next_ngram.match(prefix).to_s}".red
      return revised_counts.to_f/prefix_counts
    end
    
    
    
    
    next_ngram_revised_count = next_ngram_count==0 ? nil : ((next_ngram_count+1)*(good_turing_bins[local_ngram_model][next_ngram_count+1].to_f))/(good_turing_bins[local_ngram_model][next_ngram_count])
    next_ngram_gt_probability = next_ngram_count==0 ? nil : next_ngram_revised_count / backoff_order_ngram_count
    if !ngram_counts[local_ngram_model][next_ngram].nil?
      puts "#{' '*(indent+1)}#{local_ngram_model.red}-gram probability = #{next_ngram_gt_probability}"
    return next_ngram_gt_probability
    end
    puts "#{' '*(indent+1)}Backing off to #{local_ngram_model-1}-grams with a backoff n-gram #{backoff_ngram.cyan}"
    
    
    prefix_as_str=next_ngram.split[-local_ngram_model..-2].join(" ")
    prefix_counts = ngram_counts[local_ngram_model-1][prefix_as_str].to_i
    puts "#{' '*(indent+1)}Prefix: #{prefix_as_str.brown}, rawcount = #{prefix_counts}"
    if prefix_counts==0
      sum_of_discounted_probabilities=0
    else
      all_similar = ngram_counts[local_ngram_model].keys.select {|k| k.match(prefix)}.map{|k| k.split.last} # e.g. (in her) FORTIES, (in her) HOUSE, (in her) JEANS - returns only the words in parentheses
      sum_of_discounted_probabilities = 0
      all_similar.each do |alt_phrase| 
        similar_ngram = "#{next_ngram.split[-local_ngram_model..-2].join(" ")} #{alt_phrase}" # IN HER FORTIES, IN HER JEANS, IN HER HOUSE...
        similar_ngram_rawcount = ngram_counts[local_ngram_model][similar_ngram]
        similar_ngram_rawcount_revised = (similar_ngram_rawcount+1)*(good_turing_bins[local_ngram_model][similar_ngram_rawcount+1].to_f/good_turing_bins[local_ngram_model][similar_ngram_rawcount])
        p_star = similar_ngram_rawcount_revised/prefix_counts
        sum_of_discounted_probabilities += p_star
        puts "#{' '*(indent+1)}Considering #{similar_ngram.green}, raw count = #{similar_ngram_rawcount}, revised count = #{similar_ngram_rawcount_revised}, P* = #{p_star}"
      end
    end
    puts "#{' '*(indent+1)}beta is = 1-#{sum_of_discounted_probabilities} = #{1-sum_of_discounted_probabilities}"

    beta=1-sum_of_discounted_probabilities
    final_prob = beta*katz_backoff(backoff_ngram, ngram_counts, local_ngram_model-1, good_turing_bins, indent+3)
    return final_prob
end


   ngram_counts = Marshal.load File.read('/wymiana/Projekty/NLP/ngram_counts.txt')

#ngram_counts = Hash.new
for i in 1..3 # this time we include trigrams
#  ngram_counts[i] = Hash.new
#  corpus.each_line do |line|
 #   puts line
  # ngram_counts[i] = corpus.split(" ").each_cons(i).to_a.reduce(Hash.new(0)) {|acc, word| acc[word] += 1; acc }.map{|k,v| [k.join(" "), v]}.to_h
 #   this_hash = Hash.new
#    this_hash = line.split(" ").each_cons(i).to_a.reduce(Hash.new(0)) {|acc, word| acc[word] += 1; acc }.map{|k,v| [k.join(" "), v]}.to_h
  #    puts this_hash 
#    this_hash.each do |k,v|
#    if ngram_counts[i].has_key?(k)
#      puts "yes"
 #     ngram_counts[i][k] += v
 #   else
 #     puts "no"
 #     ngram_counts[i][k] = v
 #  end
 #   end 
 # end
  puts "For #{i}-grams number of types (unique tokens) = #{ngram_counts[i].size}"
end
#    serialized_array = Marshal.dump(ngram_counts)
#    File.open('/wymiana/Projekty/NLP/ngram_counts.txt', 'w') {|f| f.write(serialized_array) }
#
# puts ngram_counts
   good_turing_bins = Marshal.load File.read('/wymiana/Projekty/NLP/good_turing_bins.txt')

#good_turing_bins = []
#good_turing_bins[0] = [corpus.split.count]
#good_turing_bins[0] = [corpus.each_line {|line| line.split.count}.sum]
for i in 1..3 # bins for unigrams, bigrams and trigrams
#  good_turing_bins[i] = []
#  good_turing_bins[i][0]=corpus.split.count # we will keep the corpus size in the zeroeth index
#  (1..ngram_counts[i].values.max).each {|j| good_turing_bins[i][j] = ngram_counts[i].values.reduce(0) {|acc, cnt| cnt==j ? 1+acc : acc} }
end

#    serialized_array = Marshal.dump(good_turing_bins)
#    File.open('/wymiana/Projekty/NLP/good_turing_bins.txt', 'w') {|f| f.write(serialized_array) }

p good_turing_bins[2][5]
# pp ngram_counts[1].select {|x| ngram_counts[x]==1}
#phr="terms"
#puts ngram_counts[1].select {|k,v| k==phr}.to_s.red   # v. easy to get counts and specific ngrams


sentence = "she went home"
probability=1.0
sentence.split.each_cons($ngram_model) do |next_g|
  
  next_ngram = next_g.join(" ")
  next_ngram_count = ngram_counts[$ngram_model].fetch(next_ngram, 0)
  
  puts "Processing #{next_ngram.cyan} with raw count = #{next_ngram_count}"
  probability = probability*katz_backoff(next_ngram, ngram_counts, $ngram_model, good_turing_bins)
  puts "Sentence probability so far: #{probability}\n****"
  
end

# next_ngram = "she was a conceited and proud girl who lived alone"
 
# puts "Next ngram: #{next_ngram}, count: #{next_ngram_count}, revised count: #{next_ngram_revised_count}, GT probability: #{next_ngram_gt_probability}"
