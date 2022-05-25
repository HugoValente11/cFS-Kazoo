#!/bin/bash
cp MSC_ErrorCase.msc work/binaries/user_GUI
cd work/binaries/user_GUI
taste-msc2py MSC_ErrorCase.msc
../demo &
PID=$!
echo $PID
python3 ./MSC_ErrorCase.py
RET=$?
kill $PID || exit 1
if [ "$RET" != "0" ]
then
    echo TEST CASE FAILED AS EXPECTED
    exit 0
else
    echo TEST CASE SUCCEEDED BUT THIS IS NOT EXPECTED
    exit 1
fi
