# -*- coding: utf-8 -*-
from __future__ import (absolute_import, division, print_function)

from sympy import log, exp, Symbol
from sympy.codegen.cfunctions import log2, exp2, expm1, log1p
from approximations import approx


def test_approx():
    x = Symbol('x')
    expr = 1 + x
    res = approx(expr, {x: (-1e-20, 1e-20)})
    assert res - 1 == 0
