#!/usr/bin/env python
import sys

timeout = 5

binaries = [
    "work/binaries/demo" 
    ]

expected = [
        ["C++ : 2",
         "SDL :  3",
         "[TASTE] Initialization completed for function CppInstance",
         "[TASTE] Initialization completed for function AdaInstance",
         "[TASTE] Initialization completed for function SDLInstance"],
        ["Ada value :  1",
         "SDL (3) asked me to work"]
]

sys.path.append("..")
import commonRegression
result = commonRegression.test(binaries, expected, timeout)
sys.exit(result)
