#if defined(PORTNAME_win32)
#include <sys/cygwin.h>
typedef __int64_t __int64;
typedef unsigned long HANDLE;
#define MAX_PATH 260
#endif

#include <jni.h>

#include <string.h>

#include <scommands.h>
#include <mdasGlobalsExtern.h>
#include <clAuthExtern.h>

#include "SRBURLConnection.h"

JNIEXPORT void JNICALL
Java_edu_duke_biac_srb_SRBURLConnection_connect(JNIEnv * env, jobject this)
{
    srbConn *conn;
    int fdesc;
    jmethodID geturlmid;
    jmethodID getfilemid;
    jfieldID srbconnfid;
    jfieldID fdescfid;
    jobject jurl;
    jstring jurlstr;
    const char * urlstr;
    char * coll;
    char * objid;
    char * slashpos;
    
    geturlmid = (*env)->GetMethodID(env, (*env)->GetObjectClass(env, this), "getURL", "()Ljava/net/URL;");
    getfilemid = (*env)->GetMethodID(env, (*env)->FindClass(env, "java/net/URL"), "getFile", "()Ljava/lang/String;");
    srbconnfid = (*env)->GetFieldID(env, (*env)->GetObjectClass(env, this), "srbconn", "J");
    fdescfid = (*env)->GetFieldID(env, (*env)->GetObjectClass(env, this), "fdesc", "I");

    jurl = (*env)->CallObjectMethod(env, this, geturlmid);
    jurlstr = (*env)->CallObjectMethod(env, jurl, getfilemid);
    
    urlstr = (*env)->GetStringUTFChars(env, jurlstr, NULL);
    if ((slashpos = strrchr(urlstr, '/')) == NULL) {
	coll = strdup("");
	objid = strdup(urlstr);
    } else {
	size_t urllen = strlen(urlstr);
	size_t colllen = slashpos - urlstr;
	size_t objidlen = urllen - colllen - 1;
	coll = (char *)malloc(sizeof(char) * (colllen + 1));
	strncpy(coll, urlstr, colllen);
	coll[colllen] = '\0';
	objid = (char *)malloc(sizeof(char)*(objidlen + 1));
	strncpy(objid, slashpos + 1, objidlen);
	objid[objidlen] = '\0';
    }
    (*env)->ReleaseStringUTFChars(env, jurlstr, urlstr);

//    (*env)->DeleteLocalRef(env, jurl);
//    (*env)->DeleteLocalRef(env, jurlstr);

    conn = clConnect(NULL, NULL, NULL);
    if (conn->status != CLI_CONNECTION_OK) {
	char * errmsg = clErrorMessage(conn);
	clFinish(conn);
	(*env)->ThrowNew(env, (*env)->FindClass(env, "java/io/IOException"), errmsg);
	return;
    }
    if ((fdesc = srbObjOpen(conn, objid, O_RDONLY, coll)) < 0) {
	char * errmsg = clErrorMessage(conn);
	clFinish(conn);
	(*env)->ThrowNew(env, (*env)->FindClass(env, "java/io/IOException"), errmsg);
	return;
    }
    (*env)->SetLongField(env, this, srbconnfid, (jlong)(unsigned int)conn);
    (*env)->SetIntField(env, this, fdescfid, (jint)fdesc);
}

JNIEXPORT void JNICALL
Java_edu_duke_biac_srb_SRBURLConnection_disconnect(JNIEnv * env, jobject this)
{
    jfieldID srbconnfid;
    jfieldID fdescfid;
    srbConn *conn;
    int fdesc;

    srbconnfid = (*env)->GetFieldID(env, (*env)->GetObjectClass(env, this), "srbconn", "J");
    fdescfid = (*env)->GetFieldID(env, (*env)->GetObjectClass(env, this), "fdesc", "I");
    
    conn = (srbConn *)(unsigned int)(*env)->GetLongField(env, this, srbconnfid);
    fdesc = (int)(*env)->GetIntField(env, this, fdescfid);
    srbObjClose(conn, fdesc);
    clFinish(conn);
}
