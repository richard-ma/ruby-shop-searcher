#!/bin/sh

tempfile=/tmp/sites-temp-file

SAVEIFS=$IFS
IFS='\n'

if [ $# -ne 1 ]; then
    echo "Please input a directory path"
    exit 1
fi

files=$1/*.sites

for file in $files; do
    # sort and uniq
    sort "$file" | uniq > "$tempfile"

    # move back
    rm "$file"
    mv "$tempfile" "$file.checked"

    echo "$file completed."
done

IFS=$SAVEIFS

echo "All files completed."
