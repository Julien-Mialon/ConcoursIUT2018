#!/bin/bash

arr=(0 1 2 3 4 5 6)

echo ${arr[0]}
echo ${arr[1]}

arr[12]=42

arr[1]=8

echo ${arr[1]}

echo ${arr[12]}

echo "#"${arr[91]}"#"