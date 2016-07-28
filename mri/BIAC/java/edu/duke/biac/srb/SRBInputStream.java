package edu.duke.biac.srb;

import java.io.InputStream;
import java.io.IOException;

public class SRBInputStream extends InputStream {
    long srbconn;
    int fdesc;

    static {
	System.loadLibrary("srbnative");
    }

    public SRBInputStream(long connid, int fd) {
	super();
	srbconn = connid;
	fdesc = fd;
    }

    public int read() throws IOException {
	byte buf [] = new byte [1];
	int result = read(buf, 0, 1);
	if (result != 1) {
	    return -1;
	}
	return (int)buf[0];
    }
    
    public native int read(byte[] b, int off, int len) throws IOException;
}
