GSoC 2017 - Improved code-generation facilities
===============================================

.. contents::

Name and contact information
----------------------------
Björn Dahlgren
Email: `<bjodah@gmail.com>`_
Phone: Will be provided upon request
Blog: `<https://bjodah.github.io>`_

Synopsis
--------
The code-generation facilities in SymPy are already in active use in
the research community [1], [2], [3]. There are, however, still many
great opportunities for further improvements. Since SymPy is a CAS it
has ... things that may be improved upon. being 

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
   >>> pw1 = sp.Piecewise((x, sp.Lt(x, 1)), (x**2, True))
   >>> print(sp.ccode(pw1))
   ((x < 1) ? (
      x
   )
   : (
      pow(x, 2)
   ))


this works because C has a ternary operator, however, for Fortran
earlier than Fortran 95 there is no ternary operator. The code printer
base class has a work-around implemented for this, when we give the
keyword argument ``assign_to`` the code printer can generate a
statement instead of an expression:

.. code:: python

   >>> y = sp.Symbol('y')
   >>> print(sp.fcode(pw1, assign_to=y))
         if (x < 1) then
            y = x
         else
            y = x**2
         end if


this in itself is not a problem, however the way it is implemented now
is that there is a special case to handle Piecewise in the printing of
`Assignment`. This approach fails when we want to print nested
statements (*e.g.* a loop with conditional exit containing an if-statement).

The module ``sympy.utilities.codegen`` currently offers the most complete
functionality to generate complete functions. Its design however does not
lend itself to easy extension through subclassing, *e.g.* the ``CodeGen.routine``
method does not use the visitor pattern, instead it handles different types
through ``if``-statements which makes it hard to use with expressions containing
user defined classes. Also the ``CCodeGen`` class hard-codes (at least in a
method which may be overloaded) what headers to include. The notion of types in
``sympy.utilities.codegen`` is also somewhat confusing (there is no easy way
to use the binary32 IEEE 754 floating point data type for example).

Proposed improvements
~~~~~~~~~~~~~~~~~~~~~
In ``sympy.codegen.ast`` there are building blocks for representing an
abstract syntax tree. This module should be extended by adding more node
types. It would allow the either the current ``codegen`` facilities to gradually
be migrated to use the ``sympy.codegen.ast`` module or (if backward incompatiblity
issues prove to be substantial) introduce a new codeprinter using these facilities.

A new module: ``sympy.codegen.algorithms``, should be created, containg common algorithms
which are often rewritten today in every new project. This module would leverage the to-be-written
classes in ``sympy.codegen.ast``. Let's consider the Newton-Rhapson method as a
case (this is working --- but unpolished --- code to convey the point):

.. code:: python

   >>> from mockups import my_ccode, newton_raphson_algorithm
   >>> x, dx, atol = sp.symbols('x dx atol')
   >>> expr = sp.cos(x) - x**3
   >>> algo = newton_raphson_algorithm(expr, x, atol, dx)
   >>> print(my_ccode(algo))
   double dx = INFINITY;
   while (fabs(dx) > atol) {
      dx = (pow(x, 3) - cos(x))/(-3*pow(x, 2) - sin(x));
      x += dx;
   }

this and related algorithms, for example (modifed) newton method for non-linear systems
could be of great value for users writing applied code.

A popular[sumpy,pycalphad] feature of SymPy is common subexpresison
elimination (CSE), currently the code printers are not catered to deal
with these in an optimal way. Consider e.g.:

.. code:: python

   >>> pw2 = sp.Piecewise((2/(x + 1), sp.Lt(x, 1)), (sp.exp(1-x), True))
   >>> cses, (new_expr,) = sp.cse(pw1 + pw2)
   >>> print(cses)
   [(x0, x < 1)]

Currently the codeprinters don't know how to properly deal with
booleans, this should be improved so that codeblocks can be generated
where cse variables have their type deteremined automatically:

.. code:: python

   >>> from mockups import assign_cse
   >>> print(my_ccode(assign_cse(y, pw1 + pw2)))
   {
      const _Bool x0 = x < 1;
      y = ((x0) ? (
         x
      )
      : (
         pow(x, 2)
      )) + ((x0) ? (
         2/(x + 1)
      )
      : (
         exp(-x + 1)
      ));
   }
   
note that when using ``C++11`` as target language we may choose to
declare CSE variables ``auto`` which leaves type-deduction to the
compiler.


Finite precision arithmetics
----------------------------
Currently there is only rudimentary facilities to deal with precision in the codeprinters
(the current implementation essentially only deals with the number of decimals printed for
number constants). The new ```sympy.codegen.algorithms``` modeule should leave the decision
of requires precision to the user, revisiting the ``newton_raphson_algorithm`` example:

.. code:: python

   >>> print(my_ccode(algo, settings={'precision': 7}))
   float dx = INFINITY;
   while (fabsf(dx) > atol) {
      dx = (powf(x, 3) - cosf(x))/(-3*powf(x, 2) - sinf(x));
      x += dx;
   }

Note how our lowered precision affected what function calls that were generated (``fabsf``,
``powf``, ``cosf`` & ``sinf``). It should be noted that ``C++`` already allows the user to
write type-generic code, but still today all platforms support ``C++``, and for those platforms
the conveninece of generating code based precision can greatly reduce the manual labour of
rewriting the expressions. The magnitude for the choice of atol inherently depends on
the machine epsilon for the underlying data type, it would therefore
be convinient if there existed a node type which can reference the the
printer settings:

.. code:: python

   >>> from mockups import PrinterSetting
   >>> prec = PrinterSetting('precision')
   >>> algo2 = newton_raphson_algorithm(expr, x, atol=10**(1-prec), delta=dx)
   >>> print(my_ccode(algo2, settings={'precision': 15}))
   double dx = INFINITY;
   while (fabs(dx) > pow(10, 1 - 15)) {
      dx = (pow(x, 3) - cos(x))/(-3*pow(x, 2) - sin(x));
      x += dx;
   }


Making the code printers aware of precision would also allow for for
more correct results by transforming the expression into its most
precision perserving form, consider *e.g.*:

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

   >>> knol = {sp.Gt(x + sp.log(1e-10), y)}
   >>> sp.smart_ccode(expr, knowledge=knol, precision=15)  # doctest: +SKIP
   'exp(x) + exp(y)'
   >>> sp.smart_ccode(expr, knowledge=knol, precision=7)  # doctest: +SKIP
   'expf(x)'

above the smart code printer would use the fact that `IEEE 754
<http://grouper.ieee.org/groups/754/>`_ binary64 and binary32 have
machine epsilon values of :math:`2^{-53}` and :math:`2^{-24}` in order 
to simplify the 32-bit version not to include the ``exp(y)`` term
(which would have no effect on the finite precision expression due to
shifting). 

In many algortihms (especially iteraitve ones) a computationally
cheaper approximation of an expression often works just as well but
offers an opportunity for faster convergence saving both time and
energy.

A very common situtation in numerical codes is that the majority of
CPU cycles are spent solving linear systems of equations. For large
systems direct methods (*e.g.* LU decomposition) becomes prohibitively
expensive due to cubic algorithm complexity. The remedy is to rely on
iterative methods (*e.g.* GMRES), but these require good
preconditioners (unless the problem is notoriously diagonally
dominant). A good preconditioner can be constructed from an
approxiamtion of the inverse of the matrix describing the linear system.

A potentially very interesting idea would be to generate a
symbolic approximation of *e.g.* the LU decomposition of a matrix, and
when that approximate LU decomposition is sparse (in general sparse
matrices have dense LU decompositions due to fill-in), the
approximation could then be used to generate tailored preconditioners
based only on knowledge on expected magnitude of variables.

Another area of possible improvements is rewriting of expresisons to
avoid under-/over-flow, consider *e.g.*:

.. code:: python

   >>> logsum = sp.log(sp.exp(800) + sp.exp(-800))
   >>> str(logsum.evalf()).rstrip('0')
   '800.'

there are a few hundred of zeros before the second term makes
its presence known. The C code generated for the above expression
looks like this:

.. code:: python

   >>> print(sp.ccode(logsum))
   log(exp(-800) + exp(800))

compiling that expression as a C program:

.. code:: C

<%include file="logsum.c"/>


and running that:

   $ ./logsum
   <%include file="logsum.out"/>

illustrates the dangers of finite precision arithmetics.
In this particular case, the expression could be rewritten
as:
