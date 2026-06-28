#include "qmctoolscl.h"

EXPORT void gdn_integer_to_float(
    // Convert digits of generalized digital net to floats
    const unsigned long long r, // replications
    const unsigned long long n, // points
    const unsigned long long d, // dimension
    const unsigned long long bs_r, // batch size for replications
    const unsigned long long bs_n, // batch size for points
    const unsigned long long bs_d, // batch size for dimension
    const unsigned long long r_b, // replications of bases 
    const unsigned long long tmax, // rows of each generating matrix
    const unsigned long long *bases, // bases for each dimension of size r_b*d
    const unsigned long long *xdig, // binary digital net points of size r*n*d*tmax
    double *x // float digital net points of size r*n*d
){
    unsigned long long l0 = 0*bs_r;
    unsigned long long i0 = 0*bs_n;
    unsigned long long j0 = 0*bs_d;
    unsigned long long ii_max = (n-i0)<bs_n ? (n-i0):bs_n;
    unsigned long long jj_max = (d-j0)<bs_d ? (d-j0):bs_d;
    unsigned long long ll_max = (r-l0)<bs_r ? (r-l0):bs_r;
    unsigned long long ll,l,ii,i,jj,j,t,idx_xdig;
    double recip,v,xdig_double,b;
    for(ll=0; ll<ll_max; ll++){
        l = l0+ll;
        for(ii=0; ii<ii_max; ii++){
            i = i0+ii;
            for(jj=0; jj<jj_max; jj++){
                j = j0+jj;
                idx_xdig = l*n*d*tmax+i*d*tmax+j*tmax;
                v = 0.;
                b = (double) bases[(l%r_b)*d+j];
                recip = 1/b;
                for(t=0; t<tmax; t++){
                    xdig_double = (double) (xdig[idx_xdig+t]);
                    v += recip*xdig_double;
                    recip /= b;
                }
                x[l*n*d+i*d+j] = v;
            }
        }
    }
}