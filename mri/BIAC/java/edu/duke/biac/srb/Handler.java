package edu.duke.biac.srb;

import java.io.IOException;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLStreamHandler;

public class Handler extends URLStreamHandler
{
    public Handler() { super(); }
    public URLConnection openConnection(URL u) throws IOException {
	URLConnection uc = new SRBURLConnection(u);
	uc.connect();
	return uc;
    }
}
