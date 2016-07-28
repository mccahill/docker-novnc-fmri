package edu.duke.biac;

import java.lang.String;
import java.io.IOException;
import java.lang.IllegalArgumentException;

public class matlabInputStream extends java.lang.Object
{
    private java.io.InputStream is;
    private long pos;
    private String error;
    private char machineformat;
    public matlabInputStream(java.io.InputStream isin) {
	is = isin;
	pos = 0;
	machineformat = 'n';
    }
    public matlabInputStream(java.io.InputStream isin, String permission) {
	is = isin;
	pos = 0;
	machineformat = 'n';
    }
    public matlabInputStream(java.io.InputStream isin, String permission, String mfin) {
	is = isin;
	pos = 0;
	if (mfin.equals("native")) {
	    mfin = new String("n");
	} else if (mfin.equals("ieee-le")) {
	    mfin = new String("l");
	} else if (mfin.equals("ieee-be")) {
	    mfin = new String("b");
	}
	if (mfin.length() != 1) {
	    throw new IllegalArgumentException("Bad/unsupported machineformat \"" + mfin + "\"");
	}
	machineformat = mfin.charAt(0);
	switch (machineformat) {
	case 'n':
	case 'l':
	case 'b':
	    break;
	default:
	    throw new IllegalArgumentException("Bad/unsupported mfin \"" + machineformat + "\"");
	}
    }
    public byte [] readBuf(int size) throws IOException {
	error = null;
	byte tmpbuf [] = new byte[size];
	int readbytes = 0;
	int curpos = 0;
	while (curpos < size) {
	    readbytes = is.read(tmpbuf, curpos, size-curpos);
	    if (readbytes < 0) {
		break;
	    }
	    curpos += readbytes;
	}
	if (readbytes < 0 && curpos == 0) {
	    return null;
	}
	if (curpos == size) {
	    return tmpbuf;
	}
	/* need to reduce the size of the returned array */
	byte buf [] = new byte[curpos];
	for (int i = 0; i < curpos; i++) {
	    buf[i] = tmpbuf[i];
	}
	return buf;
    }
    public java.io.InputStream getInputStream() { return is; }
    public long getPosition() { return pos; }
    public char getMachineFormat() { return machineformat; }
    
    /*************************************************/
    /* methods to mimic MATLAB file access functions */

    public int fclose() throws IOException {
	error = null;
	is.close();
	return 0;
    }
    public String ferror() {
	if (error == null) {
	    return new String("No error");
	}
	return error;
    }
    public String ferror(String strarg) {
	if (strarg.equals("clear")) {
	    String olderr = error;
	    error = null;
	    return olderr;
	}
	return error;
    }
    public boolean feof() throws IOException {
	error = null;
	byte buf[] = new byte[1];
	int readret = is.read(buf, 0, 0);
	if (readret == -1) {
	    return true;
	} else {
	    return false;
	}
    }
    public long ftell() {
	return pos;
    }
    public int fseek(long offset, String origstr) throws IllegalArgumentException, IOException {
	error = null;
	int originint;
	if (origstr.equals("bof")) {
	    originint = -1;
	} else if (origstr.equals("cof")) {
	    originint = 0;
	} else {
	    throw new IllegalArgumentException("Bad/unsupported origin argument \"" + origstr + "\"");
	}
	return fseek(offset, originint);
    }
    public int fseek(long offset, int origin) throws IllegalArgumentException, IOException {
	error = null;
	long newpos = pos;
	switch (origin) {
	case -1:
	    newpos = offset;
	    break;
	case 0:
	    newpos += offset;
	    break;
	case 1:
	    throw new IllegalArgumentException("Bad/unsupported origin argument \"" + origin + "\"");
	    // break;
	}
	if (newpos < pos) {
	    String msg = new String("Backwards seek specified: ");
	    msg.concat(new String(java.lang.Long.toString(offset)));
	    msg.concat(" from ");
	    switch (origin) {
	    case -1:
		msg.concat("beginning of file\n");
		break;
	    case 0:
		msg.concat("current position\n");
		break;
	    }
	    msg.concat("Current position: ");
	    msg.concat(java.lang.Long.toString(pos));
	    msg.concat("\n");
	    throw new IllegalArgumentException(msg);
	}
	long skippos = is.skip(newpos - pos);
	if (skippos < newpos - pos) {
	    if (feof()) {
		error = new String("Unknown error.");
	    } else {
		error = new String("End of file reached.");
	    }
	    return -1;
	}
	pos = newpos;
	return 0; /* success */
    }
    public double [] fread() throws IllegalArgumentException, IOException {
	return fread(new String("uchar"));
    }
    public double [] fread(double size []) throws IllegalArgumentException, IOException {
	return fread(size, new String("uchar"));
    }
    public double [] fread(String precision) throws IllegalArgumentException, IOException {
	double [] size = new double[1];
	size[0] = java.lang.Double.POSITIVE_INFINITY;
	return fread(size, precision);
    }
    private class precenum {
	static final int UCHAR = 1;
	static final int SCHAR = 2;
	static final int INT8 = 3;
	static final int INT16 = 4;
	static final int INT32 = 5;
	static final int INT64 = 6;
	static final int UINT8 = 7;
	static final int UINT16 = 8;
	static final int UINT32 = 9;
	static final int UINT64 = 10;
	static final int FLOAT32 = 11;
	static final int FLOAT64 = 12;
    }
    public double [] fread(double size [], String precision) throws IllegalArgumentException, IOException {
	int totalelems = 1;
	int prectype;
	if (size.length > 2) {
	    String msg = new String("Too many elements in size array argument");
	    throw new IllegalArgumentException(msg);
	} else if (size.length == 0) {
	    String msg = new String("Size array argument is empty");
	    throw new IllegalArgumentException(msg);
	} else if (size.length == 2) {
	    if (size[1] == java.lang.Double.POSITIVE_INFINITY) {
		totalelems = -1;
	    } else {
		totalelems *= size[0];
		totalelems *= size[1];
	    }
	} else {
	    if (size[0] == java.lang.Double.POSITIVE_INFINITY) {
		totalelems = -1;
	    } else {
		totalelems = (int)size[0];
	    }
	}
	int arrowind = 0;
	String precstr;
	if ((arrowind = precision.indexOf("=>")) != -1) {
	    precstr = precision.substring(0, arrowind);
	} else {
	    precstr = precision;
	}
	if (precstr.equals("unsigned char")) {
	    prectype = precenum.UCHAR;
	} else if (precstr.equals("uchar")) {
	    prectype = precenum.UCHAR;
	} else if (precstr.equals("signed char")) {
	    prectype = precenum.SCHAR;
	} else if (precstr.equals("schar")) {
	    prectype = precenum.SCHAR;
	} else if (precstr.equals("integer*1")) {
	    prectype = precenum.INT8;
	} else if (precstr.equals("int8")) {
	    prectype = precenum.INT8;
	} else if (precstr.equals("integer*2")) {
	    prectype = precenum.INT16;
	} else if (precstr.equals("int16")) {
	    prectype = precenum.INT16;
	} else if (precstr.equals("integer*4")) {
	    prectype = precenum.INT32;
	} else if (precstr.equals("int32")) {
	    prectype = precenum.INT32;
	} else if (precstr.equals("integer*8")) {
	    prectype = precenum.INT64;
	} else if (precstr.equals("int64")) {
	    prectype = precenum.INT64;
	} else if (precstr.equals("uint8")) {
	    prectype = precenum.UINT8;
	} else if (precstr.equals("uint16")) {
	    prectype = precenum.UINT16;
	} else if (precstr.equals("uint32")) {
	    prectype = precenum.UINT32;
	} else if (precstr.equals("uint64")) {
	    prectype = precenum.UINT64;
	} else if (precstr.equals("real*4")) {
	    prectype = precenum.FLOAT32;
	} else if (precstr.equals("single")) {
	    prectype = precenum.FLOAT32;
	} else if (precstr.equals("float32")) {
	    prectype = precenum.FLOAT32;
	} else if (precstr.equals("real*8")) {
	    prectype = precenum.FLOAT64;
	} else if (precstr.equals("double")) {
	    prectype = precenum.FLOAT64;
	} else if (precstr.equals("float64")) {
	    prectype = precenum.FLOAT64;
	} else {
	    throw new IllegalArgumentException("Bad/unsupported precision argument \"" + precision + "\" (used \"" + precstr + "\")");
	}
	int elemlen = 0;
	switch (prectype) {
	case precenum.UCHAR:
	case precenum.SCHAR:
	case precenum.INT8:
	case precenum.UINT8:
	    elemlen = 1;
	    break;
	case precenum.INT16:
	case precenum.UINT16:
	    elemlen = 2;
	    break;
	case precenum.INT32:
	case precenum.UINT32:
	case precenum.FLOAT32:
	    elemlen = 4;
	    break;
	case precenum.INT64:
	case precenum.UINT64:
	case precenum.FLOAT64:
	    elemlen = 8;
	    break;
	}
	byte [] bytebuf = null;
	double [] retval = null;
	int numelems = totalelems;
	if (totalelems == -1) {
	    numelems = 1024*1024;
	}
	int curelemnum = 0;
	while (totalelems == -1 || curelemnum < totalelems) {
	    if (feof()) {
		return retval;
	    }
	    if (bytebuf == null) {
		bytebuf = new byte [numelems*elemlen];
	    }
	    {
		int curpos = curelemnum * elemlen;
		int lefttoread = numelems * elemlen;
		while (!feof() && lefttoread > 0) {
		    int readret = is.read(bytebuf, curpos, lefttoread);
		    if (readret == -1) {
			if (totalelems == -1) {
			    break;
			} else {
			    throw new IOException("Error reading from stream at position " + curpos + " and length " + lefttoread);
			}
		    }
		    curpos += readret;
		    lefttoread -= readret;
		}
		if (lefttoread > 0) {
		    numelems -= lefttoread / elemlen;
		}
	    }
	    java.nio.ByteOrder byteorder = java.nio.ByteOrder.nativeOrder();
	    int needswap = 0;
	    if (machineformat == 'l' ||
		(machineformat == 'n' &&
		 byteorder == java.nio.ByteOrder.LITTLE_ENDIAN)) {
		needswap = 1;
	    }
	    if (needswap != 0 && elemlen > 1) {
		/* need to swap byte order */
		int curpos = 0;
		byte swap = 0;
		switch (elemlen) {
		case 2:
		    for (curpos = 0; curpos < numelems * elemlen; curpos += 2) {
			swap = bytebuf[curpos];
			bytebuf[curpos] = bytebuf[curpos + 1];
			bytebuf[curpos + 1] = swap;
		    }
		    break;
		case 4:
		    for (curpos = 0; curpos < numelems * elemlen; curpos += 4) {
			swap = bytebuf[curpos];
			bytebuf[curpos] = bytebuf[curpos + 3];
			bytebuf[curpos + 3] = swap;
			swap = bytebuf[curpos + 1];
			bytebuf[curpos + 1] = bytebuf[curpos + 2];
			bytebuf[curpos + 2] = swap;
		    }
		    break;
		case 8:
		    for (curpos = 0; curpos < numelems * elemlen; curpos += 8) {
			swap = bytebuf[curpos];
			bytebuf[curpos] = bytebuf[curpos + 7];
			bytebuf[curpos + 7] = swap;
			swap = bytebuf[curpos + 1];
			bytebuf[curpos + 1] = bytebuf[curpos + 6];
			bytebuf[curpos + 6] = swap;
			swap = bytebuf[curpos + 2];
			bytebuf[curpos + 2] = bytebuf[curpos + 5];
			bytebuf[curpos + 5] = swap;
			swap = bytebuf[curpos + 3];
			bytebuf[curpos + 3] = bytebuf[curpos + 4];
			bytebuf[curpos + 4] = swap;
		    }
		    break;
		}
	    }
	    int ind;
	    int bytepos;
	    if (retval == null) {
		retval = new double [numelems];
	    } else {
		double [] newretval = new double[curelemnum + numelems];
		java.lang.System.arraycopy(retval, 0, newretval, 0, curelemnum);
		retval = newretval;
	    }
	    int newnumelems = curelemnum + numelems;
	    switch (prectype) {
	    case precenum.SCHAR:
	    case precenum.INT8:
		for (ind = curelemnum, bytepos = 0; ind < newnumelems; ind++, bytepos += 1) {
		    retval[ind] = bytebuf[bytepos];
		}
		break;
	    case precenum.UCHAR:
	    case precenum.UINT8:
		for (ind = curelemnum, bytepos = 0; ind < newnumelems; ind++, bytepos += 1) {
		    retval[ind] = (0xff & (int)bytebuf[bytepos]);
		}
		break;
	    case precenum.INT16:
		for (ind = curelemnum, bytepos = 0; ind < newnumelems; ind++, bytepos += 2) {
		    retval[ind] =
			(bytebuf[bytepos] * 256) +
			(0xff & (int)bytebuf[bytepos+1]);
		}
		break;
	    case precenum.UINT16:
		for (ind = curelemnum, bytepos = 0; ind < newnumelems; ind++, bytepos += 2) {
		    retval[ind] =
			((0xff & (int)bytebuf[bytepos]) << 8) |
			 (0xff & (int)bytebuf[bytepos+1]);
		}
		break;
	    case precenum.INT32:
		for (ind = curelemnum, bytepos = 0; ind < newnumelems; ind++, bytepos += 4) {
		    retval[ind] =
			(bytebuf[bytepos] * (double)(1<<24)) +
			((0xff & (int)bytebuf[bytepos+1]) * (double)(1<<16)) +
			((0xff & (int)bytebuf[bytepos+2]) * (int)(1<<8)) +
			((0xff & (int)bytebuf[bytepos+3]));
		}
		break;
	    case precenum.UINT32:
		for (ind = curelemnum, bytepos = 0; ind < newnumelems; ind++, bytepos += 4) {
		    retval[ind] =
			((0xff & (int)bytebuf[bytepos]) * (double)(1<<24)) +
			((0xff & (int)bytebuf[bytepos+1]) * (long)(1<<16)) +
			((0xff & (int)bytebuf[bytepos+2]) * (long)(1<<8)) +
			((0xff & (int)bytebuf[bytepos+3]));
		}
		break;
	    case precenum.INT64:
		for (ind = curelemnum, bytepos = 0; ind < newnumelems; ind++, bytepos += 8) {
		    retval[ind] =
			(bytebuf[bytepos] * (double)(1<<56)) +
			((0xff & (int)bytebuf[bytepos+1]) * (long)(1<<48)) +
			((0xff & (int)bytebuf[bytepos+2]) * (long)(1<<40)) +
			((0xff & (int)bytebuf[bytepos+3]) * (long)(1<<32)) +
			((0xff & (int)bytebuf[bytepos+4]) * (long)(1<<24)) +
			((0xff & (int)bytebuf[bytepos+5]) * (long)(1<<16)) +
			((0xff & (int)bytebuf[bytepos+6]) * (long)(1<<8)) +
			((0xff & (int)bytebuf[bytepos+7]));
		}
		break;
	    case precenum.UINT64:
		for (ind = curelemnum, bytepos = 0; ind < newnumelems; ind++, bytepos += 8) {
		    retval[ind] =
			((0xff & (int)bytebuf[bytepos]) * (double)(1<<56)) +
			((0xff & (int)bytebuf[bytepos+1]) * (long)(1<<48)) +
			((0xff & (int)bytebuf[bytepos+2]) * (long)(1<<40)) +
			((0xff & (int)bytebuf[bytepos+3]) * (long)(1<<32)) +
			((0xff & (int)bytebuf[bytepos+4]) * (long)(1<<24)) +
			((0xff & (int)bytebuf[bytepos+5]) << 16) +
			((0xff & (int)bytebuf[bytepos+6]) << 8) +
			((0xff & (int)bytebuf[bytepos+7]));
		}
		break;
	    case precenum.FLOAT32:
		for (ind = curelemnum, bytepos = 0; ind < newnumelems; ind++, bytepos += 4) {
		    retval[ind] =
			java.lang.Float.intBitsToFloat(
			    ((0xff & (int)bytebuf[bytepos]) << 24) |
			    ((0xff & (int)bytebuf[bytepos+1]) << 16) |
			    ((0xff & (int)bytebuf[bytepos+2]) << 8) |
			    ((0xff & (int)bytebuf[bytepos+3])));
		}
		break;
	    case precenum.FLOAT64:
		for (ind = curelemnum, bytepos = 0; ind < newnumelems; ind++, bytepos += 8) {
		    retval[ind] =
			java.lang.Double.longBitsToDouble(
			    ((0xff & (long)bytebuf[bytepos]) << 56) |
			    ((0xff & (long)bytebuf[bytepos+1]) << 48) |
			    ((0xff & (long)bytebuf[bytepos+2]) << 40) |
			    ((0xff & (long)bytebuf[bytepos+3]) << 32) |
			    ((0xff & (long)bytebuf[bytepos+4]) << 24) |
			    ((0xff & (long)bytebuf[bytepos+5]) << 16) |
			    ((0xff & (long)bytebuf[bytepos+6]) << 8) |
			    ((0xff & (long)bytebuf[bytepos+7])));
		}
		break;
	    }
	    curelemnum += numelems;
	}
	pos += totalelems * elemlen;
	return retval;
    }
}
