#include "qmctoolscl.h"

EXPORT void lat_gen_linear(
    // Lattice points in linear order
    const unsigned long long r, // replications
    const unsigned long long n, // points
    const unsigned long long d, // dimension
    const unsigned long long bs_r, // batch size for replications
    const unsigned long long bs_n, // batch size for points
    const unsigned long long bs_d, // batch size for dimension
    const unsigned long long *g, // pointer to generating vector of size r*d
    double *x // pointer to point storage of size r*n*d
){
    unsigned long long l0 = 0*bs_r;
    unsigned long long i0 = 0*bs_n;
    unsigned long long j0 = 0*bs_d;
    unsigned long long ii_max = (n-i0)<bs_n ? (n-i0):bs_n;
    unsigned long long jj_max = (d-j0)<bs_d ? (d-j0):bs_d;
    unsigned long long ll_max = (r-l0)<bs_r ? (r-l0):bs_r;
    double n_double = n;
    double ifrac;
    unsigned long long ll,l,ii,i,jj,j;
    for(ii=0; ii<ii_max; ii++){
        i = i0+ii;
        ifrac = i/n_double;
        for(jj=0; jj<jj_max; jj++){
            j = j0+jj;
            for(ll=0; ll<ll_max; ll++){
                l = l0+ll;
                x[l*n*d+i*d+j] = (double)(fmod((double)(g[l*d+j]*ifrac),(double)(1.)));
            }
        }
    }
}