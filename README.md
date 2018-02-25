# Git Stats
## Description
Very simple command-line programm to get such statistics about git repository as: graph showing dependency of number of lines of code on number of commits, simple statistics about the committer: number of commits made, average committing time, average number of insertions/deletions per commit.
## Requirements
In order to execute successfully, it requires git and gnuplot to be installed:
	
	sudo apt-get install git
	sudo apt-get install gnuplot

## Usage
	usage: git-stats.sh  [--help] | REPOSITORY [GRAPH_DESTINATION]
		--help to see this message.
		REPOSITORY \t\tis a name of the git repository that will be analysed.
		GRAPH_DESTINATION \tif specified is a path where stats graph will be saved to. Otherwise file "graph.pdf" will be created in the current directory.

## Example
	./git-stats.sh https://github.com/annikura/git-stats.git my-graph
