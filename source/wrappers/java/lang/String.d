module java.lang.String;
import djvm;

mixin JavaClass!("String", "java.lang",
	Constructor!(string),
	Constructor!(),
	
	Method!(char, "charAt", int),
	Method!(string, "concat", string),
	StaticMethod!(string, "valueOf", bool)
);