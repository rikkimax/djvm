import djvm;
import jni;

version(unittest) {

	unittest {

		DJvm djvm = new DJvm("");
		scope(exit) {
				  djvm.destroyJvm();
		}

		JClass bbCls = djvm.findClass("java/nio/ByteBuffer");

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
}
