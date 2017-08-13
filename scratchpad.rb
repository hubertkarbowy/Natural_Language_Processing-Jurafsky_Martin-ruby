# encoding: utf-8
require_relative './RNGTK.rb'
require 'pp'

#ngtk = Ngrams.new("/wymiana/Projekty/NLP/persuasion.txt", max_ngram_model: 1)
#puts "OK, NGTK ready"
#puts "Raw counts for she = #{ngtk.get_raw_counts('she')}"
#puts ngtk.calculate_mle_probabilitity("she")

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
