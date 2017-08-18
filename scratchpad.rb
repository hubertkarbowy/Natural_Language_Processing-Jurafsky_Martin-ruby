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
#simplemodel = Ngrams.new(corpus: '/wymiana/Projekty/NLP/persuasion.txt', normalize: :by_token, max_ngram_model: 4, k: 4)
ngramcounts = simplemodel.get_ngram_counts

begin
for n in 1..2 do
    puts "========== #{n}-grams ==========="
#    puts ngramcounts[n]
#    ngramcounts[n].each {|k,_| puts "c*(#{k}) = #{simplemodel.get_revised_counts(next_ngram: k)}"}
#    ngramcounts[n].each {|k,_| puts "P*(#{k}) = #{simplemodel.calculate_gt_probability(next_ngram: k)}"}
    totalprob=ngramcounts[n].reduce(0){|acc, (k,v)| acc += simplemodel.calculate_gt_probability(next_ngram: k)}
    prob_unk = simplemodel.calculate_gt_probability(next_ngram: "#{'unknown '*n}")
    puts " Probability (seen):  #{totalprob}\n+Probability (unseen): #{prob_unk}\n=Total probability = #{totalprob+prob_unk}"
end

puts "============ MLE conditional probabilities with raw counts ================"
prior = 'german'
posterior = ['forces', 'failure', 'exactions', 'aggression', 'power', 'broadcast', 'troops', 'hands', 'and', 'war', 'air']
posterior.each {|x| puts "P(#{x} | #{prior}) = #{simplemodel.calculate_conditional_probability(posterior: x, prior: prior, ngram_model: 2)}, raw count = #{ngramcounts[2][prior+' '+x]}"}
puts "Sum of conditional probabilities = #{posterior.reduce(0) {|acc, x| acc+=simplemodel.calculate_conditional_probability(posterior: x, prior: prior, ngram_model: 2)}}"

puts "============ Revised conditional probabilities with Good-Turing discounted counts ================"
prior = 'german'
posterior = ['forces', 'failure', 'exactions', 'aggression', 'power', 'broadcast', 'troops', 'hands', 'and', 'war', 'air']
posterior.each {|x| puts "P(#{x} | #{prior}) = #{simplemodel.calculate_conditional_probability(posterior: x, prior: prior, ngram_model: 2, discounted: true)}, discounted count = #{simplemodel.get_revised_counts(next_ngram: prior+' '+x)}"}
puts "Sum of conditional probabilities = #{posterior.reduce(0) {|acc, x| acc+=simplemodel.calculate_conditional_probability(posterior: x, prior: prior, ngram_model: 2)}}"
end

#puts "Pkatz(of course was) = ..."
phr='german forces are'
x = simplemodel.calculate_katz_probability next_ngram: phr, ngram_model: 3
puts "Pkatz(#{phr}) = #{x}"