---
title: Calling Superclass Methods
published: 2022-01-21
edited: null
categories:
  - Java
excerpt: A common mistake I see Java beginners make is to call methods like `super.foo()` indiscriminate when subclassing is involved. However, there's a subtle difference between that and regular method calls.
---

When creating a subclass, a common situation is to overwrite a method, but using the original class' logic in doing so.
Let's say we have a class for sending messages, and we want to make a variant that is written in a more formal style.
In doing so, we want to preserve the "simple message formatting" logic that the superclass implements.
A simple approach could look like this:

```java
class Message {
	private final String sender, receiver, content;

	// ... constructor & getters ...

	public void send() {
		// simple message formatting
		System.out.println(getContent());
	}
}

class FormalMessage extends Message {
	public FormalMessage(String sender, String receiver, String content) {
		super(sender, receiver, content);
	}

	@Override
	public void send() {
		// formal message formatting
		System.out.println("Dear " + super.getReceiver() + ",");
		super.send();
		System.out.println("Sincerely, " + super.getSender());
	}
}
```

This might look alright: when overriding `send`, we need to use `super.send()` to avoid an accidental recursion.
For consistency, why not also use `super.getReceiver()`?
Well, consider this extension:

```java
class extends FormalIncognitoMessage {
	public FormalIncognitoMessage(String sender, String receiver, String content) {
		super(sender, receiver, content);
	}

	@Override
	public void getSender() {
		return "Anonymous";
	}
}
```

```java
		Message m = new FormalIncognitoMessage("SillyFreak", "World", "Hello.");
		m.send();

		// Dear World,
		// Hello.
		// Sincerely, SillyFreak
```

What happened here? Well, that `super` is not only special in an overridden method, it generally fixes the implementation of the method to use to that of the superclass.

A regular non-static method call in Java uses "dynamic dispatch": at runtime, the class of the object the method is called on is used to determine what variant is called.
For example, `formalMessage.getSender()` uses the implementation in `Message`, because it wasn't overwritten.
`formalMessage.send()` would use the implementation in `FormalMessage`.

But `super.getSender()` uses "static dispatch" instead.
That code is located in class `FormalMessage`, so `super` refers to class `Message` - even if the actual object is of type `FormalIncognitoMessage` and that type's superclass would be `FormalMessage`.
So the `getSender()` implementation of `Message` is used, even if there is a more specific one as well.

# Method calls on the bytecode level

So `super` works differently - that means we should be able to spot the difference in the compiled code, and indeed we can.
Let's create a more simplified example for looking at this:

```java
class A {
	public void foo() {}
}

class B {
	public void bar() {
		this.foo();
		super.foo();
	}
}
```

If we compile this and then look at `B`'s bytecode:

```shell
javac *.java
javap -c B.class
```

We get this:

```bytecode
  public void bar();
    Code:
       0: aload_0
       1: invokevirtual #7                  // Method foo:()V
       4: aload_0
       5: invokespecial #12                 // Method A.foo:()V
       8: return
```

We can roughly read this as (for a more proper understanding, take a look at [stack machines](https://en.wikipedia.org/wiki/Stack_machine), of which the JVM is an example):

- Load the `this` object (`aload_0`).
- On that object, do a regular dynamic method call to `void foo()`.
	The word "virtual" here refers to the fact that this is implemented by using a [virtual function table](https://en.wikipedia.org/wiki/Virtual_method_table) or vtable.
	The `#7` here is an index at which the method name `foo` and signature `()V` are stored within the class file.
- The `this` was "consumed" by that call, so load it again for the second call.
- On this object, do a "special" method call to that same method.
	Note how the method is specified as `A.foo:()V`:
	the class to search for `foo` is compiled into this instruction instead of determined from `this` at runtime.
- Finally, the method returns to the caller, whoever that was.
	We don't write that return in Java (for `void` methods), but at the JVM level it's a important part of what a method does.

There are other kinds of method calls in the JVM.
They are not the topic here, but if you're interested, try calling static methods and constructors, or this surprisingly intricate piece of code:

```java
int i = 0;
String s = "" + i;
```

# Conclusion

The difference between `this.foo();` and `super.foo();` is bigger than it may first seem. Having an accidental `super` method call somewhere will work at first and only make problems when the class hierarchy gets more complex - so it's important to avoid mixing the two up from the start.
