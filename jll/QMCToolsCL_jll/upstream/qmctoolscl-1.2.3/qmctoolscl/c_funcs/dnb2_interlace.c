#include "qmctoolscl.h"

EXPORT void dnb2_interlace(
    // Interlace generating matrices or transpose of point sets to attain higher order digital nets in base 2
    const unsigned long long r, // replications
    const unsigned long long d_alpha, // dimension of resulting generating matrices 
    const unsigned long long mmax, // columns of generating matrices
    const unsigned long long bs_r, // batch size for replications
    const unsigned long long bs_d_alpha, // batch size for dimension of resulting generating matrices
    const unsigned long long bs_mmax, // batch size for replications
    const unsigned long long d, // dimension of original generating matrices
    const unsigned long long tmax, // bits in integers of original generating matrices
    const unsigned long long tmax_alpha, // bits in integers of resulting generating matrices
    const unsigned long long alpha, // interlacing factor
    const unsigned long long *C, // original generating matrices of size r*d*mmax
    unsigned long long *C_alpha // resulting interlaced generating matrices of size r*d_alpha*mmax
){
    unsigned long long l0 = 0*bs_r;
    unsigned long long j0_alpha = 0*bs_d_alpha;
    unsigned long long k0 = 0*bs_mmax;
    unsigned long long kk_max = (mmax-k0)<bs_mmax ? (mmax-k0):bs_mmax;
    unsigned long long jj_alpha_max = (d_alpha-j0_alpha)<bs_d_alpha ? (d_alpha-j0_alpha):bs_d_alpha;
    unsigned long long ll_max = (r-l0)<bs_r ? (r-l0):bs_r;
    unsigned long long ll,l,jj_alpha,j_alpha,kk,k,t_alpha,t,jj,j,v,b;
    unsigned long long bigone = 1;
    for(ll=0; ll<ll_max; ll++){
        l = l0+ll;
        for(jj_alpha=0; jj_alpha<jj_alpha_max; jj_alpha++){
            j_alpha = j0_alpha+jj_alpha;
             for(kk=0; kk<kk_max; kk++){
                k = k0+kk;
                v = 0;
                for(t_alpha=0; t_alpha<tmax_alpha; t_alpha++){
                    t = t_alpha / alpha; 
                    jj = t_alpha%alpha; 
                    j = j_alpha*alpha+jj;
                    b = (C[l*d*mmax+j*mmax+k]>>(tmax-t-1))&1;
                    if(b){
                        v += (bigone<<(tmax_alpha-t_alpha-1));
                    }
                }
                C_alpha[l*d_alpha*mmax+j_alpha*mmax+k] = v;
            }
        }
    }
}