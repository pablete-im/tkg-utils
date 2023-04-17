#!/bin/bash

input=$1
to_skip=$2

cp $to_skip SKIPS_$to_skip

while IFS= read -r line
do

  if grep -q "$line" SKIPS_$to_skip; then
    echo "Can't delete image $line, skipping..."
    sed -i "s%$line%#TOBESKIPPED $line%g" SKIPS_$to_skip 
  fi

done < "$input"