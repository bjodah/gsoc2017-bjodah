# -*- coding: utf-8 -*-
from __future__ import (absolute_import, division, print_function)

from sympy import log, exp, Symbol
from sympy.codegen.cfunctions import log2, exp2
from optimize import optimize, optims_base2

def test_optims_base2():
    x = Symbol('x')
    expr = 1 + 2**x + log(3*x + 5)/(log(2))
    opt = optimize(expr, optims_base2)
    assert opt == 1 + exp2(x) + log2(3*x + 5)
