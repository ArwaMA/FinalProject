#! /usr/bin/env ruby

require "FileUtils"
require 'tokenizer'
require 'Stopwords'
require "lemmatizer"

class ManualStudy

	Bag_of_Words_port = "Bag-of-Words-port.txt"
	Bag_of_Words_new = "Bag-of-Words-new.txt"
	Log_directory = "Logs"
	All_result = "#{Dir.pwd}/Manual Study Result"
	Bag_of_Words_result = "Bag of words result"
	RepoPath = ARGV[0]
	Type = ARGV[1]
	Confidential_level = ARGV[2]
	Margine_of_error = ARGV[3]
	P_value = ARGV[4]
	Name = ARGV[5]


	def initialize
		@words_port = []
		@words_new = []
		@number_of_commits = 0
		File.readlines(Bag_of_Words_port).each do |line|
      		@words_port.push(line.strip)
    	end
    	File.readlines(Bag_of_Words_new).each do |line|
      		@words_new.push(line.strip)
    	end
    	@allCommits = {}
    	@z = 1.96
    	FileUtils.mkdir_p("#{All_result}/#{Name}") # make a new one
    	FileUtils.mkdir_p("#{All_result}/#{Name}/#{Bag_of_Words_result}")
	end

	# check if provided path is exist and contains .git/.hg/.svn folder.
	def checkexistance(path)
		if Dir.exists?(path)
			Dir.chdir("#{path}") do
				if !(Dir.exist?("#{Type}"))
					puts "There is no #{Type} directory here, I am in #{Dir.pwd}"
					exit 1
				end
			end
		else
			exit 1
		end
	end

	# get all the logs (commit id only) and save it in a file.
	def getLogs(path)
		Dir.chdir("#{path}") do
			FileUtils.mkdir_p("#{All_result}/#{Name}/#{Log_directory}")
			%x{git log --pretty=format:"%H"  > "#{All_result}/#{Name}/#{Log_directory}/allLogsCommitOnly.txt"} if Type == ".git"
			%x{svn log | grep -oE "r[0-9]+" > "#{All_result}/#{Log_directory}/allLogsCommitOnly.txt"} if Type == ".svn"
			%x{hg log  | grep -oE " [0-9]+:[a-z0-9]+( |$)" > "#{All_result}/#{Log_directory}/allLogsCommitOnly.txt"} if Type == ".hg"
		end
	end

	# I don't think I need it 
	def msgTokentize(msg)
		de_tokenizer = Tokenizer::Tokenizer.new
		array = de_tokenizer.tokenize(msg)
		return array
	end

	def removeStopWords(msg)
		filter = Stopwords::Snowball::Filter.new "en"
		array = filter.filter msg.split
		return array
	end

	def stemMsg(msg_array)
		lem = Lemmatizer.new
		lem_array = []
		msg_array.each do |word|
			lem_array.push(lem.lemma(word))
		end
		return lem_array.join(' ')
	end

	def countOccurnace(lem_msg, commit)
		jaccard = 0
		split_msg = lem_msg.split(/\s+/)
		union_array = @words_port + @words_new
		intersection_array = split_msg & union_array
		sum_min = intersection_array.size
		words_hash = {}
		if (!(split_msg & @words_port).empty?) and (!(split_msg & @words_new).empty?) ## it should contain at least one word from each bag
			split_msg.each do |word|
				if union_array.include?(word)
					if words_hash.has_key?(word)
	    	       		words_hash[word] = words_hash[word] + 1 ## tf of word
	   				else
	     				words_hash[word] = 1
	    			end
	    		end
    		end
		end		  
		sum_max = words_hash.inject(0) { |sum, tuple| sum += tuple[1] }
		jaccard = sum_min.to_f / sum_max.to_f if sum_max > 0
		@allCommits[commit] = jaccard if jaccard > 0
	end
	
	# check if commit msg contain any of the words in Bag-of-words file.
	def checkMsg(path)
		Dir.chdir("#{path}") do
			File.open("#{All_result}/#{Name}/#{Log_directory}/allLogsCommitOnly.txt", "r") do |line|
				while (commitId = line.gets)
					@number_of_commits = @number_of_commits + 1
					msg = %x{git log --format=%B -n 1 #{commitId}} if Type == ".git"
					msg = %x{svn log -#{commitId}}.scan(/^\n.+\n/)[0].to_s.strip if Type == ".svn"
					commitId = commitId[commitId.index(':')+1..-1] if Type == ".hg"
					msg = %x{hg log -r #{commitId}}.scan(/(?<=summary:     ).+/)[0].to_s.strip if Type == ".hg"
					if ! msg.valid_encoding? 
 						 msg = msg.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8')
 						 msg.gsub!(/[^\p{Alnum}\p{Space}-]/, '') # remove non-alphanumerical 
 					else
 						msg.gsub!(/[^\p{Alnum}\p{Space}-]/, '') # remove non-alphanumerical 
					end
					msg.downcase! # converting all word in msg to lower case
					msg_array = removeStopWords(msg) # remove stop words
					lem_msg = stemMsg(msg_array) # lemanization
					countOccurnace(lem_msg, commitId)
				end
			end
		end
	end

	def parameters
		case Confidential_level
		when 90
			@z.replace(1.645)
		when 95
			@z.replace(1.96)
		when 98
			@z.replace(2.33)
		when 99
			@z.replace(2.575)
		end
	end

	def getRandom
		if @allCommits.length > 30
			x = ((@z ** 2) * P_value.to_f * (1 - P_value.to_f))/(Margine_of_error.to_f ** 2)
			n = ((@allCommits.length.to_f * x)/(x + (@allCommits.length - 1).to_f)).ceil ## appropriate sample size
			arr = @allCommits.to_a
			selected = arr.sample(n) ## get random from result
			printToFile(RepoPath, selected)
		else
			printToFile(RepoPath, @allCommits.to_a)
		end
	end

	# print to a file, the commits that contain any of the words.
	def printToFile(path, array_Selected)
		sorted = array_Selected.sort {|a,b| a[1] <=> b[1]}.reverse	
		Dir.chdir("#{path}") do
			File.open("#{All_result}/#{Name}/#{Bag_of_Words_result}/AllCommits.txt", "a") do |commitInfo|
				commitInfo.puts "Total number of commit: #{@number_of_commits}"
				commitInfo.puts " "
				commitInfo.puts " "
				sorted.each do |commit|
					commitInfo.puts "Similarity: #{commit[1]}"
					commitInfo.puts %x{git log -1 #{commit[0]}} if Type == ".git"
					commitInfo.puts %x{svn log -#{commit[0]}} if Type == ".svn"
					commitInfo.puts %x{hg log -r #{commit[0]}} if Type == ".hg"
					commitInfo.puts "\n"
					commitInfo.puts "Files Changed:"
					commitInfo.puts %x{git show --diff-filter=AM --pretty="format:" --name-only #{commit[0]}} if Type == ".git"
					commitInfo.puts %x{svn log --verbose -#{commit[0]}}.scan(/(?<=[MA]\s).+/) if Type == ".svn"
					commitInfo.puts %x{hg status --change #{commit[0]}}.scan(/(?<=[MA]\s).+/) if Type == ".hg"
					commitInfo.puts "\n"
					commitInfo.puts "*" * 100
					commitInfo.puts "\n"
				end
			end
		end
	end

	manualS = ManualStudy.new
	manualS.checkexistance(RepoPath)
	manualS.getLogs(RepoPath)
	manualS.checkMsg(RepoPath)
	manualS.parameters
	manualS.getRandom
end