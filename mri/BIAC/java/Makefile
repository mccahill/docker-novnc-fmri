# Make sure to use version 1.1.8 -- Matlab won't recognize anything newer!
JDKDIR=/usr/java/j2sdk1.4.1_01
SRBHOME=/home/gadde/shares/users/gadde/SRB2.1.2

# linux
PLATFORM=linux
CLASSPATHSEP=":"
ROOTDIRPREFIX=

## cygwin
#PLATFORM=win32
#CLASSPATHSEP=";"
#ROOTDIRPREFIX=c:/cygwin/

###

CFLAGS=-g -O2 -Wall

PKGDIR=edu/duke/biac
PKGNAME=edu.duke.biac
BUILDDIR=$(ROOTDIRPREFIX)$(CURDIR)

JAVAC=$(JDKDIR)/bin/javac -classpath "$(BUILDDIR)$(CLASSPATHSEP)$(JDKDIR)/lib/classes.zip"
JAVAH=$(JDKDIR)/bin/javah -classpath "$(BUILDDIR)$(CLASSPATHSEP)$(JDKDIR)/lib/classes.zip"
JAR=$(JDKDIR)/bin/jar

JNIINCS=-I$(JDKDIR)/include -I$(JDKDIR)/include/$(PLATFORM)

SRBINCS=-DPORTNAME_$(PLATFORM)=1 -I$(SRBHOME)/src/include -I$(SRBHOME)/src/catalog/include -I$(SRBHOME)/utilities/include
SRBLIBS=-L$(SRBHOME)/obj -lSrbClient

JARFILE=srbclasses.jar
CLASSES=$(PKGDIR)/whollyInputStream.class $(PKGDIR)/srb/SRBInputStream.class $(PKGDIR)/srb/SRBURLConnection.class $(PKGDIR)/srb/Handler.class

LIB=libsrbnative.so
DLL=srbnative.dll
NATIVEOBJS=SRBInputStream.o SRBURLConnection.o

all: $(JARFILE) $(LIB) testurl.class

clean:
	rm -f $(JARFILE) $(CLASSES) $(LIB) $(NATIVEOBJS)

$(PKGDIR)/srb/SRBInputStream.class: $(PKGDIR)/srb/SRBInputStream.java
	cd $(PKGDIR)/srb; $(JAVAC) SRBInputStream.java

SRBInputStream.h: $(PKGDIR)/srb/SRBInputStream.java
	cd $(PKGDIR)/srb; $(JAVAH) -jni -o $(BUILDDIR)/SRBInputStream.h $(PKGNAME).srb.SRBInputStream
	touch SRBInputStream.h

SRBInputStream.o: SRBInputStream.c SRBInputStream.h
	$(CC) -c -o SRBInputStream.o SRBInputStream.c $(SRBINCS) $(JNIINCS)

$(PKGDIR)/srb/SRBURLConnection.class: $(PKGDIR)/srb/SRBURLConnection.java
	cd $(PKGDIR)/srb; $(JAVAC) SRBURLConnection.java

SRBURLConnection.h: $(PKGDIR)/srb/SRBURLConnection.java
	cd $(PKGDIR)/srb; $(JAVAH) -jni -o $(BUILDDIR)/SRBURLConnection.h $(PKGNAME).srb.SRBURLConnection
	touch SRBURLConnection.h

SRBURLConnection.o: SRBURLConnection.c SRBURLConnection.h
	$(CC) -c -o SRBURLConnection.o SRBURLConnection.c $(SRBINCS) $(JNIINCS)

$(PKGDIR)/srb/Handler.class: $(PKGDIR)/srb/Handler.java
	cd $(PKGDIR)/srb; $(JAVAC) Handler.java

$(PKGDIR)/whollyInputStream.class: $(PKGDIR)/whollyInputStream.java
	cd $(PKGDIR); $(JAVAC) whollyInputStream.java

$(JARFILE): $(CLASSES)
	$(JAR) cf $(JARFILE) $(CLASSES)

$(LIB): $(NATIVEOBJS)
	$(CC) -shared -o $(LIB) $(NATIVEOBJS) $(SRBLIBS)

$(DLL): $(NATIVEOBJS)
	dllwrap --output-def srbnative.def --add-stdcall-alias --driver-name gcc -o $(DLL) $(NATIVEOBJS) $(SRBHOME)/obj/libSrbClient.a /lib/libcygwin.a -Wl,-e,__cygwin_noncygwin_dll_entry@12 -s

testurl.class: testurl.java
	$(JAVAC) testurl.java
