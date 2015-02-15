/**
 * Example of how to do a raw D function to be called from java.
 * 
 * License:
 *     The MIT License (MIT)
 *    
 *     Copyright (c) 2015 James Mahler, Richard Andrew Cattermole
 *    
 *     Permission is hereby granted, free of charge, to any person obtaining a copy
 *     of this software and associated documentation files (the "Software"), to deal
 *     in the Software without restriction, including without limitation the rights
 *     to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *     copies of the Software, and to permit persons to whom the Software is
 *     furnished to do so, subject to the following conditions:
 *    
 *     The above copyright notice and this permission notice shall be included in all
 *     copies or substantial portions of the Software.
 *    
 *     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *     AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *     OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *     SOFTWARE.
 */
module Java_JNIFoo;
import djvm;

void testfunc(JNIEnv* env) {
	//writeln("Running unittest");
	try {
		import java.lang.String;
		import std.stdio;
		String str = new String("Hello there!");

		writeln(str.charAt(0));
	} catch(Error e) {
		import std.file;
		write("error.txt", e.toString());
	} catch(Exception e) {
		import std.file;
		write("error.txt", e.toString());
	}
	//assert(str.charAt(0) == 'H');
	//assert(str.charAt(5) == 'o');
}

extern(System)
export {
	jstring Java_JNIFoo_nativeFoo(JNIEnv* env, jobject obj) {
		import core.runtime;
		Runtime.initialize();

		testfunc(env);
		return (*env).NewStringUTF(env, "foo: Test program of JNI.\n\0");
	}
}