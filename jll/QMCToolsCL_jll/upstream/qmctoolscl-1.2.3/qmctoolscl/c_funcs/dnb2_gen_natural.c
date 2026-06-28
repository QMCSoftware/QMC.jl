#include "qmctoolscl.h"

EXPORT void dnb2_gen_natural(
    // Binary representation of digital net in base 2 in natural order
    const unsigned long long r, // replications
    const unsigned long long n, // points
    const unsigned long long d, // dimension
    const unsigned long long bs_r, // batch size for replications
    const unsigned long long bs_n, // batch size for points
    const unsigned long long bs_d, // batch size for dimension
    const unsigned long long n_start, // starting index in sequence
    const unsigned long long mmax, // columns in each generating matrix
    const unsigned long long *C, // generating matrices of size r*d*mmax
    unsigned long long *xb // binary digital net points of size r*n*d
){   
    unsigned long long l0 = 0*bs_r;
    unsigned long long i0 = 0*bs_n;
    unsigned long long j0 = 0*bs_d;
    unsigned long long ii_max = (n-i0)<bs_n ? (n-i0):bs_n;
    unsigned long long jj_max = (d-j0)<bs_d ? (d-j0):bs_d;
    unsigned long long ll_max = (r-l0)<bs_r ? (r-l0):bs_r;
    unsigned long long b,t,ll,l,ii,i,jj,j,prev_i,new_i;
    unsigned long long itrue = n_start+i0;
    // initial index 
    t = itrue^(itrue>>1);
    prev_i = (t-n_start)*d;
    if(n>0){
        // initialize first values 0 
        for(jj=0; jj<jj_max; jj++){
            j = j0+jj;
            for(ll=0; ll<ll_max; ll++){
                l = l0+ll;
                xb[l*n*d+prev_i+j] = 0;
            }
        }
        // set first values
        b = 0;
        while(t>0){
            if(t&1){
                for(jj=0; jj<jj_max; jj++){
                    j = j0+jj;
                    for(ll=0; ll<ll_max; ll++){
                        l = l0+ll;
                        xb[l*n*d+prev_i+j] ^= C[l*d*mmax+j*mmax+b];
                    }
                }
            }
            b += 1;
            t >>= 1;
        }
    }
    // set remaining values
    for(ii=1; ii<ii_max; ii++){
        i = i0+ii;
        itrue = i+n_start;
        t = itrue^(itrue>>1);
        new_i = (t-n_start)*d;
        b = 0;
        while(!((itrue>>b)&1)){
            b += 1;
        }
        for(jj=0; jj<jj_max; jj++){
            j = j0+jj;
            for(ll=0; ll<ll_max; ll++){
                l = l0+ll;
                xb[l*n*d+new_i+j] = xb[l*n*d+prev_i+j]^C[l*d*mmax+j*mmax+b];
            }
        }
        prev_i = new_i;
    }
}