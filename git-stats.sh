#!/bin/bash 

# expects username as a first parameter
# from the logical point of view to calculate average commit time for n commits we 
# want to calculate the value: ((t2 - t1) + (t3 - t2) + ... + (tn - t{n-1})) / (n - 1)
# where ti is the time when commit #i was made
# Though, from the mathimatical point of view it's equal to (tn - t1) / (n - 1)
function get_average_commit_time {
	git log --all --committer="$1" --format='%ct' | 
	awk 	'BEGIN{last=0; first=0; inc=0} \
		{last=$1; \
		if (first == 0) \
			first=$1; \
		inc+=1} \
		END \
		{if (inc < 1) \
			ans=0; \
		else \
			ans = (first-last)/(inc - 1)/86400; \ 
		print ans}'
	# 86400 is a number of secons in 24 hours
}

# expects username as a first parameter
# returns string containing average numbers of inserts and deletes formatted as "%20f %20f".
function get_inserted_and_deleted_averages {
	git log --all --committer="$1" --pretty=tformat: --numstat | 
	awk 	'BEGIN{inserted=0; deleted=0; inc=0} \
		{inserted+=$1; deleted+=$2; inc+=1} \
		END \
		{if (inc != 0) {
			inserted=inserted/inc;
			deleted=deleted/inc; }
		printf "%25f %25f", inserted, deleted
		}'
}

# retrieves names of committers form the commit history and leaves unuque users
function get_list_of_committers {
	git log --all --format='%cN' | sort -u
}

# returns the list of commits for the current git repo in the chonological order 
function get_list_of_commits {
	git log --all --reverse --pretty=format:"%H"
}

# expects username as a first parameter 
function get_number_of_commits {
	git shortlog -scn | # result of this command has format "*number of commits* *username*"
	grep "^\s*[0-9]*\s*$1$" | # taking the line which corresponds to the proper user
	grep -Po "^\s*\K[0-9]*" 
}

# retrieves the number of lines in the current state of the repository from diff --shortstat call
function get_number_of_lines_in_repository {
	git diff --shortstat `git hash-object -t tree /dev/null` | 
	# `git hash-object -t tree /dev/null` -- hash, corresponding to an empty tree 
	# result of this command has format "X files changed, Y insertions(+)"
	grep -Po "[0-9]+[^0-9]+\K[0-9]*" # extracting second number in the line
}

saveIFS=$IFS
IFS=$'\n'
curdir="$PWD"
tmpdir=$(mktemp -d -p "$curdir")
if [ $? -ne 0 ]
then
	echo "Failed to create temporary directory. Aborting..."
	cleanup
	exit
fi
tmpfile=$(mktemp /tmp/git-stats.XXXXXX)
if [ $? -ne 0 ]
then
	echo "Failed to create temporary file. Aborting..."
	cleanup
	exit
fi

function cleanup {
	rm -rf "$tmpdir"
	rm "$tmpfile"
	IFS=$saveIFS
	cd "$curdir"
}

if [ "$1" == "--help" ]
then
	usage="usage: git-stats.sh  [--help] | REPOSITORY [GRAPH_DESTINATION]\n
		--help to see this message.\n
		REPOSITORY \t\tis a name of the git repository that will be analysed.\n
		GRAPH_DESTINATION \tif specified is a path where stats graph will be saved to. Otherwise file "graph.pdf" will be created in the current directory.\n"
	echo -ne $usage	
	cleanup
	exit
fi

graph_file="$2"

if [ "$2" == "" ]
then
	graph_file="graph.pdf"
fi

cd "$tmpdir"
echo "Cloning repository..."
git clone -q --progress "$1"
if [ $? -ne 0 ]
then
	echo "Failed to clone repository. Aborting..."
	cleanup	
	exit
fi

cd *
echo "Generating graph. It may take some time..."

counter=0
for commit in $(get_list_of_commits)
do
	git checkout -q $commit
	echo "$counter $(get_number_of_lines_in_repository)" >> "$tmpfile"
	counter=$((counter+1))
	echo -ne "$counter commits were processed\r"
done

gnuplot -e " \
		set term postscript enh color eps; \
		set autoscale; \
		set xlabel \"Commits\"; \
		set ylabel \"Lines of code\"; \
		plot  \"$tmpfile\" title 'Lines in repository' with lines; \
		exit" > "$graph_file"

cp "$graph_file" ".."
cd ..
cp "$graph_file" ".."
rm "$graph_file"
cd *

echo -e "DONE. You can find the graph in \e[4m$graph_file\e[0m file."
echo "Generating authors statistics table..."

# table header
printf 	"%25s %25s %25s %25s %25s\n\n" \
	"Committer" \
	"Number of commits" \
	"Avg commit time(in days)" \
	"Avg inserts(per commit)" \
	"Avg deletes(per commit)"

for committer in $(get_list_of_committers)
do
	printf "%25s %25s %25s %25s\n" "$committer" \
	"$(get_number_of_commits $committer)" \
	"$(get_average_commit_time $committer)" \
	"$(get_inserted_and_deleted_averages $committer)";
done

cleanup
echo "Done."
