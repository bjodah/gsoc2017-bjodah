from __future__ import (absolute_import, division, print_function)

from sympy import cse
from sympy.core import AtomicExpr, Integer, S, Symbol
from sympy.tensor.indexed import IndexedBase
from sympy.core.basic import Basic
from sympy.codegen.ast import Assignment, CodeBlock

class While(Basic):
    """
    Examples
    --------
    >>> from sympy import symbols, Gt, Abs
    >>> from sympy.codegen import Assignment
    >>> x, dx = symbols('x dx')
    >>> expr = 1 - x**2
    >>> whl = While(Gt(Abs(dx), 1e-9), [
    ...     Assignment(dx, -expr/expr.diff(x)),
    ...     AddAugmentedAssignment(x, dx)
    ... ])

    """
    nargs = 2


class Scope(Basic):
    nargs = 1


class PrintStatement(Basic):
    """ (formatstring, Tuple)"""
    nargs = 2


class Type(Basic):
    """ a superset of NumPy naming, see https://docs.scipy.org/doc/numpy/user/basics.types.html

    Arguments
    ---------
    name : str
        Either an explicit type: intc, intp, int8, int16, int32, int64, uint8, uint16, uint32, uint64,
        float16, float32, float64, complex64, complex128, bool.
        Or only kind (precision decided by code-printer): real, integer

    """
    allowed_names = tuple('intc intp int8 int16 int32 int64 uint8 uint16 uint32'.split() +
                          'uint64 float16 float32 float64 complex64 complex128'.split() +
                          'real integer bool'.split())
    __slots__ = []

    def __new__(cls, name):
        if isinstance(name, Type):
            return name
        if name not in cls.allowed_names:
            raise ValueError("Unknown type: %s" % name)
        return Basic.__new__(cls, name)


def _type_from_expr(expr, symb=None):
    if symb is not None:
        if symb.is_integer:
            return Type('integer')
        elif symb.is_complex:
            return Type('complex')

    if isinstance(expr, str):
        return Type('real')  # default
    else:
        if isinstance(expr, (int, Integer)):
            return Type('integer')
        if isinstance(expr, Symbol) and expr.is_integer:
            return Type('integer')
        expr = S(expr)
        if expr.is_Relational:
            return Type('bool')
        else:
            return Type('real')


class Variable(Basic):
    """ name, type, constness """
    def __new__(cls, symbol, type_=None, const=False):
        if isinstance(symbol, Variable):
            return symbol
        if type_ is None:
            type_ = _type_from_expr(symbol)
        return Basic.__new__(cls, symbol, Type(type_), const)

    @property
    def symbol(self):
        return self.args[0]

    @property
    def type(self):
        return self.args[1]

    @property
    def const(self):
        return self.args[2]


class Pointer(Basic):
    """ name, type, value_const, pointer_const, restrict"""
    def __new__(cls, symbol, type_=None, value_const=False, pointer_const=False, restrict=False):
        if type_ is None:
            type_ = _type_from_expr(symbol)
        return Basic.__new__(cls, symbol, type_, value_const, pointer_const, restrict)

    @property
    def symbol(self):
        return self.args[0]

    @property
    def type(self):
        return self.args[1]

    @property
    def value_const(self):
        return self.args[2]

    @property
    def pointer_const(self):
        return self.args[3]

    @property
    def restrict(self):
        return self.args[4]



class Declaration(Basic):
    def __new__(cls, var, value=None, const=None):
        if isinstance(var, (Variable, Pointer)):
            if const is not None:
                raise ValueError("Cannot change constness of an existing Variable/Pointer")
        else:
            if value is not None:
                type_ = _type_from_expr(value, var)
            else:
                type_ = None

            if isinstance(var, IndexedBase):
                var = Pointer(var, type_, const)
            else:
                var = Variable(var, type_, const)

        return Basic.__new__(cls, var, value)


def assign_cse(target, expr):
    cses, (new_expr,) = cse(expr)
    cse_declars = [Declaration(*args, const=True) for args in cses]
    blck = cse_declars + [Assignment(target, new_expr)]
    return Scope(CodeBlock(*blck))


class FunctionDefinition(Basic):
    """ return_type, name, inputs, body """
    def __new__(cls, return_type, name, inputs, body):
        return Basic.__new__(cls, Type(return_type), name,
                             tuple(Declaration(inp) for inp in inputs), body)


class FunctionPrototype(Basic):
    """ return_type, name, input_types """
    @classmethod
    def from_FunctionDefinition(cls, func_def):
        return_type, name, inputs, body = func_def.args
        return cls(return_type, name, tuple(inp.type for inp in inputs))


class PrinterSetting(AtomicExpr):
    pass

class ReturnStatement(Basic):
    pass

class FunctionCall(Basic):
    """ name, args, statement """
    def __new__(cls, name, args=(), statement=False):
        return Basic.__new__(cls, name, args, statement)
