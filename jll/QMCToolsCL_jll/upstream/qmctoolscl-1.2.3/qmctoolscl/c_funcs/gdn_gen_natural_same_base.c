#include "qmctoolscl.h"

EXPORT void gdn_gen_natural_same_base(
    // Generalized digital net with the same base for each dimension e.g. a digital net in base greater than 2
    const unsigned long long r, // replications
    const unsigned long long n, // points
    const unsigned long long d, // dimension
    const unsigned long long bs_r, // batch size for replications
    const unsigned long long bs_n, // batch size for points
    const unsigned long long bs_d, // batch size for dimension
    const unsigned long long mmax, // columns in each generating matrix
    const unsigned long long tmax, // rows of each generating matrix
    const unsigned long long n_start, // starting index in sequence
    const unsigned long long b, // common base
    const unsigned long long *C, // generating matrices of size r*d*mmax*tmax
    unsigned long long *xdig // generalized digital net sequence of digits of size r*n*d*tmax
){   
    unsigned long long l0 = 0*bs_r;
    unsigned long long i0 = 0*bs_n;
    unsigned long long j0 = 0*bs_d;
    unsigned long long ii_max = (n-i0)<bs_n ? (n-i0):bs_n;
    unsigned long long jj_max = (d-j0)<bs_d ? (d-j0):bs_d;
    unsigned long long ll_max = (r-l0)<bs_r ? (r-l0):bs_r;
    unsigned long long idx_xdig,idx_C,dig,itrue,icp,ii,i,jj,j,ll,l,t,k;
    // initialize xdig everything to 0
    for(ll=0; ll<ll_max; ll++){
        l = l0+ll;
        for(ii=0; ii<ii_max; ii++){
            i = i0+ii;
            for(jj=0; jj<jj_max; jj++){
                j = j0+jj;
                idx_xdig = l*n*d*tmax+i*d*tmax+j*tmax;
                for(t=0; t<tmax; t++){
                    xdig[idx_xdig+t] = 0;
                }
            }
        }
    }
    // now set the points
    for(ii=0; ii<ii_max; ii++){
        i = i0+ii;
        itrue = i+n_start;
        k = 0;
        icp = itrue; 
        while(icp>0){
            dig = icp%b;
            icp = (icp-dig)/b;
            if(dig>0){
                for(ll=0; ll<ll_max; ll++){
                    l = l0+ll;
                    for(jj=0; jj<jj_max; jj++){
                        j = j0+jj;
                        idx_xdig = l*n*d*tmax+i*d*tmax+j*tmax;
                        idx_C = l*d*mmax*tmax+j*mmax*tmax+k*tmax;
                        for(t=0; t<tmax; t++){
                            xdig[idx_xdig+t] = (xdig[idx_xdig+t]+dig*C[idx_C+t])%b;
                        }
                    }
                }
            }
            k += 1;
        }
    }
}