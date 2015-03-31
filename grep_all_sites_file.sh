#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Please input a directory path"
    exit 1
fi

files=$1/*.sites.checked

for file in $files; do
    echo "$file starting."
    ./grep_shop.rb $file

    #remove processed file
    if [ $? = '0' ]; then
        rm $file
        echo "remove $file"
    fi

    echo "$file completed."
done

echo "All files completed."
