GSoC 2017 - Better code printers
================================

.. contents::

Name and contact information
----------------------------
Björn Dahlgren
Email: `bjodah@gmail.com`_
Phone:
Blog: `bjodah.github.io`_

Code printers
-------------
SymPy has facilities for generating code in other programming
languages. Especially in statically typed compiled languages which
offer considerable performance advantages compared to pure Python.

Current status
~~~~~~~~~~~~~~
Currently the code printers in the language specific modules under
`sympy.printing` are geard towards generating inline expressions,
*e.g.*:

.. code:: python

   >>> import sympy as sp
   >>> x = sp.Symbol('x')
   >>> pw = sp.Piecewise((x, sp.Lt(x, 1), (x**2, True)
   >>> sp.ccode(pw)
   '(x < 1) ? x : pow(x, 2.0)`

this works because C has a ternary operator, however, for Fortran
earlier than Fortran 95 there is no ternary operator. The code printer
base class has a work-around implemented for this, when we give the
keyword argument ``assign_to`` the code printer can generate a
statement instead of an expression:

.. code:: python

   >>> y = sp.Symbol('y')
   >>> print(sp.fcode(pw, assign_to=y))
          if (x < 1)
              y = x
          else
              y = x**2
          end if

this in itself is not a problem, however the way it is implemented now
is that there is a special case to handle Piecewise in the printing of
`Assignment`. This approach fails when we want to print nested
statements (*e.g.* a loop with conditional exit containing an if-statement).

Proposed improvements
~~~~~~~~~~~~~~~~~~~~~
In ``sympy.codegen.ast`` there are building blocks for representing an
abstract syntax tree. Let's consider the Newton-Rhapson method as a
case:

.. code:: python

   >>> import sympy as sp
   >>> from sympy.codegen.ast import WhileLoop
   ...


Finite precision arithmetics
----------------------------
Consider the following code:

.. code:: python

   >>> import sympy as sp
   >>> x, y = sp.symbols('x y')
   >>> expr = sp.exp(x) + sp.exp(y)
   >>> sp.ccode(expr)
   'exp(x) + exp(y)'

If we have *a priori* knowledge about the magnitudes of the variables we
could generate code that is more efficient and gives the same results.
Here is a mock up of what a smart code printer could do:

.. code:: python

   >>> sp.smart_ccode(expr, knowledge={sp.Gt(x + log(1e-10), y)}, precision='binary64')  # doctest: +SKIP
   'exp(x) + exp(y)'
   >>> sp.smart_ccode(expr, knowledge={sp.Gt(x + log(1e-10), y)}, precision='binary32')  # doctest: +SKIP
   'exp(x)'

above the smart code printer would use the fact that `IEEE 754 <http://grouper.ieee.org/groups/754/>`_ binary64
and binary32 have machine epsilon values of :math:`2^{-53}` and :math:`2^{-24}` in order
to simplify the 32-bit version not to include the ``exp(y)`` term
(which would have no effect on the finite precision expression due to
shifting).

In many algortihms (especially iteraitve ones) a computationally
cheaper approximation of an expression often works just as well but
offers an opportunity for faster convergence saving both time and
energy.

Making the code printers aware of precision would not only allow for
approximative expressions, it would also allow for more correct
results by transforming the expression into its most precision
perserving form, consider *e.g.*:

.. code:: python

   >>> sp.smart_ccode(2**x + log(x)/log(2))  # doctest: +SKIP
   'exp2(x) + log2(x)'

here the C-code printer would use the ``exp2`` and ``log2`` functions from
the C99 standard. Some transformations would only be beneficial if
the magnitude of the variables are within some span, *e.g.*: 

.. code:: python

   >>> smart_ccode((2*exp(x) - 2)*(3*exp(y) - 3), typically={x: And(-.1 < x, x < .1)})  # doctest: +SKIP
   '6*expm1(x)*(exp(y) - 1)'

here the proposed printer would use `expm1
<http://en.cppreference.com/w/c/numeric/math/expm1>`_ from the C99
standard to avoid cancellation in the subtraction.