/**
 * Internal code that helps generate and manipulate classes/fields and methods.
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
module djvm.helpers;
import djvm.jvm;

package string getJtype(string type) pure {
	import std.string : toLower;

	if (type == "Void") {
		return "void";
	}
	return "j" ~ toLower(type);
}

// FIXME: currently only will work for static fields
package string generateFieldGets(string[] types, string extra) pure {
	string rtn = "";
	foreach (ref string type; types) {
		rtn ~= getJtype(type) ~ " get" ~ type ~ "() { return (*env).Get" ~ extra ~ type ~ "Field(env, cls, fieldId); }\n";
	}
	return rtn;
}

package string generateFieldSets(string[] types, string extra) pure {
	string rtn = "";
	foreach (ref string type; types) {
		rtn ~= "void set" ~ type ~ "(" ~ getJtype(type) ~ " value) { return (*env).Set" ~ extra ~ type ~ "Field(env, cls, fieldId, value); }\n";
	}
	return rtn;
}

package string generateMethodCalls(string[] types, string extra, string extraMethodArgs, string callArg) pure {
	string rtn = "";
	foreach (ref string type; types) {
		string funcName = "call" ~ type;

		rtn ~= getJtype(type) ~ " " ~ funcName ~ "(" ~ extraMethodArgs ~ "...) {\n";
		rtn ~= "va_list args;\n";

		string firstArg = "this";
		if (extraMethodArgs != "") {
			// find last argument
			firstArg = "mixin(ParameterIdentifierTuple!" ~ funcName ~ "[$-1])";
		}

		version (X86)
			rtn ~= "va_start(args, " ~ firstArg ~ ");\n";
		else version (Win64)
			rtn ~= "va_start(args, " ~ firstArg ~ ");\n";
		else version (X86_64)
			rtn ~= "va_start(args, __va_argsave);\n";


		if (type == "Void") {
			rtn ~= "(*env).Call" ~ extra ~ type ~ "MethodV(env, " ~ callArg	~ ", methodId, args);\n";
		} else {
			rtn ~= "return (*env).Call" ~ extra ~ type ~ "MethodV(env, " ~ callArg ~ ", methodId, args);\n";
		}
		rtn ~= "}\n";
	}
	return rtn;
}