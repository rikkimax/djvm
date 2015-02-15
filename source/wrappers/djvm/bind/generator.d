module djvm.bind.generator;
import djvm.bind.defs;
import djvm.bind.helpers;

string generateJavaClass(string name, DEFINITIONS...)(string packageFile = __MODULE__) {
	import std.string : tr;
	string fqnName = packageFile ~ "." ~ name;

	string ret;
	ret ~= "class " ~ name ~ " : ";
	size_t textLength = ret.length;

	/// Add the inheritance information
	foreach(definition; DEFINITIONS) {
		parseDefinition!(definition, true)(fqnName, ret);
	}
	parseDefinition!(InheritFrom!JRootObject, true)(fqnName, ret);

	ret.length -= 2;
	ret ~= " {\n";

	/// adds default constructor based upon the java object id
	ret ~= "\tthis(jobject id) {\n";
	ret ~= "\t\tmyJavaObjectID_ = id;\n";
	ret ~= "\t}\n";
	
	/// The object instances id
	ret ~= "\tprivate jobject myJavaObjectID_;\n";
	ret ~= "\t@property jobject myJavaObjectId() { return myJavaObjectID_; }\n";
	
	/// The classes type id
	ret ~= "\tstatic {\n";
	ret ~= "\t\tprivate JClass myJavaClassID_;\n";
	ret ~= "\t\t@property JClass myJavaClassId() {\n";
	ret ~= "\t\t\tif (myJavaClassID_ is null) myJavaClassID_ = DJvm.getInstance.findClass(\"" ~ fqnName ~ "\");\n";
	ret ~= "\t\t\treturn myJavaClassID_; }\n";
	ret ~= "\t}\n\n";
	
	/// The definitions passed in via DEFINITIONS
	foreach(definition; DEFINITIONS) {
		parseDefinition!(definition, false)(fqnName, ret);
	}

	/// Type mangled name
	ret ~= "\n\tstatic @property string javaMangleOf() pure { return \"" ~ (packageFile ~ "." ~ name).tr(".", "/") ~ "\"; }\n";
	
	ret ~= "}\n";
	return ret;
}

/**
 * TODO:
 * 		Caching method/field ids
 * 		MyObjectType
 */
void parseDefinition(definition, bool doInheritDefinition)(string fqnName, ref string ret) {
	import djvm.bindings.types;
	import std.traits : fullyQualifiedName, moduleName;
	import std.conv : text;

	enum isStatic = isStaticAttribute!definition;

	enum isf = isField!definition;
	enum ism = isMethod!definition;
	enum isif = isInheritFrom!definition;
	enum isc = isConstructor!definition;

	static if (isf) {
		static if(!doInheritDefinition) {
			/// get
			
			
			ret ~= "\t@property ";
			static if (isStatic)
				ret ~= "static ";
			
			ret ~= fullyQualifiedName!(typeof(definition.value)) ~ " " ~ definition.name ~ "() {\n";
			ret ~= "\t\tJNIEnv* env = DJvm.getInstance.env;\n";
			
			static if (isStatic) {
				ret ~= "\t\tJStaticField field = myJavaClassId().getStaticField(\"" ~ definition.name ~ "\", \"" ~ getJavaTypeSignature!(typeof(definition.value)) ~ "\");\n";
				ret ~= "\t\tauto ret = (*env).GetStatic" ~ getJavaTypeNameSignature!(typeof(definition.value)) ~ "Field(env, myJavaClassId().cls, field.fieldId);\n";
			} else {
				ret ~= "\t\tJField field = myJavaClassId().getField(\"" ~ definition.name ~ "\", \"" ~ getJavaTypeSignature!(typeof(definition.value)) ~ "\");\n";
				ret ~= "\t\tauto ret = (*env).Get" ~ getJavaTypeNameSignature!(typeof(definition.value)) ~ "Field(env, myJavaObjectId(), field.fieldId);\n";
			}
			
			static if (is(typeof(definition.value) == string)) {
				//string
				ret ~= "\t\tint len = (*env).GetStringUTFLength(env, ret);\n";
				ret ~= "\t\tauto retv = (*env).GetStringUTFChars(env, ret, null);\n";
				ret ~= "\t\tstring retv2 = cast(string)retv[0 .. len].idup;\n";
				ret ~= "\t\t(*env).ReleaseStringUTFChars(env, ret, retv);\n";
				ret ~= "\t\treturn retv2;\n";
			} else static if (is(typeof(definition.value) == wstring)) {
				//wstring
				ret ~= "\t\tint len = (*env).GetStringLength(env, ret);\n";
				ret ~= "\t\tauto retv = (*env).GetStringChars(env, ret, null);\n";
				ret ~= "\t\twstring retv2 = cast(wstring)retv[0 .. len].idup;\n";
				ret ~= "\t\t(*env).ReleaseStringChars(env, ret, retv);\n";
				ret ~= "\t\treturn retv2;\n";
			} else static if (is(typeof(definition.value) : JRootObject)) {
				//object
				ret ~= "\t\treturn new " ~ fullyQualifiedName!(typeof(definition.value)) ~ "(cast(jobject)ret);\n";
			} else {
				// primitive
				ret ~= "\t\treturn cast(" ~ fullyQualifiedName!(typeof(definition.value)) ~ ")ret;\n";
			}
			
			ret ~= "\t}\n";
			
		
			///set
			
			
			ret ~= "\t@property ";
			static if (isStatic)
				ret ~= "static ";
			
			ret ~= "void " ~ definition.name ~ "(" ~ fullyQualifiedName!(typeof(definition.value)) ~ " toset) {\n";
			ret ~= "\t\tJNIEnv* env = DJvm.getInstance.env;\n";
			
			static if (isStatic) {
				ret ~= "\t\tJStaticField field = myJavaClassId().getStaticField(\"" ~ definition.name ~ "\", \"" ~ getJavaTypeSignature!(typeof(definition.value)) ~ "\");\n";
				ret ~= "\t\t(*env).SetStatic" ~ getJavaTypeNameSignature!(typeof(definition.value)) ~ "Field(env, myJavaClassId().cls, field.fieldId, ";
			} else {
				ret ~= "\t\tJField field = myJavaClassId().getField(\"" ~ definition.name ~ "\", \"" ~ getJavaTypeSignature!(typeof(definition.value)) ~ "\");\n";
				ret ~= "\t\t(*env).Set" ~ getJavaTypeNameSignature!(typeof(definition.value)) ~ "Field(env, myJavaObjectId(), field.fieldId, ";
			}
			
			static if (is(typeof(definition.value) == string)) {
				ret ~= "(*env).NewStringUTF(env, toset.toStringz)";
			} else static if (is(typeof(definition.value) == wstring)) {
				ret ~= "(*env).NewString(env, toset.ptr, cast(int)a" ~ TI ~  ".length)";
			} else static if (is(typeof(definition.value) : JRootObject)) {
				ret ~= "toset.myJavaObjectId()";
			} else static if (__traits(compiles, {jvalue.fromValue(typeof(definition.value).init);})) {
				ret ~= "toset";
			} else {
				static assert(0, typeof(definition.value).stringof ~ " cannot be used as type for java method call");
			}
			
			ret ~= ");\n\t}\n";
		}
	} else static if (ism) {
		static if(!doInheritDefinition) {
			static if (isStatic) {
				ret ~= "\tstatic ";
			} else {
				ret ~= "\t";
			}
			ret ~= fullyQualifiedName!(typeof(definition.returnValue)) ~ " " ~ definition.name ~ "(";
			
			foreach(i, arg; typeof(definition.args)) {
				ret ~= fullyQualifiedName!arg ~ " a" ~ text(i) ~ ", ";
			}
			static if (typeof(definition.args).length > 0)
				ret.length -= 2;
			ret ~= ") {\n";
			ret ~= "\t\tJNIEnv* env = DJvm.getInstance.env;\n";
			enum ARGNAMES = mixin("getJavaMethodSignature!(typeof(definition.returnValue), " ~ argNameList!(definition)("definition.args") ~ ")(false)");
			ret ~= "\t\tjmethodID mid = (*env).GetMethodID(env, myJavaClassId.cls, cast(const(char)*)\"" ~ definition.name ~ "\".toStringz, cast(const(char)*)\"" ~ ARGNAMES ~ "\".toStringz);\n";
			
			string conArgs;
			static if (__traits(hasMember, definition, "args")) {
				foreach(i, arg; typeof(definition.args)) {
					enum TI = text(i);
					static if (is(arg == string)) {
						conArgs ~= "(*env).NewStringUTF(env, a" ~ TI ~  ".toStringz), ";
					} else static if (is(arg == wstring)) {
						conArgs ~= "(*env).NewString(env, a" ~ TI ~  ".ptr, cast(int)a" ~ TI ~  ".length), ";
					} else static if (is(arg : JRootObject)) {
						conArgs ~= "a" ~ TI ~ ".myJavaObjectId(), ";
					} else static if (__traits(compiles, {jvalue.fromValue(arg.init);})) {
						conArgs ~= "jvalue.fromValue(a" ~ TI ~ "), ";
					} else {
						static assert(0, arg.stringof ~ " cannot be used as type for java method call");
					}
				}
				conArgs.length -= 2;
			}

			static if (__traits(hasMember, definition, "returnValue")) {
				static if (isStatic) {
					ret ~= "\t\tauto ret = (*env).CallStatic" ~ getJavaTypeNameSignature!(typeof(definition.returnValue)) ~ "Method(env, myJavaClassId().cls, mid, " ~ conArgs ~ ");\n";
				} else {
					ret ~= "\t\tauto ret = (*env).Call" ~ getJavaTypeNameSignature!(typeof(definition.returnValue)) ~ "Method(env, myJavaObjectId(), mid, " ~ conArgs ~ ");\n";
				}
				
				static if (is(typeof(definition.returnValue) == string)) {
					//string
					ret ~= "\t\tint len = (*env).GetStringUTFLength(env, ret);\n";
					ret ~= "\t\tauto retv = (*env).GetStringUTFChars(env, ret, null);\n";
					ret ~= "\t\tstring retv2 = cast(string)retv[0 .. len].idup;\n";
					ret ~= "\t\t(*env).ReleaseStringUTFChars(env, ret, retv);\n";
					ret ~= "\t\treturn retv2;\n";
				} else static if (is(typeof(definition.returnValue) == wstring)) {
					//wstring
					ret ~= "\t\tint len = (*env).GetStringLength(env, ret);\n";
					ret ~= "\t\tauto retv = (*env).GetStringChars(env, ret, null);\n";
					ret ~= "\t\twstring retv2 = cast(wstring)retv[0 .. len].idup;\n";
					ret ~= "\t\t(*env).ReleaseStringChars(env, ret, retv);\n";
					ret ~= "\t\treturn retv2;\n";
				} else static if (is(typeof(definition.returnValue) : JRootObject)) {
					//object
					ret ~= "\t\treturn new " ~ fullyQualifiedName!(typeof(definition.returnValue)) ~ "(cast(jobject)ret);\n";
				} else {
					// primitive
					ret ~= "\t\treturn cast(" ~ fullyQualifiedName!(typeof(definition.returnValue)) ~ ")ret;\n";
				}
			} else {
				static if (isStatic) {
					ret ~= "\t\t(*env).CallStaticVoidMethod(env, myJavaClassId().cls, mid, " ~ conArgs ~ ");\n";
				} else {
					ret ~= "\t\t(*env).CallVoidMethod(env, myJavaObjectId(), mid, " ~ conArgs ~ ");\n";
				}
			}
	
			ret ~= "\t}\n";
		}
	} else static if (isif) {
		static if(doInheritDefinition) {
			foreach(parent; typeof(definition.parents)) {
				ret ~= parent.stringof ~ ", ";
			}
		}
	} else static if (isc) {
		static if(!doInheritDefinition) {
			ret ~= "\tthis(";
			static if (__traits(hasMember, definition, "args")) {
				foreach(i, arg; typeof(definition.args)) {
					static if (__traits(compiles, {auto _ = moduleName!arg;}))
						mixin("static import " ~ moduleName!arg ~ ";");
					ret ~= fullyQualifiedName!arg ~ " a" ~ text(i) ~ ", ";
				}

				ret.length -= 2;
			}
			ret ~= ") {\n";

			ret ~= "\t\tDJvm djvm = DJvm.getInstance;\n";

			ret ~= "\t\tJNIEnv* env = djvm.env;\n";
			ret ~= "\t\tif (env is null) throw new NonCreatableClass(\"Cannot create a class, environement unknown.\");\n";

			enum ARGNAMES = mixin("getJavaMethodSignature!(void, " ~ argNameList!(definition)("definition.args") ~ ")");
			ret ~= "\t\tJMethod mid = myJavaClassId.getMethod(\"<init>\", \"" ~ ARGNAMES ~ "\");\n";
			ret ~= "\t\tif (myJavaClassId is null) throw new NonCreatableClass(\"Cannot create a class, unknown method constructor for arguments, " ~ ARGNAMES ~ ".\");\n";

			string conArgs;
			static if (__traits(hasMember, definition, "args")) {
				foreach(i, arg; typeof(definition.args)) {
					enum TI = text(i);
					static if (is(arg == string)) {
						conArgs ~= "(*env).NewStringUTF(env, a" ~ TI ~  ".toStringz), ";
					} else static if (is(arg == wstring)) {
						conArgs ~= "(*env).NewString(env, a" ~ TI ~  ".ptr, cast(int)a" ~ TI ~  ".length), ";
					} else static if (is(arg : JRootObject)) {
						conArgs ~= "a" ~ TI ~ ".myJavaObjectId(), ";
					} else static if (__traits(compiles, {jvalue.fromValue(arg.init);})) {
						conArgs ~= "jvalue(a" ~ TI ~ "), ";
					} else {
						static assert(0, arg.stringof ~ " cannot be used as type for java method call");
					}
				}
				conArgs.length -= 2;
			}

			ret ~= "\t\tmyJavaObjectID_ = (*env).NewObject(env, myJavaClassId.cls, mid.methodID, " ~ conArgs ~ ");\n";
			ret ~= "\t}\n";
		}
	} else {
		static assert(0, "Unknown definition");
	}
}