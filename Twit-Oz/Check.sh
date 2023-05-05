#!/bin/bash
Quant=0

cd tweets
for n in {1..208};
do
    echo $n
    cat part_$n.txt | tr '[:upper:]' '[:lower:]' | grep 'congrats to'
    Val=$(cat part_$n.txt | wc --words)
    Quant=$(($Val + $Quant))
done
echo $Quant