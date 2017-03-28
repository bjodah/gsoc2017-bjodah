#!/bin/bash
function get_assembly() {
    gcc -O0 -S -x c -o - - <<EOF
#include <math.h>
double f() { return $1; }
EOF
}
result_pow=$(get_assembly "pow(10, 1 - 15)")
result_literal=$(get_assembly "1e-14")
diff <(echo $result_pow) <(echo $result_literal)
echo $?
