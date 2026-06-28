#include "qmctoolscl.h"

EXPORT void lat_gen_natural(
    // Lattice points in natural order
    const unsigned long long r, // replications
    const unsigned long long n, // points
    const unsigned long long d, // dimension
    const unsigned long long bs_r, // batch size for replications
    const unsigned long long bs_n, // batch size for points
    const unsigned long long bs_d, // batch size for dimension
    const unsigned long long n_start, // starting index in sequence
    const unsigned long long *g, // pointer to generating vector of size r*d 
    double *x // pointer to point storage of size r*n*d
){   
    unsigned long long l0 = 0*bs_r;
    unsigned long long i0 = 0*bs_n;
    unsigned long long j0 = 0*bs_d;
    unsigned long long ii_max = (n-i0)<bs_n ? (n-i0):bs_n;
    unsigned long long jj_max = (d-j0)<bs_d ? (d-j0):bs_d;
    unsigned long long ll_max = (r-l0)<bs_r ? (r-l0):bs_r;
    double ifrac, _v;
    unsigned long long p,v,itrue,igc,b,ll,l,ii,i,jj,j,idx;
    unsigned long long n0 = n_start+i0;
    p = ceil(log2((double)n0+1));
    v = 0; 
    b = 0;
    unsigned long long t = n0^(n0>>1);
    while(t>0){
        if(t&1){
            v+= 1<<(p-b-1);
        }
        b += 1;
        t >>= 1;
    }
    for(ii=0; ii<ii_max; ii++){
        i = i0+ii;
        ifrac = ldexp((double)v,-p);
        for(jj=0; jj<jj_max; jj++){
            j = j0+jj;
            itrue = i+n_start;
            igc = itrue^(itrue>>1);
            idx = (igc-n_start)*d+j;
            for(ll=0; ll<ll_max; ll++){
                l = l0+ll;
                _v = (double)g[l*d+j] * ifrac; x[l*n*d+idx] = _v - floor(_v);
            }
        }
        itrue = i+n_start+1;
        if((itrue&(itrue-1))==0){ // if itrue>0 is a power of 2
            p += 1;
            v <<= 1;
        }
        b = 0;
        while(!((itrue>>b)&1)){
            b += 1;
        }
        v ^= 1<<(p-b-1);
    }
}