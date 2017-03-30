void sympy_quicksort_inplace(${real_type} * const arr, int n){
    if (n > 1){
        const int i = partition_inplace(arr, n);
        sympy_quicksort_inplace(arr, i);
        sympy_quicksort_inplace(arr + i, n - i);
    }
}
