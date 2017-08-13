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


require_relative './RNGTK.rb'
require 'pp'

simplemodel = Ngrams.new(corpus: 'simplecorpus.txt', max_ngram_model: 4, k: 4)
puts simplemodel.get_revised_counts(next_ngram: 'one two three four', ngram_model: 4)

ngramcounts = simplemodel.get_ngram_counts
for n in 1..4 do
    puts "========== #{n}-grams ==========="
    puts ngramcounts[n]
    ngramcounts[n].each {|k,_| puts "c*(#{k}) = #{simplemodel.get_revised_counts(next_ngram: k)}"}
    ngramcounts[n].each {|k,_| puts "P*(#{k}) = #{simplemodel.calculate_gt_probability(next_ngram: k)}"}
    totalprob=ngramcounts[n].reduce(0){|acc, (k,v)| acc += simplemodel.calculate_gt_probability(next_ngram: k)}
    prob_unk = simplemodel.calculate_gt_probability(next_ngram: "#{'unknown '*n}")
    puts " Probability (seen):  #{totalprob}\n+Probability (unseen): #{prob_unk}\n=Total probability = #{totalprob+prob_unk}"
end

puts "============ Conditional probabilities (raw) ================"
prior = 'your house looks'
posterior = ['fine', 'nice', 'lovely', 'good']
posterior.each {|x| puts "P(#{x} | #{prior}) = #{simplemodel.calculate_conditional_probability(posterior: x, prior: prior, ngram_model: 4)}"}
puts "Sum of conditional probabilities = #{posterior.reduce(0) {|acc, x| acc+=simplemodel.calculate_conditional_probability(posterior: x, prior: prior, ngram_model: 4)}}"

puts "============ Conditional probabilities (discounted) ================"
prior = 'your house looks'
posterior = ['fine', 'nice', 'lovely', 'good']
posterior.each {|x| puts "P(#{x} | #{prior}) = #{simplemodel.calculate_conditional_probability(posterior: x, prior: prior, ngram_model: 4, discounted: true)}"}
puts "Sum of conditional probabilities = #{posterior.reduce(0) {|acc, x| acc+=simplemodel.calculate_conditional_probability(posterior: x, prior: prior, ngram_model: 4)}}"