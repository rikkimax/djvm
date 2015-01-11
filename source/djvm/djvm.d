import std.stdio;
import std.string;
import jni;

void main(string[] args) {
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

        jclass systemCls = (*env).FindClass(env, cast(const(char)*)toStringz("java/lang/System"));
        jclass printCls = (*env).FindClass(env, "java/io/PrintStream");

        jfieldID fid = (*env).GetStaticFieldID(env, systemCls, "out", "Ljava/io/PrintStream;");
        jobject out_ = (*env).GetStaticObjectField(env, systemCls, fid);
        jmethodID mid = (*env).GetMethodID(env, printCls, "println", "(I)V");
        (*env).CallVoidMethod(env, out_, mid, 100);

        (*jvm).DestroyJavaVM(jvm);

	writeln("hello");
}
