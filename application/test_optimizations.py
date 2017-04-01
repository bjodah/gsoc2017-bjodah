# -*- coding: utf-8 -*-
from __future__ import (absolute_import, division, print_function)

from sympy import log, exp, Symbol
from sympy.codegen.cfunctions import log2, exp2, expm1, log1p
from optimize import optimize, log2_opt, exp2_opt, expm1_opt, log1p_opt, optims_c99


def test_log2_opt():
    x = Symbol('x')
    expr1 = 7*log(3*x + 5)/(log(2))
    opt1 = optimize(expr1, [log2_opt])
    assert opt1 == 7*log2(3*x + 5)

    expr2 = 3*log(5*x + 7)/(13*log(2))
    opt2 = optimize(expr2, [log2_opt])
    assert opt2 == 3*log2(5*x + 7)/13

    expr3 = log(x)/log(2)
    opt3 = optimize(expr3, [log2_opt])
    assert opt3 == log2(x)

    expr4 = log(x)/log(2) + log(x+1)
    opt4 = optimize(expr4, [log2_opt])
    assert opt4 == log2(x) + log(2)*log2(x+1)

    expr5 = log(17)
    opt5 = optimize(expr5, [log2_opt])
    assert opt5 == expr5


def test_exp2_opt():
    x = Symbol('x')
    expr1 = 1 + 2**x
    opt1 = optimize(expr1, [exp2_opt])
    assert opt1 == 1 + exp2(x)

    expr2 = 1 + 3**x
    assert expr2 == optimize(expr2, [exp2_opt])

def test_expm1_opt():
    x = Symbol('x')

    expr1 = exp(x) - 1
    opt1 = optimize(expr1, [expm1_opt])
    assert expm1(x) - opt1 == 0

    expr2 = 3*exp(x) - 3
    opt2 = optimize(expr2, [expm1_opt])
    assert 3*expm1(x) == opt2

    expr3 = 3*exp(x) - 5
    assert expr3 == optimize(expr3, [expm1_opt])

    expr4 = 3*exp(x) + log(x) - 3
    opt4 = optimize(expr4, [expm1_opt])
    assert 3*expm1(x) + log(x) == opt4


def test_log1p_opt():
    x = Symbol('x')
    expr1 = log(x + 1)
    opt1 = optimize(expr1, [log1p_opt])
    assert log1p(x) - opt1 == 0
    expr2 = log(3*x + 3)
    opt2 = optimize(expr2, [log1p_opt])
    assert log1p(x) + log(3) == opt2


def test_optims_c99():
    x = Symbol('x')

    expr1 = 2**x + log(x)/log(2) + log(x + 1) + exp(x) - 1
    opt1 = optimize(expr1, optims_c99).simplify()
    assert opt1 == exp2(x) + log2(x) + log1p(x) + expm1(x)

    expr2 = log(x)/log(2) + log(x + 1)
    print()
    opt2 = optimize(expr2, optims_c99)
    assert opt2 == log2(x) + log1p(x)

    expr3 = log(x)/log(2) + log(17*x + 17)
    opt3 = optimize(expr3, optims_c99)
    delta3 = opt3 - (log2(x) + log(17) + log1p(x))
    assert delta3 == 0

    expr4 = 2**x + 3*log(5*x + 7)/(13*log(2)) + 11*exp(x) - 11 + log(17*x + 17)
    opt4 = optimize(expr4, optims_c99).simplify()
    delta4 = opt4 - (exp2(x) + 3*log2(5*x + 7)/13 + 11*expm1(x) + log(17) + log1p(x))
    assert delta4 == 0
