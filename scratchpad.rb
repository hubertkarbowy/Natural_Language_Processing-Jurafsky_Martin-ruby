# encoding: utf-8
## RNGTK (Ruby Ngram Toolkit) demo
##
## Author: Hubert Karbowy (hk atsign hubertkarbowy.pl)
## See my blog on http://www.hubertkarbowy.pl
##
## This script demonstrates some of the typical ngram operations: getting raw counts, discounted (Good-Turing) counts,
## MLE probabilities, GT probabilities, conditional probabilities (with and without discounting) and Katz backoff.
##
## Requires RNGTK v. 0.93a and Ruby 2.4.0 - might work with 2.3 and 2.2, won't work with lower versions

# This program demonstrates RNGTK
# Please don't take Good-Turing discounted counts and discounted probabilities on faith. It is quite likely that is version still contains bugs. 

require_relative './RNGTK.rb'
require 'pp'

simplemodel = Ngrams.new(corpus: 'churchill.txt', max_ngram_model: 3, k: 2, normalize: :by_token)
#simplemodel = Ngrams.new(corpus: 'persuasion.txt', normalize: :by_token, max_ngram_model: 4, k: 4)
ngramcounts = simplemodel.get_ngram_counts

begin
for n in 1..3 do
    puts "========== #{n}-grams ==========="
#    puts ngramcounts[n]
#    ngramcounts[n].each {|k,_| puts "c*(#{k}) = #{simplemodel.get_revised_counts(next_ngram: k)}"}
#    ngramcounts[n].each {|k,_| puts "P*(#{k}) = #{simplemodel.calculate_gt_probability(next_ngram: k)}"}
    totalprob=ngramcounts[n].reduce(0){|acc, (k,v)| acc += simplemodel.calculate_gt_probability(next_ngram: k)}
    prob_unk = simplemodel.calculate_gt_probability(next_ngram: "#{'unknown '*n}")
    puts " Probability (seen):  #{totalprob}\n+Probability (unseen): #{prob_unk}\n=Total probability = #{totalprob+prob_unk}"
end

puts "c (german) = #{simplemodel.get_raw_counts('german')}"

puts "\n============ MLE conditional probabilities with raw counts ================"
prior = 'german'
posterior = ['forces', 'failure', 'exactions', 'aggression', 'power', 'broadcast', 'troops', 'hands', 'and', 'war', 'air']
posterior.each {|x| puts "P(#{x} | #{prior}) = #{simplemodel.calculate_conditional_probability(posterior: x, prior: prior, ngram_model: 2)}, c(#{prior + ' ' + x}) = #{ngramcounts[2][prior+' '+x]}"}
puts "Sum of conditional probabilities = #{posterior.reduce(0) {|acc, x| acc+=simplemodel.calculate_conditional_probability(posterior: x, prior: prior, ngram_model: 2)}}"


puts "\n============ Revised conditional probabilities with Good-Turing discounted counts ================"
prior = 'german'
posterior = ['forces', 'failure', 'exactions', 'aggression', 'power', 'broadcast', 'troops', 'hands', 'and', 'war', 'air']
posterior.each {|x| puts "P(#{x} | #{prior}) = #{simplemodel.calculate_conditional_probability(posterior: x, prior: prior, ngram_model: 2, discounted: true)}, c*(#{prior+' '+x}) = #{simplemodel.get_revised_counts(next_ngram: prior+' '+x)}"}
puts "Sum of revised conditional probabilities = #{posterior.reduce(0) {|acc, x| acc+=simplemodel.calculate_conditional_probability(posterior: x, prior: prior, ngram_model: 2, discounted: true)}}"
end

n=2
simplemodel.set_oov(testset: "wenn ist das nunstuck git und slotermeyer ja great beiherhund das oder die flipperwaldt gersput", max_ngram_model: n)
puts "\n============ GT discounting and dividing leftover probability equally between known number of unseen n-grams ================"
for i in 1..n do puts "Leftover probability for #{i}-grams: #{simplemodel.get_leftover_probability[i]}"; end
phrase = 'great beiherhund'
totalprob=phrase.split.each_cons(n).reduce(1) {|acc, ngram| acc * (simplemodel.calculate_gt_probability(next_ngram: ngram.join(" "), ngram_model: n))}
puts "P(#{phrase}) = #{totalprob}"
phrase = 'great britain'
totalprob=phrase.split.each_cons(n).reduce(1) {|acc, ngram| acc * (simplemodel.calculate_gt_probability(next_ngram: ngram.join(" "), ngram_model: n))}
puts "P(#{phrase}) = #{totalprob}"


n=3
puts "\n============ Katz-backoff demonstration ================"

phrase1 = 'fighting with germany'
totalprob1=phrase1.split.each_cons(n).reduce(1) {|acc, bigram| puts "Processing #{n}-gram #{bigram.join(" ").red}"; acc * (simplemodel.calculate_katz_probability(next_ngram: bigram.join(" "), ngram_model: n))}
puts "P(#{phrase1}) = #{totalprob1}"

phrase2 = 'fighting with slotermeyer'
totalprob2=phrase2.split.each_cons(n).reduce(1) {|acc, bigram| puts "Processing #{n}-gram #{bigram.join(" ").red}"; acc * (simplemodel.calculate_katz_probability(next_ngram: bigram.join(" "), ngram_model: n))}
puts "P(#{phrase1}) = #{totalprob1}, now compare with:"
puts "P(#{phrase2}) = #{totalprob2}"

simplemodel.clear_oov_counts

phrase3 = 'fighting with depression'
totalprob3=phrase3.split.each_cons(n).reduce(1) {|acc, bigram| puts "Processing #{n}-gram #{bigram.join(" ").red}"; acc * (simplemodel.calculate_katz_probability(next_ngram: bigram.join(" "), ngram_model: n))}
puts "P(#{phrase1}) = #{totalprob1} (all words present in the corpus) now compare with:"
puts "P(#{phrase2}) = #{totalprob2} (\"slotemeyer\" absent, but its probability is only part of the total leftover) and with:"
puts "P(#{phrase3}) = #{totalprob3} (\"depression\" absent with all the leftover probability assigned to it)"

n=2
discount = 0.25
puts "\n============ Knesser-Ney demonstration with #{n}-grams and fixed discount = #{discount} ================"

phrase = 'great britain'
totalprob=phrase.split.each_cons(n).reduce(1) {|acc, ngram| acc * (simplemodel.calculate_kn_probability(next_ngram: ngram.join(" "), ngram_model: n, discount: discount))}
puts "P(#{phrase}) = #{totalprob}\n\n"

phrase = 'great enemy'
totalprob=phrase.split.each_cons(n).reduce(1) {|acc, ngram| acc * (simplemodel.calculate_kn_probability(next_ngram: ngram.join(" "), ngram_model: n, discount: discount))}
puts "P(#{phrase}) = #{totalprob}\n\n"

phrase = 'great wizard'

totalprob=phrase.split.each_cons(n).reduce(1) {|acc, ngram| acc * (simplemodel.calculate_kn_probability(next_ngram: ngram.join(" "), ngram_model: n, discount: discount))}
puts "P(#{phrase}) = #{totalprob}"

puts "For comparison:"
simplemodel.be_quiet
puts "Pkatz(great britain) = #{simplemodel.calculate_katz_probability(next_ngram: 'great britain')}"
puts "Pkatz(great enemy) = #{simplemodel.calculate_katz_probability(next_ngram: 'great enemy')}"
