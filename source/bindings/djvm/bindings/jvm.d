/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2015 James Mahler, Richard Andrew Cattermole
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
module djvm.bindings.jvm;

public {
	import djvm.bindings.functions;
	import djvm.bindings.types;
}

private {
	import derelict.util.loader;
	import derelict.util.system;
	
	static if( Derelict_OS_Windows ) {
		enum libNames = "jvm.dll";
	} else static if( Derelict_OS_Posix ) {
		enum libNames = "libjvm.so";
	}
	else
		static assert( 0, "Need to implement lua libNames for this operating system." );
}

class DerelictJVMLoader : SharedLibLoader {
	public this() {
		super(libNames);
	}
	
	protected override void loadSymbols() {
		bindFunc(cast(void**)&JNI_GetDefaultJavaVMInitArgs, "JNI_GetDefaultJavaVMInitArgs");
		bindFunc(cast(void**)&JNI_CreateJavaVM, "JNI_CreateJavaVM");
		bindFunc(cast(void**)&JNI_GetCreatedJavaVMs, "JNI_GetCreatedJavaVMs");
	}
}

__gshared DerelictJVMLoader DerelictJvm;

shared static this() {
	DerelictJvm = new DerelictJVMLoader();
}