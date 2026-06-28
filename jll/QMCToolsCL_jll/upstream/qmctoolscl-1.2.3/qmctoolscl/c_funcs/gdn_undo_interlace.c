#include "qmctoolscl.h"

EXPORT void gdn_undo_interlace(
    // Undo interlacing of generating matrices 
    const unsigned long long r, // replications
    const unsigned long long d, // dimension of resulting generating matrices 
    const unsigned long long mmax, // columns in generating matrices
    const unsigned long long bs_r, // batch size of replications
    const unsigned long long bs_d, // batch size of dimension of resulting generating matrices
    const unsigned long long bs_mmax, // batch size of columns in generating matrices
    const unsigned long long d_alpha, // dimension of interlaced generating matrices
    const unsigned long long tmax, // rows of original generating matrices
    const unsigned long long tmax_alpha, // rows of interlaced generating matrices
    const unsigned long long alpha, // interlacing factor
    const unsigned long long *C_alpha, // interlaced generating matrices of size r*d_alpha*mmax*tmax_alpha
    unsigned long long *C // original generating matrices of size r*d*mmax*tmax
){
    unsigned long long l0 = 0*bs_r;
    unsigned long long j0 = 0*bs_d;
    unsigned long long k0 = 0*bs_mmax;
    unsigned long long kk_max = (mmax-k0)<bs_mmax ? (mmax-k0):bs_mmax;
    unsigned long long jj_max = (d-j0)<bs_d ? (d-j0):bs_d;
    unsigned long long ll_max = (r-l0)<bs_r ? (r-l0):bs_r;
    unsigned long long ll,l,j_alpha,kk,k,t_alpha,tt_alpha,t,jj,j;
    for(ll=0; ll<ll_max; ll++){
        l = l0+ll;
        for(jj=0; jj<jj_max; jj++){
            j = j0+jj;
             for(kk=0; kk<kk_max; kk++){
                k = k0+kk;
                for(t=0; t<tmax; t++){
                    j_alpha = j/alpha;
                    tt_alpha = j%alpha;
                    t_alpha = t*alpha+tt_alpha;
                    C[l*d*mmax*tmax+j*mmax*tmax+k*tmax+t] = C_alpha[l*d_alpha*mmax*tmax_alpha+j_alpha*mmax*tmax_alpha+k*tmax_alpha+t_alpha];
                }
            }
        }
    }
}