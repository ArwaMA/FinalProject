#! /usr/bin/env ruby

## Execution class. 
## This class will call the main class that does all the work. 
## Before executing, please type donor path (DonorPath), host path (HostPath), 
## NiCad-3.5 clone detection tool path (NiCadPath), the language used of the applications (Language), 
## donor application name (DonorName), host application name (HostName), donor repository type, host repository type,
## distance threshold, similarity threshold, clones line threshols, first constant, second constant, and third constant. 


DonorPath = "--" # substitute -- with absolute path
HostPath = "--" # substitute -- with absolute path
NiCadPath = "--" # substitute -- with absolute path
Type = "--" # type1, type2, type2c, type3-1, type3-2, type3-2c
Language = "--" # java, py, cs, or c
DonorName = "--" # substitute -- with donor application name
HostName = "--" # substitute -- with host application name
Donor_repo_type = "--" # substitute -- with repository type of donor application (.git, or .hg)
Host_repo_type = ".--" # substitute -- with repository type of host application
Distance_threshold = 5 ## Maximum distance allowed between to clones.
Host_similarity_threshold = 50 ## Minimum similarity accepted of each pair of commits.
Clones_lines_threshold = 500 ## Minimun number of lines.
Constant_1 = 30
Contant_2 = 15
Contant_3 = 12

%x{./transplantation.rb #{DonorPath} #{HostPath} #{NiCadPath} #{Type} #{Language} #{DonorName} #{HostName} #{Donor_repo_type} #{Host_repo_type} #{Distance_threshold} #{Host_similarity_threshold} #{Clones_lines_threshold} #{Constant_1} #{Contant_2} #{Contant_3}}

## example:
#DonorPath = "/Users/arwa/Documents/Projects/game-off-2012" 
#HostPath = "/Users/arwa/Documents/Projects/game-off-2013"
#NiCadPath = "/Users/arwa/Documents/NiCad-3.5"
#Type = "type3-2"
#Language = "cs"
#DonorName = "game-off-2012"
#HostName = "game-off-2013"
#Donor_repo_type = ".git"
#Host_repo_type = ".git"
#Distance_threshold = 10
#Host_similarity_threshold = 90
#Clones_lines_threshold = 500
#Constant_1 = 30
#Contant_2 = 15
#Contant_3 = 12
