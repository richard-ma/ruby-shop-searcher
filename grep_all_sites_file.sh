#!/bin/sh

SAVEIFS=$IFS
IFS='\n'

if [ $# -ne 1 ]; then
    echo "Please input a directory path"
    exit 1
fi

files=$1/*.sites.checked

for file in $files; do
    echo "$file starting."
    ./grep_shop.rb $file

    # remove processed file
    if [ $? = '0' ]; then
        rm $file
    fi

    echo "$file completed."
done

IFS=$SAVEIFS

echo "All files completed."
