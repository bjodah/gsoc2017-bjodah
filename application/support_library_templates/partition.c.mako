int sympy_partition_inplace(${real_type} * const arr, int n){
    int i = -1, j = n+1;
    const ${real_type} x = arr[n/2];
    while(1){
        i++;
        j--;
        while (arr[i] < x)
            i++;
        while (arr[j] > x)
            j--;
        if (i >= j)
            break;
        const ${real_type} tmp1 = arr[i];
        arr[i] = arr[j];
        arr[j] = tmp1;
    }
    return i;
}
