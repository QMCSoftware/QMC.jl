#include "qmctoolscl.h"

EXPORT void dnb2_linear_matrix_scramble(
    // Linear matrix scrambling for base 2 generating matrices
    const unsigned long long r, // replications
    const unsigned long long d, // dimension
    const unsigned long long mmax, // columns in each generating matrix 
    const unsigned long long bs_r, // batch size for replications
    const unsigned long long bs_d, // batch size for dimensions
    const unsigned long long bs_mmax, // batch size for columns
    const unsigned long long r_C, // original generating matrices
    const unsigned long long tmax_new, // bits in the integers of the resulting generating matrices
    const unsigned long long *S, // scrambling matrices of size r*d*tmax_new
    const unsigned long long *C, // original generating matrices of size r_C*d*mmax
    unsigned long long *C_lms // resulting generating matrices of size r*d*mmax
){
    unsigned long long l0 = 0*bs_r;
    unsigned long long j0 = 0*bs_d;
    unsigned long long k0 = 0*bs_mmax;
    unsigned long long kk_max = (mmax-k0)<bs_mmax ? (mmax-k0):bs_mmax;
    unsigned long long jj_max = (d-j0)<bs_d ? (d-j0):bs_d;
    unsigned long long ll_max = (r-l0)<bs_r ? (r-l0):bs_r;
    unsigned long long b,t,ll,l,jj,j,kk,k,u,v,udotv,vnew,idx;
    unsigned long long bigone = 1;
    unsigned long long nelemC = r_C*d*mmax;
    for(ll=0; ll<ll_max; ll++){
        l = l0+ll;
        for(jj=0; jj<jj_max; jj++){
            j = j0+jj;
            for(kk=0; kk<kk_max; kk++){
                k = k0+kk;
                idx = l*d*mmax+j*mmax+k;
                v = C[idx%nelemC];
                vnew = 0;
                for(t=0; t<tmax_new; t++){
                    u = S[l*d*tmax_new+j*tmax_new+t];
                    udotv = u&v;
                    // Brian Kernighan algorithm: https://www.geeksforgeeks.org/count-set-bits-in-an-integer/
                    b = 0;
                    while(udotv){
                        b += 1;
                        udotv &= (udotv-1);
                    }
                    if((b%2)==1){
                        vnew += bigone<<(tmax_new-t-1);
                    }
                }
                C_lms[idx] = vnew;
            }
        }
    }
}