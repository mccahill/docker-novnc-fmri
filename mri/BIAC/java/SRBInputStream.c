#if defined(PORTNAME_win32)
#include <sys/cygwin.h>
typedef __int64_t __int64;
typedef unsigned long HANDLE;
#define MAX_PATH 260
#endif

#include <jni.h>

#include <scommands.h>
#include <mdasGlobalsExtern.h>
#include <clAuthExtern.h>

#include "SRBInputStream.h"

JNIEXPORT jint JNICALL
Java_edu_duke_biac_srb_SRBInputStream_read(JNIEnv *env, jobject this, jbyteArray jbuf, jint off, jint len)
{
    jclass thisclass;
    jfieldID srbconnfid;
    jfieldID fdescfid;
    srbConn *conn;
    int fdesc;

    int buflen;
    jbyte * buf;
    int bytesread;

    thisclass = (*env)->GetObjectClass(env, this);
    srbconnfid = (*env)->GetFieldID(env, thisclass, "srbconn", "J");
    fdescfid = (*env)->GetFieldID(env, thisclass, "fdesc", "I");
    
    conn = (srbConn *)((*env)->GetLongField(env, this, srbconnfid));
    fdesc = (int)(*env)->GetIntField(env, this, fdescfid);

    buflen = (*env)->GetArrayLength(env, jbuf);
    buf = (jbyte *)malloc(sizeof(jbyte)*len);
    (*env)->GetByteArrayRegion(env, jbuf, off, len, buf);
    bytesread = srbObjRead(conn, fdesc, buf, len);
    if (bytesread <= 0) {
	return -1;
    }
    (*env)->SetByteArrayRegion(env, jbuf, off, bytesread, buf);
    return (jint)bytesread;
}
