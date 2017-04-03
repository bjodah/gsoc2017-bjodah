# -*- coding: utf-8 -*-
from __future__ import (absolute_import, division, print_function)

from sympy import log, exp, Symbol, sin, oo
from sympy.codegen.cfunctions import log2, exp2, expm1, log1p
from optimizations import optimize
from approximations import sum_approx, sin_approx


def test_sum_approx():
    x, y = map(Symbol, 'x y'.split())
    expr1 = 1 + x
    apx1 = optimize(expr1, [sum_approx], bounds={x: (-1e-20, 1e-20)})
    assert apx1 - 1 == 0

    expr2 = exp(x) + exp(y)
    apx2 = optimize(expr2, [sum_approx], bounds={x: (0, oo), y: (-oo, 0)}, reltol=1e-14)
    assert apx2 == exp(x) + exp(y)

    apx3 = optimize(expr2, [sum_approx], bounds={x: (0, oo), y: (-oo, -50)}, reltol=1e-14)
    assert apx3 == exp(x)


def test_sin_approx():
    x = Symbol('x')
    expr1 = 1 + sin(x)
    approx1 = optimize(expr1, [sin_approx], bounds={x: (-.1, .1)}, reltol=1e-10, abstol=1e-10)
    assert approx1 == 1 + x - x**3/6 + x**5/120
