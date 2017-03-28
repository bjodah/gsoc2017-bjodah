.. ${'{0} eval: (read-only-mode) {0}'.format('-*-')}

Improved code-generation facilities
===================================

.. contents::

About me
--------

+---------------+----------------------------------------------------------------+
|Name           |Björn Dahlgren                                                  |
+---------------+----------------------------------------------------------------+
|Email          |`bjodah@gmail.com <bjodah@gmail.com>`_                          |
+---------------+----------------------------------------------------------------+
|University     |`KTH Royal Institute of Technology <http://www.kth.se>`_,       |
|               |Stockholm, Sweden                                               |
+---------------+----------------------------------------------------------------+
|Program        |PhD-student, project: Modelling interfacial radiation chemistry |
+---------------+----------------------------------------------------------------+
|Blog           |`<https://bjodah.github.io>`_                                   |
+---------------+----------------------------------------------------------------+
|Github profile |`<https://www.github.com/bjodah>`_                              |
+---------------+----------------------------------------------------------------+
|Time-zone      |UTC+01:00                                                       |
+---------------+----------------------------------------------------------------+
|Phone          |Will be provided upon request                                   |
+---------------+----------------------------------------------------------------+

Background
~~~~~~~~~~
I am a PhD student in my final year. I have a MSc in Chemical Science and
Engineering which included courses in numerical methods and scientific
programming. I am proficient with Python/C/C++/Fortran and have a
general interest in scientific computing. My preferred development
environment is Emacs under Linux using git.

Earlier contributions
~~~~~~~~~~~~~~~~~~~~~
I have been an active contributor to SymPy since about 3 years with
`35 pull-requestes <https://github.com/sympy/sympy/pulls/bjodah>`_
(of which 25 have been merged) for SymPy (*e.g.* a `C++ code printer
<https://github.com/sympy/sympy/pull/11637>`_), 
`a handful <https://github.com/sympy/sympy_benchmarks/pulls/bjodah>`_
for ``sympy_benchmarks``,
`one <https://https://github.com/symengine/symengine/pull/1075>`_
for SymEngine and `a few
<https://github.com/symengine/symengine.py/pulls/bjodah>`_
for the Python wrappers for SymEngine. I'm also the author of two
open-source python libraries with a general audience which use SymPy 
as their primary backend for solving `initial value problems
<https://en.wikipedia.org/wiki/Initial_value_problem>`_ (IVPs) for 
`systems of ordinary differential equations (ODE systems)
<https://en.wikipedia.org/wiki/Ordinary_differential_equation#System_of_ODEs>`_
and systems of nonlinear equations respectively (`example
<https://en.wikipedia.org/wiki/Gradient_descent#Solution_of_a_non-linear_system>`_): 

- `pyodesys`_: Solving IVPs for systems of ODEs
- `pyneqsys`_: Solving (possibly overdetermined) noninear systems by optimization.

I have been using SymPy to do code-generation in various domain
specific projects: 

- `ChemPy <https://github.com/bjodah/chempy>`_: solving chemical equilibria
  and kinetics using `pyodesys`_ & `pyneqsys`_
- `mdiosvcor <https://github.com/bjodah/mdiosvcor>`_ - Molecular
  Dynamics Ion Solvation Correction terms (using a `patched version`_ of
  ``sympy.utilities.autowrap``)
- `fastinverse <https://github.com/bjodah/fastinverse>`_: using
  `pycodeexport <https://github.com/bjodah/pycodeexport>`_ (which uses
  SymPy) and `pycompilation <https://github.com/bjodah/pycompilation>`_
- `cInterpol <https://github.com/bjodah/cinterpol>`_: library for fast
  polynomial interpolation where the formulae are derived
  using ``sympy.solve`` during the code-generation phase.

.. _pyodesys: https://github.com/bjodah/pyodesys
.. _pyneqsys: https://github.com/bjodah/pyneqsys
.. _patched version: https://github.com/bjodah/mdiosvcor/blob/master/mdiosvcor/mod_autowrap.py

Time commitment
~~~~~~~~~~~~~~~
If accepted, I will have no other commitments, meaning that I will be
avaiable at least 40 h/week during the program. Any shorter vaccation
will, in addition to being coordinated with the mentor, be compensated
in advance e.g. by working 50 h/week during 4 weeks leading up to 1
week of vaccation. I will hopefully spend one week at the SciPy 2017
conference, in which case I will help out teaching in a tutorial on
using ``SymPy``'s code-generation facilities, and participate in
code-sprints. This time will therefore go directly into the project.

Synopsis
--------
The code-generation facilities in SymPy are already in active use in
the research community. There are, however, still many great
opportunities for further improvements. As a CAS, SymPy has access to
far more information than a compiler processing typical source code in
languages such C/C++/Fortran. SymPy uses arbitrary precision
arithmetics which avoids problems such as overflow (integer and
floating point), loss of significance *etc.* High performance code
relies on `floating-point arithmetic
<https://en.wikipedia.org/wiki/Floating-point_arithmetic>`_ (which has
`dedicated hardwarde
<https://en.wikipedia.org/wiki/Floating-point_unit>`_ in modern CPUs),
therefore, any code generation for a programming language which maps
mathematical expressions to finite precision floating point
instructions, would benefit greatly if that code-generation was made
in such a way to minimize `precision loss
<https://en.wikipedia.org/wiki/Loss_of_significance>`_, risk of
under-/overflow *etc.*

The current code-generation facilities are spread out over:

- ``CodePrinter`` and its subclasses in the ``sympy.printing``
  subpackage
- ``CodeGen`` and its related classes in ``sympy.utilities.codegen``.
- Types for abstract syntax tree (AST) generation in
  ``sympy.codegen.ast`` and related langauge specific types in
  ``sympy.codegen.cfunctions`` and ``sympy.codegen.ffunctions`` (for C-
  and Fortran-functions respectively).

Ideally the ``CodePrinter`` subclasses should only deal with
expressing the AST types as valid code in their respective languages.
Any re-ordering of expressions or transformations from one node type
to another should be performed by other classes prior to reaching the
printers.

Code printers
-------------
SymPy has facilities for generating code in other programming
languages. Especially in statically typed compiled languages which
offer considerable performance advantages compared to pure Python.

Current status
~~~~~~~~~~~~~~
Currently the code printers in the language specific modules under
``sympy.printing`` are geard towards generating inline expressions,
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
is that there is a special case to handle ``Piecewise`` in the printing of
``Assignment``. This approach fails when we want to print nested
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
case (this is working — but unpolished — code to convey the point):

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

A popular feature of SymPy is common subexpresison elimination (CSE),
currently the code printers are not catered to deal with these in an
optimal way. Consider e.g.: 

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

Currently the printers do not track what methods have been called.
It would be useful if C-code printers kept a per instance set of
header files (and libraries) needed, *e.g.*:

.. code:: python

   >>> from mockups import CPrinter
   >>> instance = CPrinter()
   >>> instance.doprint(x/(x+sp.pi))
   'x/(x + M_PI)'
   >>> print(instance.headers, instance.libraries)
   set() set()
   >>> instance.doprint(sp.Abs(x/(x+sp.pi)))
   'fabs(x/(x + M_PI))'
   >>> print(instance.headers, instance.libraries)
   {'math.h'} {'m'}

this would allow users to subclass the printers with methods using
functions from libraries outside the standard. Currently the user
would also have to subclass and modify ``CCodeGen`` if they wanted to
use those facilites. With the above behaviour (and neccesssary changes
to the code-generator in addition to the code-printer) that would no
longer be required.


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

compiling that expression as a C program (and inspecting for floating
point exceptions):

.. code:: C

   ${'   '.join(open("logsum.c").readlines())}


and running that:

.. code:: bash

   $ ./logsum
   ${'   '.join(open("logsum.out").readlines())}

illustrates the dangers of finite precision arithmetics.
In this particular case, the expression could be rewritten
as:

Timeline
--------
Below is a proposed schedule for the program.

Before GSoC 2017
~~~~~~~~~~~~~~~~
Since I have the privelige of being a prior contributor to the project
I am already familiar with the code-base and the parties interested in
code-generation in SymPy. I will therefore use the time during the
spring to general design (big picture structuring, API design) and
reading up on the details of finite precision arithmetics:

- `Higham, Accuracy and stability of numerical algorithms
  <https://books.google.se/books/about/Accuracy_and_Stability_of_Numerical_Algo.html?id=7J52J4GrsJkC&printsec=frontcover>`_,
  Chapter 27 in particular (and references therein).
- IEEE's `recommended reading <http://grouper.ieee.org/groups/754/>`_
  for the 754 standard.


Phase I, 2017-05-30 – 2017-06-30
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
This phase will be consisting of incremental additions and
improvements to mainly existing infrastructure in SymPy.

- Week 1:

  - Add new types to ``sympy.codegen.ast`` related to precision,
    e.g. ``Type`` ('float64', 'float32', *etc.*), ``Variable`` (type,
    name & constness), ``Declaration`` (wrapping ``Variable``).
  - New print methods in C99CodePrinter and FCodePrinter for printing
    ``Type`` & ``Declaration`` (mapping 'float64' to 'double'/'type(0d0)'
    in C/Fortran respectively).
  - Since these will be new types they could be merged as a PR by the
    end of week (perhaps marked as provisional to allow changing
    without deprecatation cycle if needed later during the program).

- Week 2:

  - Implement precision controlled printing in C99CodePrinter, e.g.:
    ``sinf``/``sin``/``sinl`` for all math functions in ``math.h``.
  - Implement per printer instance header and library tracking.
  - Implement precision controlled printing in FCodePrinter, e.g.:
    ``cmplx(re, im, kind)``.

- Week 3:

  - Add new types to ``sympy.codegen.ast`` related to program flow,
    *e.g.* ``While``, ``FunctionDefinition``, ``FunctionPrototype`` (for ``C``),
    ``ReturnStatement``, ``PrinterSetting``, *etc.*
  - Introduce a new module ``sympy.codegen.algorithms`` containing *e.g.*
    Newton's method, fixed point iteration, *etc.*

- Week 4:

  - A new ``CodeGen``-like class using the new AST types & updated
    printers.
  - Support for `pybind11 <https://github.com/pybind/pybind11>`_ in
    addition to ``Cython`` support.

- Week 5:

  - NIL
  - Hand-in evaluations of Phase I.

Phase II, 2017-07-01 – 2017-07-28
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
The second phase will focus on providing new functionality to deal
with rewriting of expressions to optimal forms when evaluated using
finite precision arithmetics. Note that is not only something that
SymPy's codeprinters could benefit from, but also the
``LLVMDoubleVisistor`` in SymEngine.

- Week 6:

  - NIL

- Week 6:

  - NIL

- Week 7:

  - NIL

- Week 8:

  - NIL

- Week 9

  - NIL

Phase III,  2017-07-29 – 2017-08-29
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Week 10

  - NIL

- Week 11

  - NIL

- Week 12

  - NIL

- Week 13

  - NIL


After GSoC
~~~~~~~~~~
I will resume my post-graduate studies and hopefully leverage the new
code-generation facilities in future applied research projects.
