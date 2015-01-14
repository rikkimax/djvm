import std.string;
import core.stdc.stdarg;

import jni;

// Mixin helper methods

private string getJtype(string type) {
	if (type == "Void") {
		return "void";
	}
	return "j" ~ toLower(type);
}

private string generateFieldGets(string[] types, string extra) {
	string rtn = "";
	foreach (ref string type; types) {
		rtn ~= getJtype(type) ~ " get" ~ type ~ "() { return (*env).Get" ~ extra ~ type ~ "Field(env, cls, fieldId); }\n";
	}
	return rtn;
}

private string generateFieldSets(string[] types, string extra) {
	string rtn = "";
	foreach (ref string type; types) {
		rtn ~= "void set" ~ type ~ "(" ~ getJtype(type) ~ " value) { return (*env).Set" ~ extra ~ type ~ "Field(env, cls, fieldId, value); }\n";
	}
	return rtn;
}

private string generateMethodCalls(string[] types, string extra, string argType) {
	string rtn = "";
	foreach (ref string type; types) {
		rtn ~= getJtype(type) ~ " call" ~ type ~ "(" ~ argType ~ " arg, ...) {\n";
		rtn ~= "va_list args;\n";
		rtn ~= "va_start(args, __va_argsave);\n";
		if (type == "Void") {
			rtn ~= "(*env).Call" ~ extra ~ type ~ "MethodV(env, arg, methodId, args);\n";
		} else {
			rtn ~= "return (*env).Call" ~ extra ~ type ~ "MethodV(env, arg, methodId, args);\n";
		}
		rtn ~= "}\n";
	}
	return rtn;
}

// Wrapped types

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

	mixin(generateMethodCalls(["Void", "Object", "Boolean", "Byte", "Char", "Short", "Int", "Long", "Float", "Double"], "", "jobject"));
}

class JStaticMethod {
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

	mixin(generateMethodCalls(["Void", "Object", "Boolean", "Byte", "Char", "Short", "Int", "Long", "Float", "Double"], "Static", "jclass"));
}


class JField {
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

	mixin(generateFieldGets(["Object", "Boolean", "Byte", "Char", "Short", "Int", "Long", "Float", "Double"], ""));
	mixin(generateFieldSets(["Object", "Boolean", "Byte", "Char", "Short", "Int", "Long", "Float", "Double"], ""));
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

	mixin(generateFieldGets(["Object", "Boolean", "Byte", "Char", "Short", "Int", "Long", "Float", "Double"], "Static"));
	mixin(generateFieldSets(["Object", "Boolean", "Byte", "Char", "Short", "Int", "Long", "Float", "Double"], "Static"));
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

	JField getField(string name, string signature) {
		return new JField(jvm, env, cls, (*env).GetFieldID(env, cls, toStringz(name), toStringz(signature)));
	}

	JStaticField getStaticField(string name, string signature) {
		return new JStaticField(jvm, env, cls, (*env).GetStaticFieldID(env, cls, toStringz(name), toStringz(signature)));
	}

	JMethod getMethod(string name, string signature) {
		return new JMethod(jvm, env, cls, (*env).GetMethodID(env, cls, toStringz(name), toStringz(signature)));
	}
	
	JStaticMethod getStaticMethod(string name, string signature) {
		return new JStaticMethod(jvm, env, cls, (*env).GetStaticMethodID(env, cls, toStringz(name), toStringz(signature)));
	}
}

class DJvm {
	private JavaVM* jvm;
	private JNIEnv* env;

	this(string classpath) {
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
	DJvm djvm = new DJvm("");
	scope(exit) {
		djvm.destroyJvm();
	}

	JClass systemCls = djvm.findClass("java/lang/System");
	JClass printCls = djvm.findClass("java/io/PrintStream");

	JStaticField field = systemCls.getStaticField("out", "Ljava/io/PrintStream;");
	jobject obj = field.getObject();

	JMethod method = printCls.getMethod("println", "(I)V");
	method.callVoid(obj, 100);
}
