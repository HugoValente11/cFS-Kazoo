#!/usr/bin/env python3
import sys

timeout = 12

binaries = [
    "work/binaries/x86_partition"
    ]

expected = [
    ['[TASTE] Initialization completed for function Function1',
     '[TASTE] Initialization completed for function Function2'],
    'OP 0',
    'OP 0'
]

sys.path.append("..")
import commonRegression
result = commonRegression.test(binaries, expected, timeout)
sys.exit(result)
