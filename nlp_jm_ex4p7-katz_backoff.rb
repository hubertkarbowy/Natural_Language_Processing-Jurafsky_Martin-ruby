# encoding: utf-8
# Jurafsky and Martin - ex. 4.7

# Author: Hubert Karbowy (hk atsign hubertkarbowy.pl)

# This program calculates the Katz-backoff smoothed probabilities for N-grams
# Use the global variables $ngram_model and $k to fine-tune the model.
# Tested with Ruby 2.2.1 - will not work with 1.9.3

$ngram_model=3 # set this to 1 if you want unigrams, 2 for bigrams, 3 for trigrams etc.
$k = 10 # this parameter controls smoothing. Good-Turing probabilities will be calculated for n-grams whose raw counts are less than or equal to k - otherwise MLE probabilities will be used.

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

def calculate_revised_counts next_ngram, local_ngram_model, ngram_counts, good_turing_bins
  next_ngram_rawcount = ngram_counts[local_ngram_model][next_ngram].to_i
  if next_ngram_rawcount == 0
    raise "Revised counts for zero raw counts don't make sense"
  elsif next_ngram_rawcount < $k
    return (next_ngram_rawcount+1)*(good_turing_bins[local_ngram_model][next_ngram_rawcount+1].to_f/good_turing_bins[local_ngram_model][next_ngram_rawcount])
  else
    return (next_ngram_rawcount)
  end
end

def calculate_revised_probabilities next_ngram, local_ngram_model, ngram_counts, good_turing_bins
  next_ngram_rawcount = ngram_counts[local_ngram_model][next_ngram].to_i
  if next_ngram_rawcount == 0
    return good_turing_bins[local_ngram_model][1].to_f/good_turing_bins[local_ngram_model][0]
  else
    revised_counts = next_ngram_rawcount > $k ? next_ngram_rawcount : (next_ngram_rawcount+1)*(good_turing_bins[local_ngram_model][next_ngram_rawcount+1].to_f/good_turing_bins[local_ngram_model][next_ngram_rawcount])
    return revised_counts.to_f/good_turing_bins[local_ngram_model][0] 
  end
end

def calculate_alpha next_ngram, ngram_counts, local_ngram_model, good_turing_bins, indent = 0  # β
  next_ngram_rawcounts = ngram_counts[local_ngram_model][next_ngram].to_i
  raise "(Alpha) Alphas for unigrams don't make sense. There must be an error somewhere." if local_ngram_model==1
  raise "(Alpha) Ngram #{next_ngram} has a raw count > 0. This shouldn't be even called." if next_ngram_rawcounts>0
    next_ngram_as_arr=next_ngram.split
    prefix = next_ngram_as_arr[-local_ngram_model..-2].join(" ")
    puts "#{' '*(indent+1)} Prefix: #{prefix}. Calculating α(#{prefix})"
    
    prefix_rawcounts = ngram_counts[local_ngram_model-1][prefix].to_i
    backoff_ngram = next_ngram_as_arr[(-local_ngram_model+1)..-1].join(" ") # = Wn-N+1...Wn-1, i.e. if next_n_gram was a trigram, we back off to a bigram
    backoff_order_ngram_count = ngram_counts[local_ngram_model-1].fetch(backoff_ngram, 0) # part of backoff

    puts ("#{' '*(indent+1)} c(#{prefix}) = 0, so α(#{prefix}) = 1") if prefix_rawcounts==0 
    return 1 if prefix_rawcounts==0 # because if prefix raw counts are equal to 0, then Pkatz(Wn|wn-N+1) = Pkatz(Wn|wn-N+2..wn-1), i.e. we back off to an even lower n-gram by Eq. (4.42)
  
  if local_ngram_model==2
    sum_of_backoff_counts = calculate_sum_of_backoff_counts(next_ngram, local_ngram_model, ngram_counts, good_turing_bins, 1)
    puts ("#{' '*(indent+1)} c(#{prefix}) = #{prefix_rawcounts}, so α(#{prefix}) = #{1-(sum_of_backoff_counts.to_f)/prefix_rawcounts}")
    return 1-(sum_of_backoff_counts.to_f/prefix_rawcounts)
  else
    beta_sum_of_revised_counts = calculate_sum_of_backoff_counts(next_ngram, local_ngram_model, ngram_counts, good_turing_bins, 1)
    beta = 1 - (beta_sum_of_revised_counts.to_f/prefix_rawcounts)
    puts ("#{' '*(indent+1)} β(#{prefix}) = #{beta}")
    second_prefix = next_ngram_as_arr[(-local_ngram_model+1)..-2].join(" ") # = Wn-N+2...Wn-1
    puts "#{prefix.red} #{second_prefix.cyan}"
    second_prefix_count = ngram_counts[local_ngram_model-2].fetch(second_prefix, 0)
    raise "Second prefix ngram #{second_prefix} has a raw count of 0. There must be an error somewhere..." if second_prefix_count==0
    trimmed_ngram = "#{second_prefix} #{next_ngram_as_arr[-1]}"
    second_prefix_sum_of_revised_counts = calculate_sum_of_backoff_counts trimmed_ngram, local_ngram_model-1, ngram_counts, good_turing_bins, 1
    denominator = 1 - (second_prefix_sum_of_revised_counts.to_f / second_prefix_count)
    puts "#{' '*(indent+1)}β(#{prefix}) = #{beta}, sum of c*(#{second_prefix} ●) = #{second_prefix_sum_of_revised_counts}, c(#{second_prefix}) = #{second_prefix_count}"
    return beta/denominator
  end
end

def calculate_sum_of_backoff_counts next_ngram, local_ngram_model, ngram_counts, good_turing_bins, indent
    raise "Nothing to sum for N=1" if local_ngram_model==1
    next_ngram_as_arr=next_ngram.split
    prefix = /^#{next_ngram.split[-local_ngram_model..-2].join(" ")}\b/

    all_similar = ngram_counts[local_ngram_model].keys.select {|k| k.match(prefix)}.map{|k| k.split.last} # e.g. (in her) FORTIES, (in her) HOUSE, (in her) JEANS - returns only the words in parentheses
    sum_of_backoff_counts = 0
    all_similar.each do |alt_phrase| 
      similar_ngram = "#{next_ngram.split[-local_ngram_model..-2].join(" ")} #{alt_phrase}" # IN HER FORTIES, IN HER JEANS, IN HER HOUSE...
      similar_ngram_rawcount = ngram_counts[local_ngram_model][similar_ngram]
      similar_ngram_revised_count = calculate_revised_counts similar_ngram, local_ngram_model, ngram_counts, good_turing_bins
      sum_of_backoff_counts += similar_ngram_revised_count
      puts "#{' '*(indent+1)}Considering #{similar_ngram.green}, raw count = #{similar_ngram_rawcount}, revised count = #{similar_ngram_revised_count}"
    end
    puts "#{' '*(indent+1)}Sum of revised counts of #{next_ngram.split[-local_ngram_model..-2].join(" ").concat(" ●").green} is #{sum_of_backoff_counts}"
    return sum_of_backoff_counts
end

def katz2 next_ngram, ngram_counts, local_ngram_model, good_turing_bins, indent=0
    next_ngram_as_arr=next_ngram.split
    next_ngram_rawcounts = ngram_counts[local_ngram_model][next_ngram].to_i
    prefix = /^#{next_ngram.split[-local_ngram_model..-2].join(" ")}\b/
    backoff_ngram = next_ngram_as_arr[(-local_ngram_model+1)..-1].join(" ") if local_ngram_model>1 # = Wn-N+1...Wn-1, i.e. if next_n_gram was a trigram, we back off to a bigram
    backoff_order_ngram_count = ngram_counts[local_ngram_model-1].fetch(backoff_ngram, 0) if local_ngram_model>1 # part of backoff
    
    puts "#{' '*(indent+1)}Calculating Pkatz(#{next_ngram.split[-1]}#{local_ngram_model>1 ? ' | ' : ''}#{next_ngram.split[-local_ngram_model..-2].join(" ")}). Raw count = #{next_ngram_rawcounts}"
    
    if local_ngram_model==1 or next_ngram_rawcounts>0
      pkatz = calculate_revised_probabilities next_ngram, local_ngram_model, ngram_counts, good_turing_bins
    else
      alpha = calculate_alpha(next_ngram, ngram_counts, local_ngram_model, good_turing_bins, indent)
      pkatz = alpha * katz2(backoff_ngram, ngram_counts, local_ngram_model-1, good_turing_bins, indent + 3)
    end
    output_string = "#{' '*(indent+1)}Pkatz (#{next_ngram.split[-1]}#{local_ngram_model>1 ? ' | ' : ''}#{next_ngram.split[-local_ngram_model..-2].join(" ")}) = #{pkatz}"
    puts "#{output_string.cyan}"
    return pkatz
end

corpus = File.read("/wymiana/Projekty/NLP/persuasion.txt").encode('UTF-8', 'UTF-8', invalid: :replace, undef: :replace, replace: '').gsub!(/[^a-z|A-Z|\s]/, "").gsub!("\n", " ").delete!("\r").gsub!(/ +/, " ").downcase
# File.open("/wymiana/Projekty/NLP/persuasionsc.txt", "w") {|f| f.write(corpus)}

puts "Corpus size (N) = #{corpus.split.count} words"

# ngram_counts = Marshal.load File.read('/wymiana/Projekty/NLP/ngram_counts.txt')   # Alternatively read the precomputed counts from a file

ngram_counts = Hash.new
for i in 1..$ngram_model # unigrams, bigrams etc.
  ngram_counts[i] = Hash.new
  ngram_counts[i] = corpus.split(" ").each_cons(i).to_a.reduce(Hash.new(0)) {|acc, word| acc[word] += 1; acc }.map{|k,v| [k.join(" "), v]}.to_h
  puts "For #{i}-grams number of types (unique tokens) = #{ngram_counts[i].size}"
end

# serialized_array = Marshal.dump(ngram_counts)
# File.open('/wymiana/Projekty/NLP/ngram_counts.txt', 'w') {|f| f.write(serialized_array) } # Save the counts in a file if a corpus is big to avoid computing counts each time 

# good_turing_bins = Marshal.load File.read('/wymiana/Projekty/NLP/good_turing_bins.txt')   # Alternatively read the precomputed bins from a file
good_turing_bins = []
good_turing_bins[0] = [corpus.split.count]
good_turing_bins[0] = [corpus.each_line {|line| line.split.count}.sum]
for i in 1..$ngram_model # bins for unigrams, bigrams etc.
  good_turing_bins[i] = []
  good_turing_bins[i][0]=corpus.split.count - i + 1 # we will keep the number of ngrams in the zeroeth index and denote is as N0. The formula for a given ngram model is: number of tokens in the corpus - (number of ngrams + 1)
  # (1..ngram_counts[i].values.max).each {|j| good_turing_bins[i][j] = ngram_counts[i].values.reduce(0) {|acc, cnt| cnt==j ? 1+acc : acc} }
  (1..$k+1).each {|j| good_turing_bins[i][j] = ngram_counts[i].values.reduce(0) {|acc, cnt| cnt==j ? 1+acc : acc} }
end

# serialized_array = Marshal.dump(good_turing_bins)
# File.open('/wymiana/Projekty/NLP/good_turing_bins.txt', 'w') {|f| f.write(serialized_array) } # Save the bins in a file if the corpus is big to avoid lengthy computations each time

for i in 1..$ngram_model
  puts "Good-Turing bins for #{i}-grams:"
  for j in 0..$k-1
    puts "N#{j} = #{good_turing_bins[i][j]}"
  end 
end

sentence = "she lived in a house with a view on the lake"
probability=1.0
logprobability=0
sentence.split.each_cons($ngram_model) do |next_g|
  next_ngram = next_g.join(" ")
  next_ngram_count = ngram_counts[$ngram_model].fetch(next_ngram, 0)
  
  puts "Processing #{next_ngram.cyan} with raw count = #{next_ngram_count}"
  pkatz = katz2(next_ngram, ngram_counts, $ngram_model, good_turing_bins)
  probability = probability*pkatz
  logprobability = logprobability + (-Math.log(pkatz))
  puts "Sentence probability so far: #{probability}, log probability so far: #{logprobability}\n****"
end
