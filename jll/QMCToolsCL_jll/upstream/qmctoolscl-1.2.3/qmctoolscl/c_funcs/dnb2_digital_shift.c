#include "qmctoolscl.h"

EXPORT void dnb2_digital_shift(
    // Digital shift base 2 digital net 
    const unsigned long long r, // replications
    const unsigned long long n, // points
    const unsigned long long d, // dimension
    const unsigned long long bs_r, // batch size for replications
    const unsigned long long bs_n, // batch size for points
    const unsigned long long bs_d, // batch size for dimension
    const unsigned long long r_x, // replications of xb
    const unsigned long long *lshifts, // left shift applied to each element of xb
    const unsigned long long *xb, // binary base 2 digital net points of size r_x*n*d
    const unsigned long long *shiftsb, // digital shifts of size r*d
    unsigned long long *xrb // digital shifted digital net points of size r*n*d
){
    unsigned long long l0 = 0*bs_r;
    unsigned long long i0 = 0*bs_n;
    unsigned long long j0 = 0*bs_d;
    unsigned long long ii_max = (n-i0)<bs_n ? (n-i0):bs_n;
    unsigned long long jj_max = (d-j0)<bs_d ? (d-j0):bs_d;
    unsigned long long ll_max = (r-l0)<bs_r ? (r-l0):bs_r;
    unsigned long long ll,l,ii,i,jj,j,idx;
    unsigned long long nelem_x = r_x*n*d;
    for(ll=0; ll<ll_max; ll++){
        l = l0+ll;
        for(ii=0; ii<ii_max; ii++){
            i = i0+ii;
            for(jj=0; jj<jj_max; jj++){
                j = j0+jj;
                idx = l*n*d+i*d+j;
                xrb[idx] = (xb[(idx)%nelem_x]<<lshifts[l%r_x])^shiftsb[l*d+j];
            }
        }
    }
}
