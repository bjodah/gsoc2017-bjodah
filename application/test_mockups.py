from __future__ import (absolute_import, division, print_function)

import pytest
import sympy as sp
from sympy.codegen.ast import Assignment
from pycompilation import compile_link_import_strings
from printerdemo import MyPrinter, Type
from mockups import newton_raphson_algorithm, newton_raphson_function

def test_Type():
    t = Type
    t.__class__.__name__ == 'Type'


def test_newton_raphson_algorithm():
    x, dx, atol = sp.symbols('x dx atol')
    expr = sp.cos(x) - x**3
    algo = newton_raphson_algorithm(expr, x, atol, dx)
    assert algo.has(Assignment(dx, -expr/expr.diff(x)))


def test_newton_raphson_function():
    x = sp.Symbol('x')
    expr = sp.cos(x) - x**3
    func = newton_raphson_function(expr, x)
    mod = compile_link_import_strings([
        ('newton.c', ('#include <math.h>\n'
                      '#include <stdio.h>\n') + MyPrinter().doprint(func)),
        ('_newton.pyx', ("cdef extern double newton(double)\n"
                         "def py_newton(x):\n"
                         "    return newton(x)\n"))
    ], std='c99')
    assert abs(mod.py_newton(0.5) - 0.865474033102) < 1e-12


def test_newton_raphson_function_parameters():
    args = x, A, k, p = sp.symbols('x A k p')
    expr = A*sp.cos(k*x) - p*x**3
    with pytest.raises(ValueError):
        newton_raphson_function(expr, x)
    func = newton_raphson_function(expr, x, args)
    mod = compile_link_import_strings([
        ('newton.c', ('#include <math.h>\n'
                      '#include <stdio.h>\n') + MyPrinter().doprint(func)),
        ('_newton.pyx', ("cdef extern double newton(double, double, double, double)\n"
                         "def py_newton(x, A=1, k=1, p=1):\n"
                         "    return newton(x, A, k, p)\n"))
    ], std='c99')
    assert abs(mod.py_newton(0.5) - 0.865474033102) < 1e-12
