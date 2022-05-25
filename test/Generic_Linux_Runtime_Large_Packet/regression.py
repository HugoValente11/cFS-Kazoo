#!/usr/bin/env python3
import sys

timeout = 12

binaries = [
    "./test_binaries.sh"
    ]

expected = [
    ['[TASTE] Initialization completed for function Actuator',
    '[TASTE] Initialization completed for function Controller'],
    'Controller - sending work',
    'Actuator - got work',
    'Actuator - result sent',
    'Controller - got result',
    'Controller - sending work',
    'Actuator - got work',
    'Actuator - result sent',
    'Controller - got result'
]

sys.path.append("..")
import commonRegression
result = commonRegression.test(binaries, expected, timeout)
sys.exit(result)
