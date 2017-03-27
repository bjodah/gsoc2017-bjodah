from mockups import newton_raphson

import sympy as sp
from pycompilation import compile_link_import_strings
from mockups import MyPrinter, newton_raphson_algorithm, newton_raphson_function, Type

def test_Type():
    t = Type
    t.__class__.__name__ == 'Type'


def test_newton_raphson_algorithm():
    x, dx, atol = sp.symbols('x dx atol')
    expr = sp.cos(x) - x**3
    algo = newton_raphson_algorithm(expr, x, dx, atol)
    assert algo.has(Assignment(dx, -expr/expr.diff(x)))


def test_newton_raphson_function():
    x = sp.Symbol('x')
    expr = sp.cos(x) - x**3
    func = newton_raphson_function(expr, x)
    mod = compile_link_import_strings([
        ('newton.c', ('#include <math.h>\n'
                      '#include <stdio.h>\n') + newton_c),
        ('_newton.pyx', ("cdef extern double newton(double)\n"
                         "def py_newton(x):\n"
                         "    return newton(x)\n"))
    ], std='c99')
    assert abs(mod.py_newton(0.5) - 0.865474033102) < 1e-12
