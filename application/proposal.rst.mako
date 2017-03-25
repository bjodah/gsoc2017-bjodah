GSoC 2017 Application Björn Dahlgren
====================================

Finite precision arithmetics
----------------------------
Consider the following code:

.. code:: python

   >>> import sympy as sp
   >>> x, y = sp.symbols('x y')
   >>> expr = sp.exp(x) + sp.exp(y)
   >>> ccode(expr)
   'exp(x) + exp(y)'

If we have *a priori* knowledge about the magnitudes of the variables we
could generate code that is more efficient and gives the same results.
Here is a mock up of what a smart code printer could do:

.. code:: python

   >>> sp.smart_ccode(expr, knowledge={sp.Gt(x + log(1e-10), y)}, precision='binary64')  # doctest: +SKIP
   'exp(x) + exp(y)'
   >>> sp.smart_ccode(expr, knowledge={sp.Gt(x + log(1e-10), y)}, precision='binary32')  # doctest: +SKIP
   'exp(x)'

above the smart code printer would use the fact that IEEE 754 binary64
and binary32 have machine epsilon values of 2:sup:`-53` and 2:sup:`-24` in order
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

   >>> sp.smart_ccode(2**x + log(x)/log(2))
   'exp2(x) + log2(x)'

here the C-code printer would use the `exp2` and `log2` functions from
the C99 standard. Some transformations would only be beneficial if
the magnitude of the variables are within some span, *e.g.*: 

   >>> smart_ccode((2*exp(x) - 2)*(3*exp(y) - 3), typically={x: And(-.1 < x, x < .1)})
   '6*expm1(x)*(exp(y) - 1)'
