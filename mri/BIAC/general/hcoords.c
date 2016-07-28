static const char rcsid[] = "$Id: hcoords.c,v 1.3 2003/01/01 00:17:53 michelich Exp $";
/*
 *
 * HCOORDS.C Return homogeneous coordinate array.
 *
 * The calling syntax is:
 *
 *		XYZT=HCOORDS(X,Y,Z);
 *
 */

#include <memory.h>
#include "mex.h"

void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]) {
  /* Declare variables */
  int empty=0;                    /* Any args empty? */
  int inDims[3]={0,0,0};          /* Input args' dimensions */
  int outDims[2]={0,4};
  int a;                          /* Counter */
  int xs, ys, zs;                 /* length of x,y,z */
	
  /* Check for proper number of arguments */
  if (nrhs!=3)
    mexErrMsgTxt("HCOORDS requires 3 input arguments.");
  else if (nlhs>1)
    mexErrMsgTxt("HCOORDS requires 0 or 1 output arguments.");
  
  /* Input args must be numeric vectors or 3-D arrays. */
  for (a=0; a<nrhs; a++) {
    int numDims=mxGetNumberOfDimensions(prhs[a]);
    const int *dims=mxGetDimensions(prhs[a]);
    int len=0;
    if (!mxIsNumeric(prhs[a]) || mxIsComplex(prhs[a]) || mxIsSparse(prhs[a])  || !mxIsDouble(prhs[a]))
      mexErrMsgTxt("HCOORDS requires all arguments to be arrays of noncomplex, nonsparse doubles.");
    if (numDims==2) {                                               /* Might be vector */
      if (mxGetM(prhs[a])==1) {numDims=1; inDims[a]=dims[1];}       /* Row vector */
      else if (mxGetN(prhs[a])==1) {numDims=1; inDims[a]=dims[0];}  /* Column vector */
      }
    if (numDims!=1)
      mexErrMsgTxt("HCOORDS requires X,Y,Z to be vectors.");
    if (mxIsEmpty(prhs[a])) empty=1;
    }
  xs=inDims[0];
  ys=inDims[1];
  zs=inDims[2];
  if (!empty) outDims[0]=xs*ys*zs;

  /* Create a matrix for the output arg */
  plhs[0]=mxCreateNumericArray(2,outDims,mxDOUBLE_CLASS,mxREAL);
  if (plhs[0]==NULL)
    mexErrMsgTxt("Could not create output array.\n");

  if (!empty) {
    /* Assign pointers to real parts of the input args */
    double *x=mxGetPr(prhs[0]);
    double *y=mxGetPr(prhs[1]);
    double *z=mxGetPr(prhs[2]);

    /* Expand coordinates */
    int i,j,k;
    double *p=mxGetPr(plhs[0]);
    /* Fill column 1 with X */
    for (k=0; k<zs; k++)
      for (j=0; j<ys; j++)
        for (i=0; i<xs; i++)
          *p++=x[i];
    /* Fill column 2 with Y */
    for (k=0; k<zs; k++)
      for (j=0; j<ys; j++)
        for (i=0; i<xs; i++)
          *p++=y[j];
    /* Fill column 3 with Z */
    for (k=0; k<zs; k++)
      for (j=0; j<ys; j++)
        for (i=0; i<xs; i++)
          *p++=z[k];
    /* Fill column 4 with 1 */
    for (k=0; k<zs; k++)
      for (j=0; j<ys; j++)
        for (i=0; i<xs; i++)
          *p++=1;
    }
  return;
  }

/* Modification History:
 * 
 * $Log: hcoords.c,v $
 * Revision 1.3  2003/01/01 00:17:53  michelich
 * Corrected source filename in comments.
 *
 * Revision 1.2  2002/10/10 22:01:12  michelich
 * Converted from C++ to C
 * Changed name from hcoords.cpp to hcoords.c
 *
 * Revision 1.1  2002/08/27 22:24:15  michelich
 * Initial CVS Import
 *
 *
 * Pre CVS History Entries:
 * Francis Favorini, 1998/11/18.
 *
 */
