package edu.duke.biac.srb;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;

public class SRBURLConnection extends URLConnection {
    long srbconn;
    int fdesc;

    static {
	System.loadLibrary("srbnative");
    }

    public SRBURLConnection(URL url) {
	super(url);
    }

    public native void connect() throws IOException;
    public native void disconnect();
    
    public InputStream getInputStream() throws IOException {
	return new SRBInputStream(srbconn, fdesc);
    }
}
