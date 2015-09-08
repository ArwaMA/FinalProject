#! /usr/bin/env ruby

require "FileUtils"
All_result = "#{Dir.pwd}/Manual Study Result 3"
RepoPath = ARGV[0]
Type = ARGV[1]
Name = ARGV[2]

Dir.chdir("#{RepoPath}") do
	all = []
	FileUtils.mkdir_p("#{All_result}/#{Name}")
	%x{git log --pretty=format:"%H" > "#{All_result}/#{Name}/allLogsCommitOnly.txt"} if Type == ".git"
	%x{hg log | grep -oE " [0-9]+:[a-z0-9]+( |$)" > "#{All_result}/#{Name}/allLogsCommitOnly.txt"} if Type == ".hg"
	number = 1
	File.open("#{All_result}/#{Name}/allLogsCommitOnly.txt", "r") do |line|
		while (commitId = line.gets)
			number = number + 1
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
			if msg.include?"chunck recycle" or msg.include?"jemalloc" or msg.include?"chunck record" or msg.include?"cssfixme" or msg.include?"hallvors"
 				all.push(commitId)
			end
		end
	end
	File.open("#{All_result}/#{Name}/AllCommits.txt", "a") do |commitInfo|
		all.each do |commit|
			commitInfo.puts %x{git log -1 #{commit}} if Type == ".git"
			commitInfo.puts %x{svn log -#{commit}} if Type == ".svn"
			commitInfo.puts %x{hg log -r #{commit}} if Type == ".hg"
			commitInfo.puts "\n"
		end
	end
end

