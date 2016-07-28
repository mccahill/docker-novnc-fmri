static const char rcsid[] = "$Id: cellfun2.c,v 1.7 2004/03/23 16:42:22 michelich Exp $";
/*
 *
 * CELLFUN2 Extended cell array functions.  Based on MATLAB's CELLFUN.
 *
 *   TF = CELLFUN(FUN, C) where FUN is one of 
 *
 *     'isnumeric'   -- true for numeric cell
 *     'isfinite'    -- true for double cell, with all elements finite
 *     'isnotfinite' -- true for double cell, with all elements not finite
 *     'isinf'       -- true for double cell, with all elements infinite
 *     'isnan'       -- true for double cell, with all elements NaN
 *
 *   and C is the cell array, returns the results of
 *   applying the specified function to each element
 *   of the cell array. TF is a logical array the same
 *   size as C containing the results of applying FUN on
 *   the corresponding cell elements of C.
 *
 *   Complex numbers are handled the same way that the built-in MATLAB
 *   ISFINITE, ISINF, and ISNAN functions handles them.  If either the
 *   real of imaginary parts are Inf or NaN, the element is considered
 *   to be infinite or Not-a-Number repectively.
 *
 *   Note that a logical array is NOT a double, numerical array in
 *   MATLAB R13, but is a double, numerical array in earlier versions.
 *   CELLFUN2 behaves the same as the ISNUMERIC and ISA functions of
 *   the MATLAB version in which CELLFUN2 is executed.
 *
 *   See Also: CELLFUN, ISNUMERIC, ISFINITE, ISINF, ISNAN
 *
 */

/*
 *   Note on compatilibity with MATLAB versions:
 *   MATLAB R13 (6.5) introduced a logical type. Versions of MATLAB
 *   prior to R13 did not have a logical type.  Instead these
 *   versions used a numeric (double) array with a logical flag.
 * 
 *   cellfun2.c has been modified for compatibility with MATLAB R13.
 *   To compile using an older version of MATLAB, use the #define
 *   NO_LOGICAL_TYPE.  It is also possible to use the MEX file compiled
 *   with the #define NO_LOGICAL_TYPE in MATLAB R13, however a warning
 *   will be issued each time the function is called.
 *
 *   Compliation instructions:
 *     MATLAB 5 to 6.1:  
 *       mex -DNO_LOGICAL_TYPE cellfun2.m
 *         - Compatibile with MATLAB 6.5, but a warning will
 *           be issued each time the function is called.
 *     MATLAB 6.5:
 *       mex cellfun2.m
 *         - Only compatible with MATLAB 6.5 and later
 *
 */
 
/* The results of the function call on the left should match the results
   of the MATLAB code on the right.

   cellfun2('isnumeric',c)   ==>  tf = logical(zeros(size(c))); 
                                  for n=1:numel(c)
                                    results(n)=isnumeric(c{n});
                                  end

   cellfun2('isnotfinite',c) ==>  tf = logical(zeros(size(c))); 
                                  for n=1:numel(c)
                                    if isa(c{n},'double') & ~isempty(c{n})
                                      results(n)=all(~isfinite(c{n}(:))); 
                                    end
                                  end
   
   For FUN = isinf or isnan or isfinite  
   cellfun2(FUN,c)           ==>  tf = logical(zeros(size(c)));
                                  for n=1:numel(c)
                                    if isa(c{n},'double') & ~isempty(c{n})
                                      results(n)=all(FUN(c{n}(:))); 
                                    end
                                  end

   % Here is an example cell array with several of possible test cases
   a=10*ones(4,3,2); a(4,3,2)=Inf;
   c={1,'c',Inf,-Inf,NaN,logical([0,1]),struct('test','test'),uint8([0 1 2]), ...
    complex(Inf,10),complex(10,Inf),@plot,single(Inf),single(-Inf),single(NaN), ...
    complex(NaN,10),complex(NaN,-20),[1 Inf; 0 NaN],[-120 NaN 0],[Inf, -Inf, 0], ...
    [1 2 3; 4 5 6], 10*ones(2,3,4),a,[],-1};
   c=reshape(c,[4 2 3]);

   % Sample test code
   tf = logical(zeros(size(c))); for n=1:numel(c), tf(n)=isnumeric(c{n}); end
   ctf = cellfun2('isnumeric',c);
   if isequal(tf,ctf), disp('isnumeric passed'); else disp('isnumeric failed'); end
   
   tf = logical(zeros(size(c))); for n=1:numel(c), if isa(c{n},'double') & ~isempty(c{n}), tf(n)=all(~isfinite(c{n}(:))); end, end
   ctf = cellfun2('isnotfinite',c);
   if isequal(tf,ctf), disp('isnotfinite passed'); else disp('isnotfinite failed'); end

   tf = logical(zeros(size(c))); for n=1:numel(c), if isa(c{n},'double') & ~isempty(c{n}), tf(n)=all(isfinite(c{n}(:))); end, end
   ctf = cellfun2('isfinite',c);
   if isequal(tf,ctf), disp('isfinite passed'); else disp('isfinite failed'); end
 
   tf = logical(zeros(size(c))); for n=1:numel(c), if isa(c{n},'double') & ~isempty(c{n}), tf(n)=all(isnan(c{n}(:))); end, end
   ctf = cellfun2('isnan',c);
   if isequal(tf,ctf), disp('isnan passed'); else disp('isnan failed'); end

   tf = logical(zeros(size(c))); for n=1:numel(c), if isa(c{n},'double') & ~isempty(c{n}), tf(n)=all(isinf(c{n}(:))); end, end
   ctf = cellfun2('isinf',c);
   if isequal(tf,ctf), disp('isinf passed'); else disp('isinf failed'); end 
*/

#include <string.h>
#include "mex.h"
#include "matrix.h"

/* Define a myLogicalType for compatibility with multiple
   versions of MATLAB.  Also define the TRUE and FALSE
   represenations for the different MATLAB verions */
#ifdef NO_LOGICAL_TYPE
typedef double myLogicalType;
#define MYTRUE 1.0
#define MYFALSE 0.0
#else
typedef mxLogical myLogicalType;
#define MYTRUE true
#define MYFALSE false
#endif

/* Function that checks for cell elements that are numeric */
void cellIsNumeric(myLogicalType *pr, const mxArray *prhs, int numel) 
{
    int i;
    mxArray *cell;

    for (i = 0; i < numel; i++) {
        cell = mxGetCell(prhs, i);
        if (cell != NULL) {
            *pr = ((myLogicalType)mxIsNumeric(cell));
        } else {
            /* Uninitialized cell elements are treated as numeric */
            *pr = MYTRUE;
        }
        pr++;
    }
}

/* Function that checks for cell elements that are numeric and finite */
void cellIsFinite(myLogicalType *pr, const mxArray *prhs, int numel) 
{
    int i,j;
    mxArray *cell;
    double *realData, *imagData;

    for (i = 0; i < numel; i++) {
        cell = mxGetCell(prhs, i);
        if (cell != NULL && !mxIsEmpty(cell) && mxIsDouble(cell)) {
			*pr = MYTRUE; /* Initialize to true */
            realData = mxGetPr(cell);
			if (mxIsComplex(cell)) {
				/* All elements of numeric array must have finite 
				   real and imaging parts of data == Inf */
				imagData = mxGetPi(cell);
				for (j = 0; j < mxGetNumberOfElements(cell) && *pr; j++)
					*pr = (myLogicalType)(mxIsFinite(realData[j]) && 
					                      mxIsFinite(imagData[j]));
			}
			else {
     	     	/* All elements of numeric array must be finite */
	            for (j = 0; j < mxGetNumberOfElements(cell) && *pr; j++)
		            *pr = (myLogicalType)mxIsFinite(realData[j]);
			}
        } else {
			/* Return false for uninitialized, empty, or non-double cell elements */
			*pr = MYFALSE;
        }
        pr++;
    }
}

/* Function that checks for cell elements that are numeric and not finite */
void cellIsNotFinite(myLogicalType *pr, const mxArray *prhs, int numel) 
{
    int i,j;
    mxArray *cell;
    double *realData, *imagData;

    for (i = 0; i < numel; i++) {
        cell = mxGetCell(prhs, i);
        if (cell != NULL && !mxIsEmpty(cell) && mxIsDouble(cell)) {
			*pr = MYTRUE; /* Initialize to true */
			realData = mxGetPr(cell);
			if (mxIsComplex(cell)) {
				/* All elements of numeric array must have non-finite
				   real or imaging parts of data == Inf */
				imagData = mxGetPi(cell);
				for (j = 0; j < mxGetNumberOfElements(cell) && *pr; j++)
					*pr = (myLogicalType)(!mxIsFinite(realData[j]) || 
					                      !mxIsFinite(imagData[j]));
			}
			else {
                /* All elements of numeric array must be non-finite */
	            for (j = 0; j < mxGetNumberOfElements(cell) && *pr; j++)
		            *pr = (myLogicalType)!mxIsFinite(realData[j]);
			}
        } else {
			/* Return false for uninitialized, empty, or non-double cell elements */
			*pr = MYFALSE;
        }
        pr++;
    }
}

/* Function that checks for cell elements that are Inf or -Inf */
void cellIsInf(myLogicalType *pr, const mxArray *prhs, int numel) 
{
    int i,j;
    mxArray *cell;
    double *realData, *imagData;

    for (i = 0; i < numel; i++) {
        cell = mxGetCell(prhs, i);
        if (cell != NULL && !mxIsEmpty(cell) && mxIsDouble(cell)) {
			*pr = MYTRUE; /* Initialize to true */
            realData = mxGetPr(cell);
			if (mxIsComplex(cell)) {
				/* All elements of numeric array must have either 
				   real or imaging parts of data == Inf */
				imagData = mxGetPi(cell);
				for (j = 0; j < mxGetNumberOfElements(cell) && *pr; j++)
					*pr = (myLogicalType)(mxIsInf(realData[j]) || 
					                      mxIsInf(imagData[j]));
			}
			else {
				/* All elements of numeric array must be Inf*/
	            for (j = 0; j < mxGetNumberOfElements(cell) && *pr; j++)
		            *pr = (myLogicalType)mxIsInf(realData[j]);
			}
        } else {
			/* Return false for uninitialized, empty, or non-double cell elements */
			*pr = MYFALSE;
        }
        pr++;
    }
}

/* Function that checks for cell elements that are NaN */
void cellIsNaN(myLogicalType *pr, const mxArray *prhs, int numel) 
{
    int i,j;
    mxArray *cell;
    double *realData, *imagData;

    for (i = 0; i < numel; i++) {
        cell = mxGetCell(prhs, i);
        if (cell != NULL && !mxIsEmpty(cell) && mxIsDouble(cell)) {
			*pr = MYTRUE; /* Initialize to true */
            realData = mxGetPr(cell);
			if (mxIsComplex(cell)) {
				/* All elements of numeric array must have either 
				   real or imaging parts of data == NaN */
				imagData = mxGetPi(cell);
				for (j = 0; j < mxGetNumberOfElements(cell) && *pr; j++)
					*pr = (myLogicalType)(mxIsNaN(realData[j]) || 
					                      mxIsNaN(imagData[j]));
			}
			else {
				/* All elements of numeric array must be NaN */
	            for (j = 0; j < mxGetNumberOfElements(cell) && *pr; j++)
		            *pr = (myLogicalType)mxIsNaN(realData[j]);
			}
        } else {
			/* Return false for uninitialized, empty, or non-double cell elements */
			*pr = MYFALSE;
		}
        pr++;
    }
}

/* ******************** MEX GATEWAY ***************************************/
/*  Mex interface to functions that operate on cell elements.
    Currently supported functions are - isreal, isempty, isclass,
    islogical, size, length, ndims.
 */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    int         numel;
    int         buflen, status;
    myLogicalType *pr;
    char        *buf;

    /* Check the inputs */
    if (nrhs != 2) {
        mexErrMsgTxt("Incorrect number of inputs.");
    }

    /* Ensure that the first argument is a string and the second is a cell */
    if (!mxIsChar(prhs[0])) {
        mexErrMsgTxt("Function name must be a string.");
    } else if (!mxIsCell(prhs[1])) {
        mexErrMsgTxt("CELLFUN2 only works on cells.");
    }

    /* Get the number of elements in the cell */
    numel = mxGetNumberOfElements(prhs[1]);

    /* Create a logical array of the same size as the input cell */
#ifdef NO_LOGICAL_TYPE
    /* No logical type, create a numerical array and set the logical flag */
    plhs[0] = mxCreateNumericArray(mxGetNumberOfDimensions(prhs[1]),
                                   mxGetDimensions(prhs[1]),
                                   mxDOUBLE_CLASS, mxREAL);
    mxSetLogical(plhs[0]);
    pr      = (myLogicalType *)mxGetData(plhs[0]);
#else
    /* There is a logical type, make a logical array */
   	plhs[0] = mxCreateLogicalArray(mxGetNumberOfDimensions(prhs[1]),
                                   mxGetDimensions(prhs[1]));
    pr      = mxGetLogicals(plhs[0]);
#endif

    /* Get the name of the function */
    buflen = mxGetNumberOfElements(prhs[0]) + 1;
    buf    = mxMalloc(buflen*sizeof(char));

    status = mxGetString(prhs[0], buf, buflen);
    if (status != 0) {
        mexErrMsgTxt("Could not get string.");
    }   

    /* Processing the cell elements begins here */
    if (!strcmp(buf,"isnumeric")) {
        cellIsNumeric(pr, prhs[1], numel); 
    } else if (!strcmp(buf,"isfinite")) {
        cellIsFinite(pr, prhs[1], numel);
    } else if (!strcmp(buf,"isnotfinite")) {
        cellIsNotFinite(pr, prhs[1], numel);
    } else if (!strcmp(buf,"isinf")) {
        cellIsInf(pr, prhs[1], numel);
    } else if (!strcmp(buf,"isnan")) {
        cellIsNaN(pr, prhs[1], numel);
    } else {
        mexErrMsgTxt("Unknown option.");
    }

    /* Free the temporary buffer */
    mxFree(buf);  
}

/* Modification History:
 * 
 * $Log: cellfun2.c,v $
 * Revision 1.7  2004/03/23 16:42:22  michelich
 * Changes to test code in comments.
 * - Use numel(x) instead of length(x(:))
 * - Use multi-dimensional test array.
 *
 * Revision 1.6  2004/03/17 16:43:47  michelich
 * Fixed MATLAB test code in comments to test and handle empty cells properly.
 *
 * Revision 1.5  2003/07/22 15:39:03  michelich
 * Removed a couple of extra variables & added test code to comments.
 *
 * Revision 1.4  2002/09/18 23:10:45  michelich
 * Added equivalent MATLAB code to comments for clarity & ease of testing
 *
 * Revision 1.3  2002/09/18 22:28:03  michelich
 * Updated for MATLAB 6.5 logical type
 * Added proper handling of complex data
 * Changed behavior of isfinite,isnotfinite,isnan,isinf cases to return false for
 *   all numeric types other than double.  The types were not being handled
 *   properly (particularly single precision float) in the code and  MATLAB
 *   does not support these functions for types other than double.  Explicitly
 *   handling all other numeric types could be added in the future if the need
 *   arises.
 *
 * Revision 1.2  2002/08/29 23:09:39  crm
 * Added newline at end of file
 *
 * Revision 1.1  2002/08/27 22:24:13  michelich
 * Initial CVS Import
 *
 *
 * Pre CVS History Entries:
 * Francis Favorini, 2000/05/08.  Based on MATLAB's CELLFUN.
 *
 */
