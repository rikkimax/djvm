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
		JavaVM* jvm;
		JNIEnv* env;
	}

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
		return new JClass(jvm, env, (*env).FindClass(env, toStringz(name)));
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

			if (vmLoc == "") {
				import std.process : execute;
				import std.algorithm : reverse;
				import std.path : buildNormalizedPath;
				import std.file : exists;
				auto java = execute(["java", "-verbose", "-version"]);
				
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
				
				string filePath = buildNormalizedPath(temp, "../../bin/server/jvm.dll");
				if (!filePath.exists)
					filePath = buildNormalizedPath(temp, "lib/amd64/server/libjvm.so");
				
				// TODO: 32bit version?
				
				if (filePath.exists) {
					vmLoc = filePath;
				}
			}
			
			
			if (vmLoc != "") {
				try {
					DerelictJvm.load(vmLoc);
					return true;
				} catch(Exception e) {
				}
			}
			
			return false;
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

		/**
		 * Joins 
		 */
		private DJvm joinToJVM(JavaVM* vm) {
			if (hasInstance)
				throw new AlreadyCreatedJVMException("JVM has already been created");

			JNIEnv* env;
			(*vm).GetEnv(vm, cast(void**)env, JNI_VERSION_1_6);

			return new DJvm(vm, env);
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

extern(C) private @system {
	jint JNI_OnLoad(JavaVM *vm, void *reserved) {
		if (!DJvm.hasInstance) {
			JNIEnv* env;
			(*vm).GetEnv(vm, cast(void**)env, JNI_VERSION_1_6);
		
			DJvm inst = new DJvm(vm, env);
		}

		return JNI_VERSION_1_6;
	}

	//void JNI_OnUnload(JavaVM *vm, void *reserved) {}
}