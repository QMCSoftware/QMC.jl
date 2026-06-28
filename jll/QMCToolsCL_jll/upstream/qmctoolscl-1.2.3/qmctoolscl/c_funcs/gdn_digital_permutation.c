#include "qmctoolscl.h"

EXPORT void gdn_digital_permutation(
    // Permutation of digits for a generalized digital net
    const unsigned long long r, // replications
    const unsigned long long n, // points
    const unsigned long long d, // dimension
    const unsigned long long bs_r, // batch size for replications
    const unsigned long long bs_n, // batch size for points
    const unsigned long long bs_d, // batch size for dimension
    const unsigned long long r_x, // replications of xdig
    const unsigned long long r_b, // replications of bases
    const unsigned long long tmax, // rows of each generating matrix
    const unsigned long long tmax_new, // rows of each new generating matrix
    const unsigned long long bmax, // common permutation size, typically the maximum basis
    const unsigned long long *perms, // permutations of size r*d*tmax_new*bmax
    const unsigned long long *xdig, // binary digital net points of size r_x*n*d*tmax
    unsigned long long *xdig_new // float digital net points of size r*n*d*tmax_new
){
    unsigned long long l0 = 0*bs_r;
    unsigned long long i0 = 0*bs_n;
    unsigned long long j0 = 0*bs_d;
    unsigned long long ii_max = (n-i0)<bs_n ? (n-i0):bs_n;
    unsigned long long jj_max = (d-j0)<bs_d ? (d-j0):bs_d;
    unsigned long long ll_max = (r-l0)<bs_r ? (r-l0):bs_r;
    unsigned long long ll,l,ii,i,jj,j,t,idx_xdig,idx_xdig_new,idx_perm,p;
    for(ll=0; ll<ll_max; ll++){
        l = l0+ll;
        for(ii=0; ii<ii_max; ii++){
            i = i0+ii;
            for(jj=0; jj<jj_max; jj++){
                j = j0+jj;
                idx_xdig = (l%r_x)*n*d*tmax+i*d*tmax+j*tmax;
                idx_xdig_new = l*n*d*tmax_new+i*d*tmax_new+j*tmax_new;
                idx_perm = l*d*tmax_new*bmax+j*tmax_new*bmax;
                for(t=0; t<tmax; t++){
                    p = xdig[idx_xdig+t];
                    xdig_new[idx_xdig_new+t] = perms[idx_perm+t*bmax+p];
                }
                for(t=tmax; t<tmax_new; t++){
                    xdig_new[idx_xdig_new+t] = perms[idx_perm+t*bmax]; // index 0 of the permutation 
                }
            }
        }
    }
}
