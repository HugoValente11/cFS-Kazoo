#!/bin/bash


./work/binaries/partition1 & pid1=$!
./work/binaries/x86_partition & pid2=$!

function kill_binaries
{
	kill $pid1
	kill $pid2
}

trap "kill_binaries" SIGINT

wait $pid1 $pid2
