# Jurafsky and Martin - ex. 4.6

# Author: Hubert Karbowy (hk atsign hubertkarbowy.pl)

# This program calculates the Good-Turing smoothed probabilities for N-grams.
# Tested with Ruby 2.2.1 - will not work with 1.9.3
require 'pp'

#corpus = "starttoken en sag sag en sag en sag sag comma en annan sagade sagen sagen sag dot enddtoken" # taken from https://sites.google.com/site/gothnlp/exercises/jurafsky-martin/solutions
corpus = "carp carp carp carp carp carp carp carp carp carp perch perch perch whitefish whitefish trout salmon eel" # taken from The Book
#corpus = "apple apple apple banana banana dates dates eggs eggs eggs frogs grapes grapes" # taken from https://www.cs.cornell.edu/courses/cs6740/2010sp/guides/lec11.pdf
corpus = corpus.gsub(/[^a-z|A-Z|\s]/, "").gsub(/\n/, " ").downcase # for simplicity we ignore punctuation, capitalization and line breaks
#puts corpus

ngram_counts = Hash.new
for i in 1..2 # we only look at unigram and bigram counts here.
  ngram_counts[i] = corpus.split(" ").each_cons(i).to_a.reduce(Hash.new(0)) {|acc, word| acc[word] += 1; acc }.map{|k,v| [k.join(" "), v]}.to_h
  puts "For #{i}-grams number of word types = #{ngram_counts[i].size}"
end
puts "Printing n-gram raw counts"
pp ngram_counts

good_turing_bins = []
good_turing_bins[0] = [corpus.split.count] # N = 18
for i in 1..2 # bins for unigrams and bigrams only
  good_turing_bins[i] = []
  good_turing_bins[i][0]=corpus.split.count # we will keep the corpus size in the zeroeth index
  (1..ngram_counts[i].values.max).each {|j| good_turing_bins[i][j] = ngram_counts[i].values.reduce(0) {|acc, cnt| cnt==j ? 1+acc : acc} }
end

pp good_turing_bins
ngram_model=1 # for bigram probabilities try ngram_model=2 and next_word=whitefish trout
next_word = "whitefish"
next_word_count = ngram_counts[ngram_model].fetch(next_word, 0)
next_word_revised_count = next_word_count==0 ? 0 : ((next_word_count+1)*(good_turing_bins[ngram_model][next_word_count+1].to_f))/(good_turing_bins[ngram_model][next_word_count])
next_word_gt_probability = next_word_count==0 ? good_turing_bins[ngram_model][next_word_count+1].to_f/good_turing_bins[0][0] : next_word_revised_count / good_turing_bins[i][0] 
puts "Next word: #{next_word}, count: #{next_word_count}, revised count: #{next_word_revised_count}, GT probability: #{next_word_gt_probability}"
