#!/bin/sh
# Simple test runner with result archival in results git repository
# Usage:
#  ./runtests.sh -c    # wikitext -> HTML DOM tests and commit results
#  ./runtests.sh -r -c # round-trip tests; commit
#  ./runtests.sh       # wikitext -> HTML DOM; only show diff (no commit)
#  ./runtests.sh -r    # round-trip tests; only show diff (no commit)

# Helper function to echo a message to stderr
warn() {
	echo "$@" 1>&2
}

if [ ! -d results ];then
    git init results
    touch results/html.txt
    touch results/roundtrip.txt
    touch results/all.txt
    ( cd results;
      git add html.txt
      git add roundtrip.txt
      git add all.txt
      git commit -a -m 'init to empty test output' )
else
    ( cd results && git checkout -f )
fi

node=` ( nodejs --version > /dev/null 2>&1 && echo 'nodejs' ) || echo 'node' `

if [ "$1" = "--wt2wt" ];then
    time $node parserTests.js --cache --wt2wt \
        > results/roundtrip.txt 2>&1 || exit 1
elif [ "$1" = '--wt2html' ];then
    time $node parserTests.js --wt2html --cache --printwhitelist \
        > results/html.txt 2>&1 || exit 1
else
    time $node parserTests.js --wt2html --wt2wt --html2html --cache --printwhitelist \
        > results/all.txt 2>&1 || exit 1
fi

cd results || exit 1
if [ "$1" != '-c' -a "$2" != '-c' ];then
    git diff | less -R
else
    if [ "$1" = '--wt2wt' ];then
        git commit -a -m "`tail -8 roundtrip.txt`" || exit 1
    elif [ "$1" = '--wt2html' ];then
        git commit -a -m "`tail -8 html.txt`" || exit 1
    else
        git add all.txt
        git commit -m "`tail -10 all.txt`" all.txt || exit 1
    fi
    git diff HEAD~1 | less -R || exit 1
fi
