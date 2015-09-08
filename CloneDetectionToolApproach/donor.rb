#! /usr/bin/env ruby

## Each commit in the donor application is of type Donor. 
## It contains same as Commit class, 
## list of hosts commits from type “Host” (hosts); only hosts commits that were created after the donor commit are added to this list, 
## and list of files that have added/changed in the donor commit and have clone codes with any of its hosts commit (path only).

class Donor < Commit

	def initialize(cid, pname, date, number, hosts, files)
		super(cid, pname, date, number)
		@hosts = hosts
		@files = files
	end

	def cid
		@cid
	end

	def pname
		@pname
	end

	def folderNo
		@folderNo
	end

	def hosts
		@hosts
	end

	def files
		@files
	end

end
