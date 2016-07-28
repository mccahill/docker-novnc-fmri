static const char rcsid[] = "$Id: getfilesizes.c,v 1.3 2003/04/20 04:02:48 crm Exp $";
/*
 * getfilesize.c
 *
 * GETFILESIZES Determine size of the specified file(s)
 *   
 *   fsizes = GETFILESIZES(files)
 *
 *     files is a cell array of filename(s) to get sizes of.
 *     fsizes is a vector of the filesizes corresponding to each element of
 *       files.  fsizes(n) = -1 if the size could not be determined for
 *       files(n).
 *
 * NOTE: MEX file uses 32-bit version of stat.
 *
 * See also DIR
 */

#include "mex.h"
#include <sys/types.h>
#include <sys/stat.h>

void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
  /* Declare & Initialize variables */
  int n, currLength;      /* Generic counter & temp length variable */
  int numInElements;      /* Number of elements in input array */
  double * out = NULL;    /* Pointer to output array */
  char * filename = NULL; /* Current filename */
  int filenameLength = 0; /* Length of longest filename */
  struct stat statInfo;   /* Structure of file information */
  
  /* Check for proper number of arguments */
  if (nrhs!=1)
    mexErrMsgTxt("GETFILESIZES requires 1 input argument.");
  else if (nlhs>1)
    mexErrMsgTxt("GETFILESIZES requires 0 or 1 output arguments.");
  
  /* Initialize number of input elements */
  numInElements=mxGetNumberOfElements(prhs[0]);
  
  /* First input must be a cell array of strings */
  if (!mxIsCell(prhs[0]) || mxIsEmpty(prhs[0]))
    mexErrMsgTxt("GETFILESIZES: files must be a non-empty cell array of strings!");
  for (n=0; n<numInElements; n++)
  {
    if (!mxIsChar(mxGetCell(prhs[0],n)))
      mexErrMsgTxt("GETFILESIZES: files must be a non-empty cell array of strings!");
  }

  /* Determine length of longest filename */
  for (n=0; n<numInElements; n++)
  {
    currLength=mxGetNumberOfElements(mxGetCell(prhs[0],n));
    if (currLength > filenameLength)
      filenameLength = currLength;
  }
  /* Adjust length to handle multibyte character sets */
  filenameLength = filenameLength * sizeof(mxChar) + 1;

  /* Allocate output array (double array same size as input) */
  plhs[0]=mxCreateNumericArray(mxGetNumberOfDimensions(prhs[0]),
                               mxGetDimensions(prhs[0]),mxDOUBLE_CLASS,mxREAL);
  if (plhs[0]==NULL)
    mexErrMsgTxt("GETFILESIZES: Could not create output array.");
  out = mxGetPr(plhs[0]);
  
  /* Allocate space for filename */
  filename = (char *)mxMalloc(sizeof(char)*filenameLength);
  if (filename == NULL)
    mexErrMsgTxt("GETFILESIZES: Could not create filename array.");
  
  /* --- Get size of each file --- */
  for(n=0; n<numInElements; n++)
  {
    /* Put current filename in a C-string */
    if (mxGetString(mxGetCell(prhs[0],n), filename, filenameLength) != 0)
      mexErrMsgTxt("GETFILESIZES: Could not convert filename to a string.");

    if (stat(filename,&statInfo) == 0)
    {
      if (S_IFDIR & statInfo.st_mode)
        out[n]=0; /* Set size of directories to zero */
      else
        out[n]=(double)statInfo.st_size; /* Extract filesize */
    }
    else
      out[n]=-1; /* Unable to get information */
  }
  mxFree(filename);
}

/* Modification History:
 * 
 * $Log: getfilesizes.c,v $
 * Revision 1.3  2003/04/20 04:02:48  crm
 * Optimization: Only allocate filename string once.
 * Check for errors in allocating filename and extracting string.
 *
 * Revision 1.2  2003/04/18 22:21:36  michelich
 * Set size of directories to zero (like dir in MATLAB).
 *
 * Revision 1.1  2003/04/18 22:03:07  michelich
 * Initial version.
 *
 *
 */
