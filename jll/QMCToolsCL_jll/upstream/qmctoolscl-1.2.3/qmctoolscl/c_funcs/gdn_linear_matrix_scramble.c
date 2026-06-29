#include "qmctoolscl.h"

EXPORT void gdn_linear_matrix_scramble(
    // Linear matrix scramble for generalized digital net 
    const unsigned long long r, // replications 
    const unsigned long long d, // dimension 
    const unsigned long long mmax, // columns in each generating matrix
    const unsigned long long bs_r, // batch size for replications
    const unsigned long long bs_d, // batch size for dimension
    const unsigned long long bs_mmax, // batch size columns
    const unsigned long long r_C, // number of replications of C 
    const unsigned long long r_b, // number of replications of bases
    const unsigned long long tmax, // number of rows in each generating matrix 
    const unsigned long long tmax_new, // new number of rows in each generating matrix 
    const unsigned long long *bases, // bases for each dimension of size r*d 
    const unsigned long long *S, // scramble matrices of size r*d*tmax_new*tmax
    const unsigned long long *C, // generating matrices of size r_C*d*mmax*tmax 
    unsigned long long *C_lms // new generating matrices of size r*d*mmax*tmax_new
){
    unsigned long long l0 = 0*bs_r;
    unsigned long long j0 = 0*bs_d;
    unsigned long long k0 = 0*bs_mmax;
    unsigned long long kk_max = (mmax-k0)<bs_mmax ? (mmax-k0):bs_mmax;
    unsigned long long jj_max = (d-j0)<bs_d ? (d-j0):bs_d;
    unsigned long long ll_max = (r-l0)<bs_r ? (r-l0):bs_r;
    unsigned long long ll,l,jj,j,kk,k,t,c,b,v,idx_C,idx_C_lms,idx_S; 
    for(ll=0; ll<ll_max; ll++){
        l = l0+ll;
        for(jj=0; jj<jj_max; jj++){
            j = j0+jj;
            b = bases[(l%r_b)*d+j];
            for(kk=0; kk<kk_max; kk++){
                k = k0+kk;
                idx_C = (l%r_C)*d*mmax*tmax+j*mmax*tmax+k*tmax;
                idx_C_lms = l*d*mmax*tmax_new+j*mmax*tmax_new+k*tmax_new;
                for(t=0; t<tmax_new; t++){
                    v = 0;
                    idx_S = l*d*tmax_new*tmax+j*tmax_new*tmax+t*tmax;
                    for(c=0; c<tmax; c++){
                        v += (S[idx_S+c]*C[idx_C+c])%b;
                    }
                    C_lms[idx_C_lms+t] = v;
                }
            }
        }
    }
}