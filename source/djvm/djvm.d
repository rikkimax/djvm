import std.string;

import jni;

class DJvm {
	private JavaVM* jvm;
	private JNIEnv* env;

	this(string classpath) {
		JavaVM *jvm;
		JNIEnv *env;

		JavaVMInitArgs vm_args;
		JavaVMOption[] options = new JavaVMOption[1];
		options[0].optionString = cast(char*) toStringz("-Djava.class.path=/usr/lib/java");

		vm_args.version_ = JNI_VERSION_1_6;
		vm_args.nOptions = 1;
		vm_args.options = options.ptr;
		vm_args.ignoreUnrecognized = false;

		JNI_CreateJavaVM(&jvm, cast(void**) &env, &vm_args);
	}

	jclass findClass(string name) {
		return (*env).FindClass(env, toStringz(name));
	}

	jfieldID getStaticFieldID(jclass cls, string name, string signature) {
		return (*env).GetStaticFieldID(env, cls, toStringz(name), toStringz(signature));
	}

	jmethodID getMethodID(jclass cls, string name, string signature) {
		return (*env).GetMethodID(env, cls, toStringz(name), toStringz(signature));
	}

	// TODO template this to get all the types
	jobject getStaticObjectField(jclass cls, jfieldID fieldId) {
		return (*env).GetStaticObjectField(env, cls, fieldId);
	}

	// TODO template this to get all the types
	// TODO vararg the last parameter
	void callVoidMethod(jobject obj, jmethodID methodId, int value) {
		(*env).CallVoidMethod(env, obj, methodId, value);
	}

	void destroyJvm() {
		(*jvm).DestroyJavaVM(jvm);
	}
}

void main(string[] args) {
	DJvm djvm = new DJvm("/usr/lib/java");

	jclass systemCls = djvm.findClass("java/lang/System");
	jclass printCls = djvm.findClass("java/io/PrintStream");

	jfieldID fid = djvm.getStaticFieldID(systemCls, "out", "Ljava/io/PrintStream;");
	jobject out_ = djvm.getStaticObjectField(systemCls, fid);
	jmethodID mid = djvm.getMethodID(printCls, "println", "(I)V");
	djvm.callVoidMethod(out_, mid, 100);

	djvm.destroyJvm();
}
