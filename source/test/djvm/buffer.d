/**
 * Example showing how to utilise a java.nio.ByteBuffer from D.
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
import djvm;

unittest {
	DJvm djvm = DJvm.getInstance;

	JClass bbCls = djvm.findClass("java.nio.ByteBuffer");

	JStaticMethod allocate = bbCls.getStaticMethod("allocate", "(I)Ljava/nio/ByteBuffer;");
	jobject buffer = allocate.callObject(1024);

	JMethod putInt = bbCls.getMethod("putInt", "(I)Ljava/nio/ByteBuffer;");
	JMethod getInt = bbCls.getMethod("getInt", "()I");
	JMethod flip = bbCls.getMethod("flip", "()Ljava/nio/Buffer;");

	putInt.callObject(buffer, 1234);
	flip.callObject(buffer);
	int result = getInt.callInt(buffer);

	assert(1234 == result, "Did not get out what I put in");
}
