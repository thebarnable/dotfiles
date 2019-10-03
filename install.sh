#!/bin/bash

SCRIPTPATH=$(dirname "$(realpath -s "$0")") # from https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself
INSTALLPATH=~/.test

# loop over input arguments by shifting
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -o|--output)
    INSTALLPATH=$2
    shift # shift key option (e.g. -o)
    shift # shift parameter after key
    ;;
esac
done

echo "Installing to $INSTALLPATH from $SCRIPTPATH"
mkdir -p $INSTALLPATH

for dir in $SCRIPTPATH/*/
do
    dir=${dir%*/} # remove trailing slash
    echo $dir
    ln -s $dir $INSTALLPATH/ 

    # TODOs:
    # - detect already existing config, user prompt to override it
done

