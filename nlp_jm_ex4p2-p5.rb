# Jurafsky and Martin - ex. 4.2 to 4.5

# Tested with Ruby 2.2.1

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

corpus = corpus.gsub(/[^a-z|A-Z|\s]/, "").gsub(/\n/, " ").downcase # for simplicity we ignore punctuation, capitalization and line breaks
#puts corpus

ngram_counts = Hash.new
for i in 1..2 # we only look at unigram and bigram counts here.
  ngram_counts[i] = corpus.split(" ").each_cons(i).to_a.reduce(Hash.new(0)) {|acc, word| acc[word] += 1; acc }.map{|k,v| [k.join(" "), v]}.to_h
  puts "For #{i}-grams number of word types = #{ngram_counts[i].size}"
end
#puts "Printing n-gram raw counts"
#pp ngram_counts

puts "N-gram log probabilities:"
phrase = "hills far from venture"
unigram_probabilitity = phrase.split(" ").reduce(1) {|acc, word| (ngram_counts[1][word].to_f/corpus.size.to_f)*acc}
unigram_logprobabilitity = phrase.split(" ").reduce(0) {|acc, word| Math.log(ngram_counts[1][word].to_f/corpus.size.to_f)+acc}
unigram_probabilitity_laplace = phrase.split(" ").reduce(1) {|acc, word| ((ngram_counts[1][word].to_f + 1)/(corpus.size+ngram_counts[1].size.to_f))*acc}
puts "Unigram probability of #{phrase} = #{unigram_probabilitity}, unigram log probability = #{-unigram_logprobabilitity}"
puts "Unigram probability of #{phrase} with Laplace smoothing = #{unigram_probabilitity_laplace}, log probability = #{-Math.log(unigram_probabilitity_laplace)}"

bigram_probabilitity = phrase.split(" ").each_cons(2).reduce(1) {|acc, word| (ngram_counts[2][word.join(" ")].to_f/ngram_counts[1][word[0]].to_f)*acc}
bigram_logprobabilitity = phrase.split(" ").each_cons(2).reduce(0) {|acc, word| Math.log(ngram_counts[2][word.join(" ")].to_f/ngram_counts[1][word[0]].to_f)+acc}
bigram_probabilitity_laplace = phrase.split(" ").each_cons(2).reduce(1) {|acc, word| ((ngram_counts[2][word.join(" ")].to_f + 1)/(ngram_counts[1][word[0]].to_f + ngram_counts[1].size))*acc}

puts "Bigram probability of #{phrase} = #{bigram_probabilitity}, bigram log probability = #{-bigram_logprobabilitity}" 
puts "Bigram probability of #{phrase} with Laplace smoothing = #{bigram_probabilitity_laplace}, bigram log probability = #{-Math.log(bigram_probabilitity_laplace)}"

howmany=10
puts "Random string for the bigram model (#{howmany} word#{howmany>1 ? "s":""})"
generated_language = ngram_counts[2].keys.sample(1).join(" ")
while howmany != 0
  last_word = generated_language.split.last
  next_key = ngram_counts[2].keys.select { |key| key.to_s.match(/^#{last_word}/)}
  if next_key==nil
    puts "That's how far we can go. How many = #{howmany}"
    break
  end
  next_word = next_key.sample(1).join.split.last
  generated_language << " " << next_word
  howmany -=1
end
puts "Generated language: #{generated_language}"
