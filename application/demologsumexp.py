# -*- coding: utf-8 -*-
from __future__ import (absolute_import, division, print_function)

from functools import reduce
from operator import add
from sympy import log, exp, Function, Symbol, IndexedBase, Add, Min, Max
from sympy.codegen.ast import CodeBlock, AddAugmentedAssignment
from sympy.codegen.cfunctions import log1p
from symast import FunctionCall, Declaration, While, ReturnStatement, FunctionDefinition

def logsumexp_naive(args):
    return log(reduce(add, map(exp, args)))


class logsumexp(Function):
    """ log(sum(exp(arg1) + exp(arg2) + ...)) """
    def _eval_rewrite_as_log(self, expr):
        return logsumexp_naive(expr.args)

    @staticmethod
    def as_FunctionDefinition(variables=None, name="logsumexp"):
        variables = variables or {}
        n = variables.get('n', Symbol('n', integer=True))
        i = variables.get('i', Symbol('i', integer=True))
        s = variables.get('s', Symbol('s'))
        x = variables.get('x', IndexedBase('x', shape=(n,)))
        body = CodeBlock(
            FunctionCall('sympy_quicksort', (x, n), statement=True),
            Declaration(i, 0),
            Declaration(s, 0.0),
            While(i < n-1, CodeBlock(
                AddAugmentedAssignment(s, exp(x[i])),
                AddAugmentedAssignment(i, 1)
            )),
            ReturnStatement(log1p(s) + x[n-1])
        )
        return FunctionDefinition("real", name, (x, n), body)
