# encoding: utf-8
require_relative './RNGTK.rb'
require 'pp'

#ngtk = Ngrams.new("/wymiana/Projekty/NLP/persuasion.txt", max_ngram_model: 1)
#puts "OK, NGTK ready"
#puts "Raw counts for she = #{ngtk.get_raw_counts('she')}"
#puts ngtk.calculate_mle_probabilitity("she")

simplemodel = Ngrams.new("simplecorpus.txt", max_ngram_model: 4, k: 7)
puts simplemodel.calculate_mle_probabilitity("ugly")

fine=simplemodel.calculate_gt_probability(next_ngram: "your house looks fine")
nice=simplemodel.calculate_gt_probability(next_ngram: "your house looks nice")
lovely=simplemodel.calculate_gt_probability(next_ngram: "your house looks lovely")
good=simplemodel.calculate_gt_probability(next_ngram: "your house looks good")

simpleh = {"fine" => fine, "nice" => nice, "lovely" => lovely, "good" => good}
simpleh.each {|k,v| puts "P*(your house looks #{k}) = #{v}"}
puts "P*(your house looks ugly) = #{simplemodel.calculate_gt_probability(next_ngram: 'your house looks ugly')}"
puts "c*(your house looks fine) = #{simplemodel.get_revised_counts(next_ngram: 'your house looks fine')}"
#puts "Sum = #{simpleh.values.sum}"



#xx=simplemodel.get_gt_bins
#puts xx
#puts xx[4][1].to_f/xx[4][0]