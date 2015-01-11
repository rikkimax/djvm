djvm
====
Copyright 2015 James Mahler
Licensed under the terms of the MIT license - See [LICENSE.txt](LICENSE.txt)

Allows for access to Java JVM from D.  Provide D'esk interfaces as the C interaction into JNI is messy to say the least.  This is a slow work in progress and currently just constantly seg faults.  I'm hoping someone else have any an interest and be able to fix the .h -> .d issues.

Motivation
----------
The main motivation behind this is to provide simple access to things that run on the JVM.  Two possibilities that come up immediately are JDBC and Hadoop.  Using JNI from C/C++ to embed a JVM into an application is one of the ways to provide database access.  To utilize technologies like HSQLDB, I believe it is currently the only way.

Getting Started
---------------
Requirements:
* Java VM (if using package manager, make sure to install -dev packages)
* D

Compiling:
* dmd -L/usr/lib/jvm/java-7-openjdk-amd64/jre/lib/amd64/server/libjvm.so djvm.d

Running:
* LD_LIBRARY_PATH=/usr/lib/jvm/java-7-openjdk-amd64/jre/lib/amd64/server ./djvm

Issues
------
Interacting with native libraries from D is not as easy as sometimes advertised.  You have to recreate the .h files into custom .d files.  The [source/djvm/jni.d](jni.d) file is where I believe the current issues lie.  It was auto-generated with dstep then hand edited.  It is no where close to complete or correct yet.  This is where I could use the most help.

Future Work
-----------
- [ ] Fix seg faults
- [ ] Make pretty wrapper
- [ ] Make pretty JDBC wrapper

