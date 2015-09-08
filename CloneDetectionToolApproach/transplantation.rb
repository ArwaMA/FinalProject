#! /usr/bin/env ruby

require "fileutils"
require "find"
require "socket"
require "pathname"
require "date"
load "clonetool.rb"
load "parser.rb"
load "Files.rb"
load "commit.rb"
load "host.rb"
load "donor.rb"

	
class Transplantation

	def initialize
		@allDonors = []
		@allHosts = []
		@donors = []
		@dist = []
		@rename = String.new("-consistent")
		@threshold = String.new("0.3")
		
	end

	transplant = Transplantation.new

		DonorPath = ARGV[0]
		HostPath = ARGV[1]
		NiCadPath = ARGV[2]
		Type = ARGV[3]
		Language = ARGV[4]
		DonorName = ARGV[5]
		HostName = ARGV[6]
		Donor_repo_type = ARGV[7]
		Host_repo_type = ARGV[8]
		Distance_threshold = ARGV[9]
		Host_similarity_threshold = ARGV[10]
		Clones_lines_threshold = ARGV[11]
		C1 = ARGV[12]
		C2 = ARGV[13]
		C3 = ARGV[14]

	## Files should be in NiCad's Path
	MainPath = "#{NiCadPath}/#{DonorName}AND#{HostName}"

	$stdout.reopen("out.txt", "w")
	$stderr.reopen("err.txt", "w")

	## This method collects the donor/host's logs and saves them in a file.
	def getLogs(name, repo_type)
		logPath = "#{MainPath}/#{name}Log"
		FileUtils.mkdir_p(logPath)
		%x{git log --pretty=format:"%H" --reverse > "#{logPath}/allLogFor#{name}CommitOnly.txt"} if repo_type == ".git"
		%x{hg log -r : | grep -oE " [0-9]+:[a-z0-9]+( |$)" > "#{logPath}/allLogFor#{name}CommitOnly.txt"} if repo_type == ".hg"
		%x{svn log -r1:HEAD | grep -oE "r[0-9]+" > "#{logPath}/allLogFor#{name}CommitOnly.txt"} if repo_type == ".svn"	
	end

	## Check if the provided donor/host paths contain git repo.
	def checkgitexistance(path, name, repo_type)
		Dir.chdir("#{path}") do
			if Dir.exist?("#{repo_type}")
				puts "get logs for #{name}"
				getLogs(name, repo_type)
			else
				puts "There is no #{repo_type} directory here, I am in #{Dir.pwd}"
				exit 1
			end
		end
	end

	transplant.checkgitexistance(DonorPath, DonorName, Donor_repo_type)
	transplant.checkgitexistance(HostPath, HostName, Host_repo_type)
	
	## Get all the changed files in a commit in the donor and store them in a directory.
	def getfiles(path, filepath, repo_type)
		Dir.chdir("#{path}") do
			File.open("#{filepath}/ListOfChangedFilesName.txt", "r") do |changedfiles|
				while (filename = changedfiles.gets)
					if (!("#{filename}".eql? ("\n")))
						filename = filename.strip
						if (File.extname("#{filename}") == ".#{Language}")
							if Dir.exists?(File.dirname("#{filename}"))
								allFilesChanged = "#{filepath}/Files/files"
								FileUtils.mkdir_p("#{allFilesChanged}")
								fullPath = File.realdirpath("#{filename}")
								if ("#{filename}".include? "/") ## It is a directory, so we need to get all sub-directories
									directories = File.dirname("#{filename}")
									arraydirectories = directories.split("/")
									length = 0
									while length < arraydirectories.size do
										if (!(arraydirectories[length].empty?))
											if (arraydirectories[length].include? (" "))
												arraydirectories[length] = arraydirectories[length].delete(' ')
											end
											length = length + 1
										else
											length = length + 1
										end
									end
									directories = arraydirectories.join("/") 
									morefiles = "#{allFilesChanged}/#{directories}"
									FileUtils.mkdir_p("#{morefiles}")
									f = File.basename("#{filename}")
									%x{cat "#{fullPath}" > "#{morefiles}/#{f}"}
								else
									%x{cat "#{fullPath}" > "#{allFilesChanged}/#{filename}"}
								end 
							end
						end
					end ## end of if
				end ## end of while
			end
		end
	end
	
	## Get list of all files that have changed in a commit in the host and store them in a file.
	def filesChanged(path, filesChangedpath, commit, repo_type, count, clue)
		Dir.chdir("#{path}") do
			FileUtils.mkdir_p("#{filesChangedpath}")
			File.open("#{filesChangedpath}/AbouttheCommit.txt", "w") do |changedfiles|
				changedfiles.puts %x{git log -1 -U #{commit}} if repo_type == ".git"
				changedfiles.puts %x{svn log -#{commit}} if repo_type == ".svn"
				changedfiles.puts %x{hg log -r #{commit}} if repo_type == ".hg"
			end
			
			%x{git reset --hard #{commit}} if repo_type == ".git"
			%x{svn update --revision #{commit}} if repo_type == ".svn"
			%x{hg update -C #{commit}} if repo_type == ".hg"
			revision = %x{svn info | grep "Revision" | awk '{print $2}'} if repo_type == ".svn"

			File.open("#{filesChangedpath}/ListOfChangedFilesName.txt", "w") do |changedfileslist|
				## bring all files for the first commit then just bring the changed files
				if clue == "Donor"
					if count == 1
						changedfileslist.puts %x{git ls-files} if repo_type == ".git"
						changedfileslist.puts %x{svn log --verbose -#{commit}}.scan(/(?<=[MA]\s).+/) if repo_type == ".svn"
						changedfileslist.puts %x{hg status --all}.scan(/(?<=[CMI]\s).+/) if repo_type == ".hg"
					else
						changedfileslist.puts %x{git show --diff-filter=AM --pretty="format:" --name-only #{commit}} if repo_type == ".git"
						changedfileslist.puts %x{svn log --verbose -#{commit}}.scan(/(?<=[MA]\s).+/) if repo_type == ".svn"
						changedfileslist.puts %x{hg status --change #{commit}}.scan(/(?<=^[MA]\s).+/) if repo_type == ".hg"
					end
				else
					changedfileslist.puts %x{git show --diff-filter=AM --pretty="format:" --name-only #{commit}} if repo_type == ".git"
					changedfileslist.puts %x{svn log --verbose -#{commit}}.scan(/(?<=[MA]\s).+/) if repo_type == ".svn"
					changedfileslist.puts %x{hg status --change #{commit}}.scan(/(?<=^[MA]\s).+/) if repo_type == ".hg"
				end

			end
			getfiles(path, filesChangedpath, repo_type)
		end
	end

	def fileClone(clonesData, host)
		hostFiles = []
		while (!(clonesData.empty?)) do
			clone = clonesData.first
			array = clonesData.select {|item| clone.hs == item.hs} 
			clonesData = clonesData - array
			name = File.basename("#{clone.hs[0]}") ## I added [0] recently.
			if name.include?".ifdefed"
				name = name[0..name.length-9]
			end
			file = Files.new(name.to_s, array)
			hostFiles.push(file)
		end 
		if (hostFiles.size > 0)
			host.addfile(hostFiles)
		end
	end

	## Analyse NiCAd report to get the needed information; for each clone: number of lines, percentage of similarity, 
	## donor file path, start line number, end line number, host file path, start line number, and end line number. 
	## Then, inserting the needed information into an array.
	def analysereport(pathH, host, repeated_clones)
		if (Dir["#{pathH}/Files/files_blocks#{@rename}-crossclones"].count != 0)
			if (File.readlines("#{pathH}/Files/files_blocks#{@rename}-crossclones/files_blocks#{@rename}-crossclones-#{@threshold}.xml").grep(/clone nlines=/).size > 0)
				allmatch = File.read("#{pathH}/Files/files_blocks#{@rename}-crossclones/files_blocks#{@rename}-crossclones-#{@threshold}.xml")
				puts "create clone objects"
				content = allmatch.scan(/(<clone nlines=.*<\/clone>.*?)\n/m).to_s
				clonedata = []
				clonedata_new = []
				parse = Parser.new
				parse.parsexmlfile(content, clonedata)
				puts "clone data before #{clonedata.length}"
				if clonedata.length > 0
					clonedata.sort {|a,b| a.nline[0].to_i <=> b.nline[0].to_i}.reverse! if clonedata.length > 1
					clonedata.each do |clone|
						if !repeated_clones.any? {|e| e == clone}
							repeated_clones.push(clone)
							clonedata_new.push(clone)
						end
					end
				end
				fileClone(clonedata_new, host)
			else
				puts "no clone code here"
			end
		end
	end

	## NiCad part, send to NiCad all the files that have changed in the donor with all the files that have chnaged in the host. 
	## NiCad will save a report in each host (if type3 clones found).
	def sendnicad(donorNo, hostNo, host, repeated_clones)
		pathD = "#{MainPath}/FilesChanged/Donor/Donor#{donorNo}"
		pathH = "#{MainPath}/FilesChanged/Host/Host#{hostNo}"
		Dir.chdir("#{pathD}") do
			if (Dir["Files"].count != 0) ## there is some files
				file1 = "#{pathD}/Files/files"
				Dir.chdir("#{pathH}") do
					if (Dir["Files"].count != 0)
						file2 = "#{pathH}/Files/files"
						puts "send to nicad"
						%x{nicad3cross blocks #{Language} #{file1} #{file2} #{Type}}
						analysereport(pathH, host, repeated_clones)
					else
					puts "No files in host/ no clones between this donor and host"
					end ## end of if Files exist in host
				end ## end of Dir to host
			else
			puts "No files in donor/ no clones between this donor and host"
			end ## end of if Files exist in donor
		end ## end of Dir to donor
	end ## end of def

	def parseDate(date_before, repo_type)
		date = DateTime.new(date_before[0..3].to_i, date_before[5..6].to_i, date_before[8..9].to_i, date_before[11..12].to_i, date_before[14..15].to_i)
		return date
	end

	## building the structure of the files in the donor and in the host. 
	##Creating an object of kind commit for each commit in the donor and in the host, 
	##the commit contains commit id, program name, and the date in which the commit was created.
	
	def buildStructure(path, name, clue, repo_type)
		allCommits = [] 
		count = 0
		Dir.chdir("#{path}") do
			File.open("#{MainPath}/#{name}Log/allLogFor#{name}CommitOnly.txt", "r") do |commitlog|
				while (commitId = commitlog.gets)
					date_before = %x{git show -s --format=%ci #{commitId}} if repo_type == ".git"
					date_before = %x{svn log -#{commitId}}.scan(/\s[0-9]+\-[0-9]+\-[0-9]+\s[0-9]+:[0-9]+:[0-9]+\s/)[0].to_s.strip if repo_type == ".svn"
					d = commitId[0..commitId.index(':')-1].strip if repo_type == ".hg"
					date_before = %x{hg log -r#{d} --template '{date|isodate}\n'} if repo_type == ".hg"
					date = parseDate(date_before, repo_type)
					count = count + 1
					commit = Commit.new(commitId, name, date, count)
					allCommits.push(commit)
					filesPath = "#{MainPath}/FilesChanged/#{clue}/#{clue}#{count}" 
					filesChanged(path, filesPath, commitId, repo_type, count, clue)
				end
			end
		end	
			return allCommits
	end # end of def

	@allDonors = transplant.buildStructure(DonorPath, DonorName, "Donor", Donor_repo_type)
	@allHosts = transplant.buildStructure(HostPath, HostName, "Host", Host_repo_type)

	def getcandidates(allDonors, allHosts)
		repeated_clones = Array.new
		allDonors.each do |donor|
			donorHosts = []
			donorFiles = []
			allHosts.each do |host|
				if ("#{donor.date}" < "#{host.date}")
					commitWithDateFilter = "#{MainPath}/CommittsWithDateFilter"
					FileUtils.mkdir_p("#{commitWithDateFilter}")
					File.open("#{commitWithDateFilter}/#{DonorName}commitOlderthan#{HostName}commit.txt", "a") do |datefilterfile|
						datefilterfile.puts "Donor #{donor.cid} was created before host #{host.cid} \n"
					end
					hostO = Host.new(host.cid, HostName, host.date, host.folderNo)
					sendnicad(donor.folderNo, host.folderNo, hostO, repeated_clones)
					if (hostO.files.size > 0) ## If the host has files that contain clones
						donorHosts.push(hostO) ## Put the host in the current donor array
					end
				end
			end
			if (donorHosts.size > 0) ## If the current donor array has some hosts that contain files that contain clones code
				donorHosts.each do |host|
					host.files.each do |file|
						donorFiles = (donorFiles + file.clones.collect {|item| item.ds}.uniq).uniq ## get the files in the donor
					end
				end
				donorO = Donor.new(donor.cid, DonorName, donor.date, donor.folderNo, donorHosts, donorFiles) ## Create the current donor object and add the array to it
				@donors.push(donorO) ## put the donor in the all donors (the big array) array.
			end
		end
	end

	def checkType
		case Type
		when "type1"
			@rename.replace("")
			@threshold.replace("0.0")
		when "type2" 
			@rename.replace("-blind")
			@threshold.replace("0.0")
		when "type2c"
			@rename.replace("-consistent")
			@threshold.replace("0.0")
		when "type3-1"
			@rename.replace("")
			@threshold.replace("0.3")
		when "type3-2"
			@rename.replace("-blind")
			@threshold.replace("0.2")
		when "type3-2c"
			@rename.replace("-consistent")
			@threshold.replace("0.3")
		end
	end

	transplant.checkType
	transplant.getcandidates(@allDonors, @allHosts)

	# NiCad report contains similarity and number of lines which were calculated after parsing source files. 
	# However, the start line number and end line number are not matched with number of lines, so which is actually in file is written
	# inclusing comments line and differences on files. Since we don't know which options is used for pretty print source file, we will use their numbers
	# to calculate the parsed numbers.
	# What we will have after this method: each start and end line attribute within clone object will contain array. 
	# First index is what is actually in file without pretty print (for later usage if we want to see the code)
	# and second index which contains parsed number and what NiCad actually uses to calculate similarity (to calculate similarity).
	def parseNicadOutput
		@donors.each do |donor|
			donor.hosts.each do |host|
				host.files.each do |file|
					i = 0
					file.clones.sort! {|a,b| a.hstart[0].to_i <=> b.hstart[0].to_i}
					if file.clones.size > 0 
						file.clones[0].dstart.push(file.clones[0].dstart[0]) ## I am not sure if we need to do it for donor!
						file.clones[0].hstart.push(file.clones[0].hstart[0])
					end
					while i < file.clones.size
						# end line should be start line + number of lines (to remove white spaces and comments lines)
						file.clones[i].dend.push((file.clones[i].dstart[1].to_i + file.clones[i].nline[0].to_i).to_s)
						# but we want to keep the difference between 2 clones in the same file. So, next clone will start 
						# just after the difference between old numbers
						file.clones[i+1].dstart.push((file.clones[i].dend[1].to_i + (file.clones[i+1].dstart[0].to_i - file.clones[i].dend[0].to_i)).to_s) if i != file.clones.size - 1
						file.clones[i].hend.push((file.clones[i].hstart[1].to_i + file.clones[i].nline[0].to_i).to_s)
						file.clones[i+1].hstart.push((file.clones[i].hend[1].to_i + (file.clones[i+1].hstart[0].to_i - file.clones[i].hend[0].to_i)).to_s) if i != file.clones.size - 1
						i = i + 1
					end
				end
			end
		end
	end

	transplant.parseNicadOutput

	## get donor files from clones in a host. So get what it is between donor and host.
	def getDonorFiles
		puts " "
		@donors.each do |donor|
			donor.hosts.each do |host|
				host.files.each do |file|
					donor_files = []
					file.clones.each do |clone|
						puts clone
						donor_files.push(clone.ds[0].to_s)
					end
					donor_files = donor_files.uniq
					file.setDonorFiles(donor_files) if !donor_files.empty?
				end
			end
		end
	end
	transplant.getDonorFiles

	def getDistanceBTClones(file_clones, clones_distance)
		i = 0
		while i < file_clones.length 
			if i == file_clones.length - 1
				clones_distance = clones_distance + 0
				break
			else
				distance = file_clones[i+1].hstart[1].to_i - file_clones[i].hend[1].to_i
				if distance < 0 ## one inside one
					file_clones.delete(file_clones[i+1])
				else
					clones_distance = clones_distance + distance
					i = i + 1
				end
			end
		end
		return clones_distance
	end

	## Taken from http://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Longest_common_substring#Ruby
	def find_longest_common_substring(s1, s2)
	    if (s1 == "" || s2 == "")
	      return ""
	    end
	    m = Array.new(s1.length){ [0] * s2.length }
	    longest_length, longest_end_pos = 0,0
	    (0 .. s1.length - 1).each do |x|
	    	(0 .. s2.length - 1).each do |y|
		    	if s1[x] == s2[y]
		        	m[x][y] = 1
		        	if (x > 0 && y > 0)
		            	m[x][y] += m[x-1][y-1]
		        	end
		        	if m[x][y] > longest_length
			            longest_length = m[x][y]
			            longest_end_pos = x
		        	end
		    	end
	    	end
	    end
	    return s1[longest_end_pos - longest_length + 1 .. longest_end_pos]
  	end

  	## Calculate the edit distance between 2 files.
	def CalDistanceBTHFiles(combination, files_distance)
		hsFile1 = combination[0].hs[0].to_s 
		hsFile2 = combination[1].hs[0].to_s
		if hsFile1 == hsFile2
			files_distance = files_distance + 0
		else
			hsFilesLength = combination[0].hs[0].to_s.split('/').size + combination[1].hs[0].to_s.split('/').size
			common_prefix = find_longest_common_substring(hsFile1, hsFile2)
			common_directory = common_prefix.sub(%r{/[^/]*$}, '') # Taken from http://rosettacode.org/wiki/Find_common_directory_path#Ruby
			files_distance = files_distance + ((hsFilesLength - (common_directory.to_s.split('/').size * 2)) - 1 )## * 2 we have two files.
		end
		return files_distance
	end

	def CalDistanceBTDFiles(combination, files_distance)
		dsFile1 = combination[0].ds[0].to_s 
		dsFile2 = combination[1].ds[0].to_s
		if dsFile1 == dsFile2
			files_distance = files_distance + 0
		else
			dsFilesLength = combination[0].ds[0].to_s.split('/').size + combination[1].ds[0].to_s.split('/').size
			common_prefix = find_longest_common_substring(dsFile1, dsFile2)
			common_directory = common_prefix.sub(%r{/[^/]*$}, '') # Taken from http://rosettacode.org/wiki/Find_common_directory_path#Ruby
			files_distance = files_distance + ((dsFilesLength - (common_directory.to_s.split('/').size * 2)) - 1 )## * 2 we have two files.
		end
		return files_distance
	end

	def getCombinations(files, files_distance, clue)
		combination = files.combination(2).to_a ## for each host files, we will get all the combination 
		if (!(combination.empty?))
			combination.each do |com|
				files_distance = CalDistanceBTDFiles(com, files_distance) if clue == "M21"
				files_distance = CalDistanceBTHFiles(com, files_distance) if clue == "12M"
			end
		end
		return files_distance
	end

	def getDistanceBTFiles(all_clones, files_distance, clue, deleted)
		same_files = all_clones.group_by {|item| item.hs[0]} if clue == "M21"
		same_files = all_clones.group_by {|item| item.ds[0]} if clue == "12M"
		same_files.each do |key, value|
  			same_files[key] = value.uniq { |v| v.ds[0] } if clue == "M21" ## remove repeated clones with the same host file name
  			same_files[key] = value.uniq { |v| v.hs[0] } if clue == "12M"
		end
		same_files.delete_if {|file, clones| deleted << clones if clones.size == 1 && !deleted.any?{|c| c == clones}} # delete one to one. ## need to be updated
		sum = same_files.inject(0) { |sum, tuple| sum += tuple.size }
		same_files.each do |k, v|
			files_distance = getCombinations(same_files[k], files_distance, clue)
		end
		return files_distance
	end

	def getDistanceBTFilesOne(deleted, all_clones, files_distance)
		clones = []
		com = []
		clones = all_clones.uniq {|name| name.hs[0]}
		deleted.each do |one|
			clones.each do |clone|
				com.push(one)
				com.push(clone)
				files_distance = CalDistanceBTHFiles(com, files_distance)
				com.clear
			end
		end
		return files_distance
	end

	def getDistance
		@donors.each do |donor|
			donor.hosts.each do |host|
				deleted = []
				host.files do |file|
					puts file
				end
				clones_distance = 0
				files_distance_host = 0
				files_distance_donor = 0
				files_distance = 0
				all_clones = []
				host.files.each do |file|
					file.clones.sort! {|a,b| a.hstart[1].to_i <=> b.hstart[1].to_i}
					clones_distance = getDistanceBTClones(file.clones, clones_distance)
					all_clones = all_clones + file.clones
				end
				clones_distance = clones_distance.to_f / C1.to_f
				files_distance_host = getDistanceBTFiles(all_clones, files_distance_host, "M21", deleted)
				files_distance_donor = getDistanceBTFiles(all_clones,files_distance_donor, "12M", deleted)
				files_distance = getDistanceBTFilesOne(deleted.flatten, all_clones, files_distance)
				files_distance_host = files_distance_host.to_f / C2.to_f
				files_distance_donor = files_distance_donor.to_f / C3.to_f
				files_distance = files_distance
				host.add_total_distance((clones_distance + files_distance_host + files_distance_donor + files_distance) / all_clones.size)
			end
		end
	end

	transplant.getDistance

	def filterCommit
		@donors.each do |donor|
			donor.hosts.delete_if {|host| host.total_distance > Distance_threshold.to_f}
		end
		@donors.delete_if {|donor| donor.hosts.size == 0}
	end
	transplant.filterCommit

	def filterCommit2
		@donors.each do |donor|
			donor.hosts.delete_if {|host| host.similarity < Host_similarity_threshold.to_f}
			donor.hosts.delete_if {|host| host.nline < Clones_lines_threshold.to_f}
		end
	end

	def calculateHostSimilarity
		@donors.each do |donor|
			donor.hosts.each do |host|
				host_similarity = 0
				no_of_clones = 0
				nline = 0
				host.files.each do |file|
					file.clones.each do |clone|
						no_of_clones = no_of_clones + 1
						host_similarity = host_similarity + clone.sim[0].to_i
						nline = nline + clone.nline[0].to_i
					end
				end
				host.addSimilariy(host_similarity.to_f/no_of_clones.to_f)
				host.addNline(nline)
			end
		end
		filterCommit2
	end
	transplant.calculateHostSimilarity
	
	def printToFile
		File.open("#{MainPath}/result.txt", "a") do |line|
			i = 1
			@donors.each do |donor|
				j = 1
				flag = false
				donor.hosts.each do |host|
					m = 1
					if j == 1
						line.puts "#{i}. Donor commit id: #{donor.cid[0..8]}	Date: #{donor.date.to_date}"
						i = i + 1
						flag = true
					end
					line.puts "		#{j}. Host commit id: #{host.cid[0..8]}		Date: #{host.date.to_date}		Similarity: #{host.similarity}"
					host.files.each do |file|
						line.puts "			#{m}. File name: #{file.name}		"
						n = 1
						file.clones.each do |clone|
							line.puts "			Clone #{n}: 	Similarity: #{clone.sim[0]}        nline: #{clone.nline[0]}"
							line.puts "			Donor commit file:"
							line.puts "			#{clone.ds[0].to_s}		(#{clone.dstart[0].to_s}, #{clone.dend[0].to_s})"
							line.puts "			Host commit file:"
							line.puts "			#{clone.hs[0].to_s}		(#{clone.hstart[0].to_s}, #{clone.hend[0].to_s})"
							line.puts " "
							line.puts " "	
							n = n + 1
						end
						m = m + 1
					end
					j = j + 1
				end
				if flag
					line.puts "\n"
					line.puts "				----------------------------------"
					line.puts "\n"
					flag = false
				end
			end
		end
	end
	transplant.printToFile


end ## end of class
