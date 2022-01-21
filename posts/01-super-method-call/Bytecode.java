class A {
	public void foo() {}
}

class B extends A {
	public void bar() {
		this.foo();
		super.foo();

		int i = 0;
		String s = "" + i;
	}
}
