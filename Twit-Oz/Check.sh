#!/bin/bash
Quant=0

cd tweets
for n in {1..200};
do
    cat part_$n.txt | grep \r\nEveryone\'s
    Val=$(cat part_$n.txt | wc --words)
    Quant=$(($Val + $Quant))
done
echo $Quant