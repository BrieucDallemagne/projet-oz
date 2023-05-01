#!/bin/bash
Quant=0

cd tweets
for n in {1..208};
do
    echo $n
    cat part_$n.txt | grep 'The Apprentice will be on Thursdays '
    Val=$(cat part_$n.txt | wc --words)
    Quant=$(($Val + $Quant))
done
echo $Quant