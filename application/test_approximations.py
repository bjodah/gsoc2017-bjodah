# -*- coding: utf-8 -*-
from __future__ import (absolute_import, division, print_function)

from sympy import log, exp, Symbol, sin
from sympy.codegen.cfunctions import log2, exp2, expm1, log1p
from optimizations import optimize
from approximations import sum_approx, sin_approx


def test_sum_approx():
    x = Symbol('x')
    expr = 1 + x
    res = optimize(expr, [sum_approx], bounds={x: (-1e-20, 1e-20)})
    assert res - 1 == 0


def test_sin_approx():
    x = Symbol('x')
    expr1 = 1 + sin(x)
    approx1 = optimize(expr1, [sin_approx], bounds={x: (-.1, .1)}, reltol=1e-10, abstol=1e-10)
    assert approx1 == 1 + x - x**3/6 + x**5/120
