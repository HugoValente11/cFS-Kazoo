#!/usr/bin/env python3
import sys

timeout = 5

binary_native = [
    "work/binaries/x86_partition"
    ]

binary_leon = [
    "taste-simulate-leon3 work.leon3/binaries/leon3_partition_leon3_rtems.exe"
    ]

expected_native = [
    ['[TASTE] Initialization completed for function Function2',
     '[TASTE] Initialization completed for function Function1'],
    'Send 0, got 1',
    'Send 1, got 2',
    'Send 2, got 3'
]

expected_leon = [
    'Send 0, got 1',
    'Send 1, got 2',
    'Send 2, got 3'
]

sys.path.append("..")
import commonRegression
result = commonRegression.test(binary_leon, expected_leon, timeout)
if result == 0:
    result = commonRegression.test(binary_native, expected_native, timeout)
sys.exit(result)
