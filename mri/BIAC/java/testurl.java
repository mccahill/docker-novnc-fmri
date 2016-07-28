import java.net.URL;
import java.io.InputStream;
import java.io.BufferedInputStream;

public class testurl
{
    public static void main(String[] args)
	throws java.net.MalformedURLException, java.io.IOException {
	URL u = new URL(args[0]);
	InputStream is = u.openStream();
	BufferedInputStream bis = new BufferedInputStream(is);
	byte [] buf = new byte [8192];
	int bytesread;
	while ((bytesread = bis.read(buf, 0, 8192)) > 0) {
	    System.out.write(buf, 0, bytesread);
	}
    }
}
