#include <fenv.h>
#include <math.h>
#include <stdio.h>

int main(){
    feclearexcept(FE_ALL_EXCEPT);
    printf("%d\n", fetestexcept(FE_OVERFLOW));
    printf("%.5g\n", log(exp(800) + exp(-800)));
    printf("%d\n", fetestexcept(FE_OVERFLOW));
    return 0;
}
