#!/bin/bash
cp MSC_TestCase.msc work/binaries/user_GUI
cd work/binaries/user_GUI
taste-msc2py MSC_TestCase.msc
../demo &
PID=$!
echo $PID
python3 ./MSC_TestCase.py
RET=$?
kill $PID || exit 1
if [ "$RET" != "0" ]
then
    echo TEST CASE FAILED
    exit 1
else
    echo TEST CASE SUCCESS
    exit 0
fi
