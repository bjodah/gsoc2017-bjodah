# -*- coding: utf-8 -*-
from __future__ import (absolute_import, division, print_function)


from symast import Type

def test_Type():
    t = Type
    t.__class__.__name__ == 'Type'
