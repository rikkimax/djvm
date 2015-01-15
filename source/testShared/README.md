How to build & run:

Shared library must be built with --build-mode=allAtOnce because dmd strips export symbols.

For 64bit:

```bash
dub build djvm:testshared --arch=x86_64 --build-mode=allAtOnce
cd bin
javac JNIFoo.java
java JNIFoo
```

For 32bit:

```bash
dub build djvm:testshared --build-mode=allAtOnce
cd bin
javac JNIFoo.java
java JNIFoo
```