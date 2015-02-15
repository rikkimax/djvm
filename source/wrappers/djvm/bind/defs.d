module djvm.bind.defs;

struct Field(T, string NAME) {
	enum name = NAME;
	T value;
}

alias StaticField = Field;

struct Method(RET, string NAME, ARGS...) {
	static if (!is(RET == void))
		RET returnValue;
	
	enum name = NAME;
	ARGS args;	
}

alias StaticMethod = Method;

struct InheritFrom(T...) {
	static T parents;
}

struct Constructor(T...) {
	static if (T.length == 0) {
		static bool isVoid = true;
	} else {
		static T args;
	}
}

mixin template JavaClass(string name, string packageName=__MODULE__, VALUES...) {
	public import djvm;
	private import djvm.bind.helpers;
	private import djvm.bind.generator : generateJavaClass;
	private import std.string : toStringz;
	private import core.stdc.stdarg;
	private import std.conv : to;

	pragma(msg, name);
	pragma(msg, VALUES);
	pragma(msg, generateJavaClass!(name, VALUES)(packageName));
	mixin(generateJavaClass!(name, VALUES)(packageName));
}

interface JRootObject {
	public import djvm;
	@property jobject myJavaObjectId();
}

alias NonCreatableClass = Exception;

/*
 * test stuff 
 */

/*interface Foo {}


mixin JavaClass!("MyJavaClass", __MODULE__, InheritFrom!(Object, Foo),
	Constructor!(int),

	Field!(int, "x"),
	StaticField!(double, "y"),

	Method!(void, "hello", string),
	StaticMethod!(void, "goodbye")
);
*/