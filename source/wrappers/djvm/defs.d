/**
 * Internal code that helps wrap classes/fields and methods so they can be called in D.
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
module djvm.defs;
import djvm.bindings.jvm;
import djvm.helpers;
import std.string : toStringz;
import std.traits : ParameterIdentifierTuple;
import core.stdc.stdarg;

/*
 * A class
 */

final class JClass {
	package {
		JavaVM* jvm;
		JNIEnv* env; }
	jclass cls;
	
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

/*
 * Fields
 */

final class JField {
	package JavaVM* jvm;
	package JNIEnv* env;
	package jclass cls;
	package jfieldID fieldId;
	
	this(JavaVM* jvm, JNIEnv* env, jclass cls, jfieldID fieldId) {
		this.jvm = jvm;
		this.env = env;
		this.cls = cls;
		this.fieldId = fieldId;
	}
	
	mixin(generateFieldGets(["Object", "Boolean", "Byte", "Char", "Short", "Int", "Long", "Float", "Double"], ""));
	mixin(generateFieldSets(["Object", "Boolean", "Byte", "Char", "Short", "Int", "Long", "Float", "Double"], ""));
}

final class JStaticField {
	package JavaVM* jvm;
	package JNIEnv* env;
	package jclass cls;
	package jfieldID fieldId;
	
	this(JavaVM* jvm, JNIEnv* env, jclass cls, jfieldID fieldId) {
		this.jvm = jvm;
		this.env = env;
		this.cls = cls;
		this.fieldId = fieldId;
	}
	
	mixin(generateFieldGets(["Object", "Boolean", "Byte", "Char", "Short", "Int", "Long", "Float", "Double"], "Static"));
	mixin(generateFieldSets(["Object", "Boolean", "Byte", "Char", "Short", "Int", "Long", "Float", "Double"], "Static"));
}

/*
 * Methods
 */

final class JMethod {
	package JavaVM* jvm;
	package JNIEnv* env;
	package jclass cls;
	package jmethodID methodId;
	
	this(JavaVM* jvm, JNIEnv* env, jclass cls, jmethodID methodId) {
		this.jvm = jvm;
		this.env = env;
		this.cls = cls;
		this.methodId = methodId;
	}
	
	mixin(generateMethodCalls(["Void", "Object", "Boolean", "Byte", "Char", "Short", "Int", "Long", "Float", "Double"], "", "jobject obj, ", "obj"));
}

final class JStaticMethod {
	package JavaVM* jvm;
	package JNIEnv* env;
	package jclass cls;
	package jmethodID methodId;
	
	this(JavaVM* jvm, JNIEnv* env, jclass cls, jmethodID methodId) {
		this.jvm = jvm;
		this.env = env;
		this.cls = cls;
		this.methodId = methodId;
	}
	
	mixin(generateMethodCalls(["Void", "Object", "Boolean", "Byte", "Char", "Short", "Int", "Long", "Float", "Double"], "Static", "", "cls"));
}