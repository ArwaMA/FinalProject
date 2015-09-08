#! /usr/bin/env ruby

## This class represnts a clone in a file that could be found by NiCad tool between donor commit and host commit.
## Each clone has number of lines (nline), similarity (sim), donor file source (ds), 
## donor start line number (dstart), donor end line number (dend), 
## host file source (hs), host start line number (hstart), and host end line number (hend).

class CloneTool

	def initialize(nline, sim, ds, dstart, dend, hs, hstart, hend)
		@nline = nline
		@sim = sim
		@ds = ds
		@dstart = dstart
		@dend = dend
		@hs = hs
		@hstart = hstart
		@hend = hend
	end

	def nline
		@nline
	end

	def sim
		@sim
	end

	def ds
		@ds
	end

	def dstart
		@dstart
	end

	def dend
		@dend
	end

	def hs
		@hs
	end

	def hstart
		@hstart
	end

	def hend
		@hend
	end

	def setnline=(nline)
		@nline = nline
	end

	def setsim=(sim)
		@sim = sim
	end

	def setds=(ds)
		@ds = ds
	end

	def setdstart=(dstart)
		@dstart = dstart
	end

	def setdend=(dend)
		@dend = dend
	end

	def seths=(hs)
		@hs = hs
	end

	def sethstart=(hstart)
		@hstart = hstart
	end

	def sethend=(hend)
		@hend = hend
	end

	def ==(other)
   		return File.basename(self.ds[0]) == File.basename(other.ds[0]) && self.dstart[0] == other.dstart[0] && self.dend[0] == other.dend[0] && File.basename(self.hs[0]) == File.basename(other.hs[0]) && self.hstart[0] == other.hstart[0] && self.hend[0] == other.hend[0]
  	end

end ##end of class
