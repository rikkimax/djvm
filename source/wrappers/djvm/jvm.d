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
module djvm.jvm;
import djvm.defs;
import djvm.bindings.jvm;

alias AlreadyCreatedJVMException = Exception;

/**
 * Wraps a Java VM instance.
 */
final class DJvm {
	package {
		JavaVM* jvm; }
		JNIEnv* env;
	//}

	private static {
		DJvm instance_;
	}

	private this(JavaVM* jvm, JNIEnv* env) {
		this.jvm = jvm;
		this.env = env;
		instance_ = this;
	}

	/**
	 * Finds a class based upon its full package + class name.
	 * 
	 * Params:
	 * 		name	=	The package and class name.
	 * 
	 * Returns:
	 * 		The class if found.
	 */
	JClass findClass(string name) {
		import std.string : tr;
		return new JClass(jvm, env, (*env).FindClass(env, toStringz(name.tr(".", "/"))));
	}

	/**
	 * Explicitly destroys this VM instance.
	 * 
	 * Because of implemention limitations of the JVM, this should almost never be called.
	 */	
	private void destroyJvm() {
		(*jvm).DestroyJavaVM(jvm);
	}

	static {
		/**
		 * Loads the bindings given common locations.
		 * 
		 * Has_been_tested_upon:
		 * 		- Windows 7 x64 with Java 1.8.20 x64
		 * 
		 * Params:
		 * 		vmLoc	=	Overriden location to load JVM's shared library from.
		 * Returns:
		 * 		If it was successful.
		 */
		bool prepare(string vmLoc = "") {
			if (DerelictJvm.isLoaded)
				return true;

			bool loadIt(bool withArg=true) {
				try {
					if (withArg)
						DerelictJvm.load(vmLoc);
					else
						DerelictJvm.load();
					return DerelictJvm.isLoaded;
				} catch(Error e) {
				} catch(Exception e) {
				}
				
				return false;
			}

			if (loadIt(false)) return true;

			// fallback!

			import std.process : execute;
			import std.algorithm : reverse;
			import std.path : buildNormalizedPath;
			import std.file : exists;
			import std.string : strip;

			auto java = execute(["java", "-verbose", "-version"]);
			// make sure we actually did run java
			if (java.status != 0 || java.output.length <= 1024)
				return false;

			char[] temp;
			ubyte stepEnd;
			
			foreach_reverse(c; java.output) {
				if (c == 'm') {
					stepEnd = 0;
				} else if (c == 'o' && stepEnd == 0) {
					stepEnd = 1;
				} else if (c == 'r' && stepEnd == 1) {
					stepEnd = 2;
				} else if (c == 'f' && stepEnd == 2) {
					temp = temp[0 .. $-4];
					break;
				}
				
				temp ~= c;
			}
			temp.reverse;
			temp = temp.strip;
			if (temp[$-1] == ']')
				temp.length--;

			// JDK 64bit windows/possible cross platform
			string filePath = buildNormalizedPath(temp, "../../bin/server/jvm.dll");
			// TODO: JDK 32bit windows/possible cross platform

			// JRE 64bit windows
			if (!filePath.exists)
				filePath = buildNormalizedPath(temp, "../../bin/client/jvm.dll");
			else { vmLoc = filePath; return loadIt; }
			// TODO: JRE 32bit windows

			// JDK 64bit linux
			if (!filePath.exists)
				filePath = buildNormalizedPath(temp, "lib/amd64/server/libjvm.so");
			else { vmLoc = filePath; return loadIt; }
			if (!filePath.exists)
				filePath = buildNormalizedPath(temp, "amd64/server/libjvm.so");
			else { vmLoc = filePath; return loadIt; }

			// TODO: JDK 32bit linux
			// TODO: JRE 64bit linux
			// TODO: JRE 32bit linux
			// TODO: JDK 64bit OSX
			// TODO: JRE 32bit OSX
			
			assert(0);
		}

		/**
		 * Gets an instance of the JVM wrapper.
		 * It creates the instance if it does not exist.
		 */
		DJvm getInstance() {
			if (hasInstance)
				return instance_;
			else
				return createInstance();
		}

		/**
		 * Creates a new instance of DJvm.
		 * Will fail if it has already been created.
		 * 
		 * Can be paired with JVMArguments to produce nice constructor based arguments.
		 * 
		 * Params:
		 * 		args	=	Arguments accepted by the JVM on CLI
		 * 
		 * Returns:
		 * 		A DJvm instance or throws an exception if it has already been created.
		 * 
		 * See_Also:
		 * 		JVMArguments
		 */
		DJvm createInstance(string[] args...) {
			import std.string : toStringz;
			if (hasInstance)
				throw new AlreadyCreatedJVMException("JVM has already been created");

			DJvm.prepare();

			JavaVMInitArgs vm_args;
			
			JavaVMOption[] options;
			options.length = args.length;
			foreach(i, arg; args) {
				options[i].optionString = cast(char*) toStringz(arg);
			}
			
			vm_args.version_ = JNI_VERSION_1_6;
			vm_args.nOptions = cast(int)args.length;
			vm_args.options = options.ptr;
			vm_args.ignoreUnrecognized = false;

			JavaVM* jvm;
			JNIEnv* env;

			JNI_CreateJavaVM(&jvm, cast(void**) &env, &vm_args);

			return new DJvm(jvm, env);
		}

		/**
		 * Has an instance of DJvm already been created?
		 * 
		 * Returns:
		 * 		If an instance of DJvm has already been created.
		 */
		bool hasInstance() {
			return instance_ !is null;
		}
	}
}

/**
 * Constructs arguments to the JVM
 */
struct JVMArguments {
	string[] arguments;
	alias arguments this;

	/**
	 * Class path setting
	 * 
	 * Params:
	 * 		The path to look at
	 */
	JVMArguments classPath(string path) {
		arguments ~= "-Djava.class.path=" ~ path;
		return this;
	}

	//TODO: more JVM arguments!
}

extern(System) export {
	private __gshared bool loadSTDFiles;

	jint JNI_OnLoad(JavaVM *vm, void *reserved) {
		import core.runtime:Runtime;
		Runtime.initialize();

		JNIEnv* env;
		(*vm).GetEnv(vm, cast(void**)&env, JNI_VERSION_1_6);
		DJvm vm_ = new DJvm(vm, env);

		return JNI_VERSION_1_6;
	}

	void JNI_OnUnload(JavaVM *vm, void *reserved) {
		import core.runtime:Runtime;
		Runtime.terminate();
	}
}

shared static this() {
	import std.stdio: stdin, stdout, stderr, File;
	// Loads up new instances of stdin/stdout/stderr if they have not been properly created

	if (stdin.error || stdout.error || stderr.error) {
		version(Windows) {
			import core.sys.windows.windows: GetStdHandle, STD_INPUT_HANDLE, STD_OUTPUT_HANDLE, STD_ERROR_HANDLE;

			File nstdin;
			nstdin.windowsHandleOpen(GetStdHandle(STD_INPUT_HANDLE), ['r']);
			stdin = nstdin;
			
			File nstdout;
			nstdout.windowsHandleOpen(GetStdHandle(STD_OUTPUT_HANDLE), ['w']);
			stdout = nstdout;
			
			File nstderr;
			nstderr.windowsHandleOpen(GetStdHandle(STD_ERROR_HANDLE), ['w']);
			stderr = nstderr;
		}
	}
}