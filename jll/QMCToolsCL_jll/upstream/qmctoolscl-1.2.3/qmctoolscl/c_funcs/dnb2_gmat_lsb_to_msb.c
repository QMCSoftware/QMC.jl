#include "qmctoolscl.h"

EXPORT void dnb2_gmat_lsb_to_msb(
    // Convert base 2 generating matrices with integers stored in Least Significant Bit order to Most Significant Bit order
    const unsigned long long r, // replications
    const unsigned long long d, // dimension
    const unsigned long long mmax, // columns in each generating matrix 
    const unsigned long long bs_r, // batch size for replications
    const unsigned long long bs_d, // batch size for dimensions
    const unsigned long long bs_mmax, // batch size for columns
    const unsigned long long *tmaxes, // length r vector of bits in each integer of the resulting MSB generating matrices
    const unsigned long long *C_lsb, // original generating matrices of size r*d*mmax
    unsigned long long *C_msb // new generating matrices of size r*d*mmax
){
    unsigned long long l0 = 0*bs_r;
    unsigned long long j0 = 0*bs_d;
    unsigned long long k0 = 0*bs_mmax;
    unsigned long long kk_max = (mmax-k0)<bs_mmax ? (mmax-k0):bs_mmax;
    unsigned long long jj_max = (d-j0)<bs_d ? (d-j0):bs_d;
    unsigned long long ll_max = (r-l0)<bs_r ? (r-l0):bs_r;
    unsigned long long tmax,t,ll,l,jj,j,kk,k,v,vnew,idx;
    unsigned long long bigone = 1;
    for(ll=0; ll<ll_max; ll++){
        l = l0+ll;
        tmax = tmaxes[l];
        for(jj=0; jj<jj_max; jj++){
            j = j0+jj;
            for(kk=0; kk<kk_max; kk++){
                k = k0+kk;
                idx = l*d*mmax+j*mmax+k;
                v = C_lsb[idx];
                vnew = 0;
                t = 0; 
                while(v!=0){
                    if(v&1){
                        vnew += bigone<<(tmax-t-1);
                    }
                    v >>= 1;
                    t += 1;
                }
                C_msb[idx] = vnew;
            }
        }
    }
}