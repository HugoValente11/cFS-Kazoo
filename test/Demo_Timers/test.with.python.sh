#!/bin/bash
if [ ! -d work/binaries/ ] ; then
	echo Build first - invoke make
	exit 1
fi
export ASSERT_IGNORE_GUI_ERRORS=1
cp testCase.py work/binaries/gui_GUI/
cd work/binaries/gui_GUI/
../demo &
python3 testCase.py
pkill demo
cd -
