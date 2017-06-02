#! /usr/bin/env ruby

Repository_path = "--" # substitute -- with repository path.
Repo_type = "--" # substitute -- with either .git or .svn or .hg depends on repository type.
confidential_level = 95 
margine_of_error = 0.05
p_value = 0.5
name = "--" # substitute -- with repository name.

system ("./ManualStudy.rb #{Repository_path} #{Repo_type} #{confidential_level} #{margine_of_error} #{p_value} #{name}")

# example:
# Testing
#Repository_path = "/Users/arwa/Documents/Projects/iaextractor"  
#Repo_type = ".git"
#confidential_level = 95
#margine_of_error = 0.05
#p_value = 0.5
#name = "iaextractor"

