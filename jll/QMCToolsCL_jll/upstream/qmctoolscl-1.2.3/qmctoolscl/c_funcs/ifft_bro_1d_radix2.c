#include "qmctoolscl.h"

EXPORT void ifft_bro_1d_radix2(
    // Inverse Fast Fourier Transform with outputs in bit reversed order.
    // FFT is done in place along the last dimension where the size is required to be a power of 2. 
    // Follows a procedure described in https://www.expertsmind.com/learning/inverse-dft-using-the-fft-algorithm-assignment-help-7342873886.aspx. 
    const unsigned long long d1, // first dimension
    const unsigned long long d2, // second dimension
    const unsigned long long n_half, // half of the last dimension of size n = 2n_half along which FFT is performed
    const unsigned long long bs_d1, // batch size first dimension 
    const unsigned long long bs_d2, // batch size second dimension
    const unsigned long long bs_n_half, // batch size for half of the last dimension
    double *twiddler, // size n vector used to store real twiddle factors
    double *twiddlei, // size n vector used to store imaginary twiddle factors 
    double *xr, // real array of size d1*d2*n on which to perform FFT in place
    double *xi // imaginary array of size d1*d2*n on which to perform FFT in place
){
    unsigned long long j10 = 0*bs_d1;
    unsigned long long j20 = 0*bs_d2;
    unsigned long long i0 = 0*bs_n_half;
    unsigned long long ii_max = (n_half-i0)<bs_n_half ? (n_half-i0):bs_n_half;
    unsigned long long jj1_max = (d1-j10)<bs_d1 ? (d1-j10):bs_d1;
    unsigned long long jj2_max = (d2-j20)<bs_d2 ? (d2-j20):bs_d2;
    unsigned long long ii,i,i1,i2,t,jj1,jj2,j1,j2,k,s,f,idx;
    double xr1,xr2,xi1,xi2,yr,yi,v1,v2,cosv,sinv;
    double PI = acos(-1.);
    unsigned long long n = 2*n_half;
    unsigned long long m = (unsigned long long)(log2((double)n));
    unsigned long long bigone = 1;
    double sqrt2 = sqrt((double)2);
    // initialize twiddle factors
    for(ii=0; ii<ii_max; ii++){
        i = i0+ii;
        i1 = 2*i;
        i2 = i1+1;
        v1 = 2*PI*i1/n;
        twiddler[i1] = cos(v1);
        twiddlei[i1] = sin(v1);
        v2 = 2*PI*i2/n;
        twiddler[i2] = cos(v2);
        twiddlei[i2] = sin(v2);
    }
    
    // remaining butterflies
    for(k=0; k<m; k++){
        s = m-k-1;
        f = 1<<s; 
        for(ii=0; ii<ii_max; ii++){
            i = i0+ii;
            if((i>>s)&1){
                i2 = i+n_half;
                i1 = i2^f;
            }
            else{
                i1 = i;
                i2 = i1^f;
            }
            t = (i1%(1<<s))*(bigone<<k);
            cosv = twiddler[t];
            sinv = twiddlei[t];
            for(jj1=0; jj1<jj1_max; jj1++){
                j1 = j10+jj1;
                for(jj2=0; jj2<jj2_max; jj2++){
                    j2 = j20+jj2;
                    idx = j1*d2*n+j2*n;
                    xr1 = xr[idx+i1];
                    xr2 = xr[idx+i2];
                    xi1 = xi[idx+i1];
                    xi2 = xi[idx+i2];
                    yr = xr1-xr2;
                    yi = xi1-xi2; 
                    xr[idx+i1] = (xr1+xr2)/sqrt2;
                    xi[idx+i1] = (xi1+xi2)/sqrt2;
                    xr[idx+i2] = (yr*cosv-yi*sinv)/sqrt2;
                    xi[idx+i2] = (yr*sinv+yi*cosv)/sqrt2;
                }
            }
        }
        
    }
}