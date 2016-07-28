import java.net.URL;
import java.net.URLStreamHandler;

public class SRBURLStreamHandlerFactory extends URLStreamHandlerFactory
{
    public SRBURLStreamHandlerFactory() { super(); }
    public URLStreamHandler createURLStreamHandler(String protocol) {
	if (protocol.equals("http")) {
	} else if (protocol.equals("file")
    }
}
