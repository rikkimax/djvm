import std.string;

import jni;

class JMethod {
	private JavaVM* jvm;
	private JNIEnv* env;
	private jclass cls;
	private jmethodID methodId;

	this(JavaVM* jvm, JNIEnv* env, jclass cls, jmethodID methodId) {
		this.jvm = jvm;
		this.env = env;
		this.cls = cls;
		this.methodId = methodId;
	}

	// TODO template this to get all the types
	// TODO vararg the last parameter
	void callVoid(jobject obj, int value) {
		(*env).CallVoidMethod(env, obj, methodId, value);
	}
}

class JStaticField {
	private JavaVM* jvm;
	private JNIEnv* env;
	private jclass cls;
	private jfieldID fieldId;

	this(JavaVM* jvm, JNIEnv* env, jclass cls, jfieldID fieldId) {
		this.jvm = jvm;
		this.env = env;
		this.cls = cls;
		this.fieldId = fieldId;
	}

	// TODO template this to get all the types
	jobject getObject() {
		return (*env).GetStaticObjectField(env, cls, fieldId);
	}
}

class JClass {
	private JavaVM* jvm;
	private JNIEnv* env;
	private jclass cls;

	this(JavaVM* jvm, JNIEnv* env, jclass cls) {
		this.jvm = jvm;
		this.env = env;
		this.cls = cls;
	}

	JStaticField getStaticField(string name, string signature) {
		return new JStaticField(jvm, env, cls, (*env).GetStaticFieldID(env, cls, toStringz(name), toStringz(signature)));
	}

	JMethod getMethod(string name, string signature) {
		return new JMethod(jvm, env, cls, (*env).GetMethodID(env, cls, toStringz(name), toStringz(signature)));
	}
}

class DJvm {
	private JavaVM* jvm;
	private JNIEnv* env;

	this(string classpath) {
		JavaVM *jvm;
		JNIEnv *env;

		JavaVMInitArgs vm_args;
		JavaVMOption[] options = new JavaVMOption[1];
		options[0].optionString = cast(char*) toStringz("-Djava.class.path=" ~ classpath);

		vm_args.version_ = JNI_VERSION_1_6;
		vm_args.nOptions = 1;
		vm_args.options = options.ptr;
		vm_args.ignoreUnrecognized = false;

		JNI_CreateJavaVM(&jvm, cast(void**) &env, &vm_args);
	}

	JClass findClass(string name) {
		return new JClass(jvm, env, (*env).FindClass(env, toStringz(name)));
	}

	void destroyJvm() {
		(*jvm).DestroyJavaVM(jvm);
	}
}

void main(string[] args) {
	DJvm djvm = new DJvm("/usr/lib/java");

	JClass systemCls = djvm.findClass("java/lang/System");
	JClass printCls = djvm.findClass("java/io/PrintStream");

	JStaticField field = systemCls.getStaticField("out", "Ljava/io/PrintStream;");
	jobject obj = field.getObject();

	JMethod method = printCls.getMethod("println", "(I)V");
	method.callVoid(obj, 100);

	djvm.destroyJvm();
}
