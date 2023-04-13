#!/bin/bash

cd tweets
for n in {1..200};
do
    cat part_$n.txt | grep \r\nEveryone\'s
done