from __future__ import (absolute_import, division, print_function)

from sympy import And, Gt, Lt, Abs, Dummy, oo, Tuple, cse
from sympy.codegen.ast import Assignment, AddAugmentedAssignment, CodeBlock

from printerdemo import (
    Declaration, PrintStatement, FunctionDefinition, While, Scope, ReturnStatement,
    Declaration, PrinterSetting, MyPrinter as CPrinter
)


def my_ccode(expr, **kwargs):
    return CPrinter(**kwargs).doprint(expr)


def newton_raphson_algorithm(expr, wrt, atol=1e-12, delta=None, debug=False,
                             itermax=None, counter=None):
    """
    See https://en.wikipedia.org/wiki/Newton%27s_method
    """
    if delta is None:
        delta = Dummy()
        Wrapper = Scope
        name_d = 'delta'
    else:
        Wrapper = lambda x: x
        name_d = delta.name

    delta_expr = -expr/expr.diff(wrt)
    body = [Assignment(delta, delta_expr), AddAugmentedAssignment(wrt, delta)]
    if debug:
        prnt = PrintStatement(r"{0}=%12.5g {1}=%12.5g\n".format(wrt.name, name_d), Tuple(wrt, delta))
        body = [body[0], prnt] + body[1:]
    if isinstance(atol, float) and atol < 0:
        atol = -atol*10**-PrinterSetting('precision')
    req = Gt(Abs(delta), atol)
    declars = [Declaration(delta, oo)]
    if itermax is not None:
        counter = counter or Dummy(integer=True)
        declars.append(Declaration(counter, 0))
        body.append(AddAugmentedAssignment(counter, 1))
        req = And(req, Lt(counter, itermax))
    whl = While(req, CodeBlock(*body))
    return Wrapper(CodeBlock(*declars, whl))


def newton_raphson_function(expr, wrt, func_name="newton", **kwargs):
    algo = newton_raphson_algorithm(expr, wrt, **kwargs)
    if isinstance(algo, Scope):
        algo, = algo.args
    return FunctionDefinition("real", func_name, (wrt,), CodeBlock(algo, ReturnStatement(wrt)))


def assign_cse(target, expr):
    cses, (new_expr,) = cse(expr)
    cse_declars = [Declaration(*args, const=True) for args in cses]
    return Scope(CodeBlock(*cse_declars, Assignment(target, new_expr)))
