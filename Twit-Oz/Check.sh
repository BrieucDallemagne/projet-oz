#!/bin/bash
Quant=0

cd tweets
for n in {1..208};
do
    cat part_$n.txt | grep 'Ã'
    Val=$(cat part_$n.txt | wc --words)
    Quant=$(($Val + $Quant))
done
echo $Quant