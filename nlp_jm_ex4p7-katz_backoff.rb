# Jurafsky and Martin - ex. 4.7

# Author: Hubert Karbowy (hk atsign hubertkarbowy.pl)

# This program calculates the Katz-backoff smoothed probabilities for N-grams
# Note: This is a work in progress (doesn't calculate anything yet)
# Tested with Ruby 2.2.1 - will not work with 1.9.3
require 'pp'

corpus = 
<<-ENDC
Last October, AngelList, a company that helps tech start-ups raise money and hire employees, held an office retreat. In the Hollywood Hills, far from Silicon Valley, the firm’s mostly male staff mingled poolside with bikini-clad women who had been invited to the event.Before the afternoon was over, Babak Nivi, a founder and board member at AngelList, said things that made Julie Ruvolo, a contractor, uncomfortable about working at the company. His comments included a suggestion that the women, who were not employees, warm up the pool by jumping in and rubbing their bodies together. The incident was described by two entrepreneurs who were told about it in the weeks after it occurred but were not authorized to speak about it.
Precisely what occurred at the Hollywood Hills event is not publicly known. Several weeks after the party, each side signed a nondisparagement clause as part of a settlement, the two people said, and its details are not public. And neither Ms. Ruvolo nor AngelList is permitted to talk about what happened that day.
As more harassment allegations come to light, employment lawyers say nondisparagement agreements have helped enable a culture of secrecy. In particular, the tech start-up world has been roiled by accounts of workplace sexual harassment, and nondisparagement clauses have played a significant role in keeping those accusations secret. Harassers move on and harass again. Women have no way of knowing their history. Nor do future employers or business partners.
Nondisparagement clauses are not limited to legal settlements. They are increasingly found in standard employment contracts in many industries, sometimes in a simple offer letter that helps to create a blanket of silence around a company. Their use has become particularly widespread in tech employment contracts, from venture investment firms and start-ups to the biggest companies in Silicon Valley, including Google.
Google declined to comment on its use of nondisparagement agreements.
Nondisparagement clauses have become so common that the Equal Employment Opportunity Commission, which enforces federal discrimination laws, and the National Labor Relations Board, a federal agency that protects workers’ rights, have been studying whether they are having a chilling effect on workers speaking up about wrongdoing or filing lawsuits, said Orly Lobel, a law professor at the University of San Diego.
Employees increasingly “have to give up their constitutional right to speak freely about their experiences if they want to be part of the work force,” said Nancy E. Smith, a partner at the law firm Smith Mullin. “The silence sends a message: Men’s jobs are more important than women’s lives.”
t Binary Capital, a venture capital firm in San Francisco that collapsed last month under the weight of multiple allegations of sexual harassment, new hires signed an employment contract that included the clause that “employee shall not disparage the company,” according to a contract quoted in a lawsuit filed against the firm last month.
Ann Lai, a former employee, said in her lawsuit filed in San Mateo Superior Court in California that she had complained to her bosses about sexism, discrimination and inappropriate behavior in the workplace, and that Binary used the nondisparagement provision in her employment contract to threaten her and prevent her from talking about why she had quit her job.
The nondisparagement clause made it “hard for employees to ‘speak up’ about inappropriate or illegal conduct,” the suit said, adding, “Employees are instead led to believe that it is illegal to do so, and that disclosing information about their working conditions will lead to ruinous litigation.
e founders of Binary Capital, Justin Caldbeck and Jonathan Teo, did not respond to a request for comment on their firm’s employee contract clause. Chris Baker, an employment lawyer at the law firm Baker Curtis & Schwartz who represents Ms. Lai and has sued Google over broad nondisclosure provisions, declined to comment specifically on Ms. Lai’s case.
When Mr. Caldbeck worked at Lightspeed Venture Partners, he attended board meetings at the e-commerce company Stitch Fix, on behalf of the firm. After Lightspeed was informed that Mr. Caldbeck had made Katrina Lake, the Stitch Fix chief executive, uncomfortable, Mr. Caldbeck was removed from his role on the board, according to three people with knowledge of the matter. Spokeswomen for Ms. Lake and Lightspeed declined to comment.
The company and Ms. Lake signed a mutual nondisparagement agreement in 2013, according to a copy of the agreement obtained by the news site Axios.
Mr. Caldbeck left Lightspeed the next year, but the reason he was removed from Ms. Lake’s board was not made public.
At Binary, in text messages reviewed by The New York Times, he requested evening meetings with an entrepreneur named Lindsay Meyer, asked if she was attracted to him, and if she would accompany him on overnight trips. He also questioned why she would rather be with her boyfriend than with him.
Mr. Caldbeck would not comment about the incidents at the two firms.
In its buyout agreements, The Times asks employees to agree to a limited nondisparagement clause that specifies the agreement does not prohibit people from providing information about legal violations or discrimination to the government or regulators. The terms of other nondisparagement agreements vary.
In addition to Ms. Ruvolo, three other women who work in the technology industry told The Times that they had been harassed in the workplace and signed nondisparagement agreements to settle those disputes. The women would not say more because they are not allowed to acknowledge that the agreements even exist.
AngelList grappled with a harassment disclosure after the tech news site TechCrunch reported that AngelList was investigating whether a different partner had sexually harassed someone at a previous job. The company, based in San Francisco, confirmed that it had suspended an employee pending an investigation.
Mr. Nivi continued to serve on the company’s board. The nondisparagement clause prevented potential employees and partners from knowing such allegations had been made.
Mr. Nivi said by email, “these statements about me are not true.”
s. Ruvolo says she wants to talk about her situation, but cannot. “I asked AngelList to release me from the agreement, but they have declined,” Ms. Ruvolo said. The company did not acknowledge a nondisparagement deal exists, and its terms would probably have prevented it from doing so.
“I wonder how I may have disserviced other women working in tech, including my female colleagues, with my silence,” she said. “I think we need to rethink what it means to ask for or grant silence as resolution.”
AngelList said Mr. Nivi has no role at the company and is no longer a board member, but would not say when or why he left the board.
“When we conduct investigations, individuals are removed from the workplace, given counseling if needed, and can’t contact complainants,” Graham Jenkin, AngelList’s chief operating officer, said in a statement. “Any implication that we would silence anyone or not pursue an issue is mistaken.”
Mr. Jenkin would not say whether AngelList had a nondisparagement agreement with Ms. Ruvolo or whether Mr. Nivi had harassed her. He disputed some of the details of the poolside incident described to The Times, but would not provide clarification.
Ms. Ruvolo, who was a freelance writer for AngelList and whose contract was not renewed this year, said she could not comment on the event that led to her agreement or on the terms of the deal.
“Companies wave the agreements around and use them to force a settlement and make the problem go away,” said Karen Kessler, chief executive of the public relations firm Evergreen Partners. “After that, nobody is the wiser for it.”
ENDC

def katz_backoff word, ngram_counts, good_turing_bins, c, cstar 
  
  p_star = c==0 ? nil : cstar.to_f/c
  return p_star unless p_star.nil?
  
  word_as_arr=word.split
  last_token = word_as_arr.last
  preceding_tokens = word_as_arr[0..-2].join(" ")
  
  next_word_count = ngram_counts[ngram_model].fetch(next_word, 0)
  next_word_revised_count = next_word_count==0 ? 0 : ((next_word_count+1)*(good_turing_bins[ngram_model][next_word_count+1].to_f))/(good_turing_bins[ngram_model][next_word_count])
  next_word_gt_probability = next_word_count==0 ? good_turing_bins[ngram_model][next_word_count+1].to_f/good_turing_bins[0][0] : next_word_revised_count / good_turing_bins[i][0]
  
  
  
 # beta = # leftover probability
  end

#corpus = "starttoken en sag sag en sag en sag sag comma en annan sagade sagen sagen sag dot enddtoken" # taken from https://sites.google.com/site/gothnlp/exercises/jurafsky-martin/solutions
#corpus = "carp carp carp carp carp carp carp carp carp carp perch perch perch whitefish whitefish trout salmon eel" # taken from The Book
#corpus = "apple apple apple banana banana dates dates eggs eggs eggs frogs grapes grapes" # taken from https://www.cs.cornell.edu/courses/cs6740/2010sp/guides/lec11.pdf
#corpus = corpus.gsub(/[^a-z|A-Z|\s]/, "").gsub(/\n/, " ").downcase # for simplicity we ignore punctuation, capitalization and line breaks
#puts corpus

ngram_counts = Hash.new
for i in 1..3 # this time we include trigrams
  ngram_counts[i] = corpus.split(" ").each_cons(i).to_a.reduce(Hash.new(0)) {|acc, word| acc[word] += 1; acc }.map{|k,v| [k.join(" "), v]}.to_h
  puts "For #{i}-grams number of types (unique tokens) = #{ngram_counts[i].size}"
end
#puts "Printing n-gram raw counts"
#puts ngram_counts


good_turing_bins = []
good_turing_bins[0] = [corpus.split.count]
for i in 1..3 # bins for unigrams, bigrams and trigrams
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
