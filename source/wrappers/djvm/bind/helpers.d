module djvm.bind.helpers;
import djvm;

alias isField = isAttributeChecker!"Field";
alias isMethod = isAttributeChecker!"Method";
alias isInheritFrom = isAttributeChecker!"InheritFrom";
alias isConstructor = isAttributeChecker!"Constructor";

bool isStaticAttribute(T)() pure {
	return postStaticName(T.stringof) != T.stringof;
}

string getJavaMethodSignature(RETTYPE, T...)(bool byteAsChar = true) pure {
	string ret = "(";
	foreach(U; T) {
		import std.traits : isArray, fullyQualifiedName;
		ret ~= getJavaTypeSignature!(cast()U)(byteAsChar);
	}
	return ret ~ ")" ~ getJavaTypeSignature!RETTYPE(byteAsChar);
}

string getJavaTypeSignature(T)(bool byteAsChar = true) {
	import std.traits : isArray, isSomeString, fullyQualifiedName;
	static if (is(T == void))
		return "V";
	else static if (is(T == bool))
		return "Z";
	else static if (is(T == byte) || is(T == char))
		if (is(T == char) && !byteAsChar)
			return "C";
		else
			return "B";
	else static if (is(T == wchar))
		return "C";
	else static if (is(T == short))
		return "S";
	else static if (is(T == int))
		return "I";
	else static if (is(T == long))
		return "J";
	else static if (is(T == float))
		return "F";
	else static if (is(T == double))
		return "D";
	else static if (is(T : JRootObject))
			return "L" ~ T.javaMangleOf() ~ ";";
	else static if(isArray!T && !isSomeString!T) {
		T t;
		return "[" ~ getJavaTypeSignature!(typeof(cast()t[0]));
	} else static if (isSomeString!T)
		return "Ljava/lang/String;";
	else
		return "L" ~ fullyQualifiedName!T ~ ";";
}

string getJavaTypeNameSignature(T)(bool byteAsChar = true) {
	import std.traits : isArray, isSomeString, fullyQualifiedName;
	static if (is(T == void))
		return "Void";
	else static if (is(T == bool))
		return "Boolean";
	else static if (is(T == byte) || is(T == char))
		if (is(T == char) && !byteAsChar)
			return "Char";
		else
			return "Byte";
	else static if (is(T == wchar))
		return "Char";
	else static if (is(T == short))
		return "Short";
	else static if (is(T == int))
		return "Int";
	else static if (is(T == long))
		return "Long";
	else static if (is(T == float))
		return "Float";
	else static if (is(T == double))
		return "Double";
	else
		return "Object";
}

string argNameList(definition)(string prepend) pure {
	import std.conv : text;
	string ret;
	static if (__traits(hasMember, definition, "args")) {
		foreach(i, arg; typeof(definition.args)) {
			ret ~= "typeof(" ~ prepend ~ "[" ~ text(i) ~ "]), ";
		}
		
		ret.length -= 2;
	}
	return ret;
}

private {
	template isAttributeChecker(string textToCheck) {
		package bool isAttributeChecker(T)() pure {
			enum NAME = postStaticName(T.stringof);

			static if (NAME.length >= textToCheck.length) {
				return NAME[0 .. textToCheck.length] == textToCheck;
			} else {
				return false;
			}
		}
	}

	string postStaticName(string name) pure {
		if (name.length > 6 && name[0 .. 6] == "Static")
			return name[6 .. $];
		else
			return name;
	}
}