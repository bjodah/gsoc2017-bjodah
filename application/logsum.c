#include <fenv.h>
#include <math.h>
#include <stdio.h>

void report_overflow() {
    if (fetestexcept(FE_OVERFLOW))
        printf("overflow reported\n");
}

int main(){
    feclearexcept(FE_ALL_EXCEPT);
    report_overflow();
    printf("%.5g\n", log(exp(800) + exp(-800)));
    report_overflow();
    return 0;
}
