#!/bin/bash

for n in {1..200};
do
    cat part_$n.txt | grep slower
done