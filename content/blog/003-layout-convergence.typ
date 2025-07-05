#import "/template/blog-post.typ": *

#show: blog-post(
  title: "Typst's dreaded \"Layout did not converge\" error",
  author: "SillyFreak",
  description: "Rewrite it (the Blog) in Typst",
  published: "2025-07-05",
  // edited: "2025-07-05",
  draft: true,
  tags: ("typst",),
	excerpt: ```typ
  If you've dabbled in writing more complex Typst code, you may have encountered the "Layout did not converge within 5 attempts" warning. What does it mean and what can you do?
	```,
)

All typesetting and word processing systems at one point face a problem in one way or another: if your document should have an outline, you need to somehow know what headings appear on what pages in your document, and then you need to insert that outline into the document itself:

#figure({
  import "@preview/fletcher:0.5.8": diagram, node, edge

  set text(0.85em, font: "FreeSans",)
  diagram(node-shape: circle, {
    let node = node.with(radius: 1.35cm, stroke: 0.5pt)
    node((150deg, 1.7cm), name: <a>)[we need to render the outline, so ...]
    node((30deg,  1.7cm), name: <b>)[we need to render the headings, so ...]
    node((270deg, 1.7cm), name: <c>)[#move(dy: -0.3em)[we need to know what's before the headings, so ...]]
    edge(<a>, <b>, "->", bend: 30deg)
    edge(<b>, <c>, "->", bend: 30deg)
    edge(<c>, <a>, "->", bend: 30deg)
  })
})

It's a classic chicken and egg situation! Where to start? Different systems have come up with different solutions:

- In MS Word, the outline is like a "snapshot" of what it should be. To refresh it, you need to #link("https://support.microsoft.com/en-us/office/update-a-table-of-contents-6c727329-d8fd-44fe-83b7-fa7fe3d8ac7a")[select it and press a button].

- LaTeX acts as though the document was empty on the first compile (creating an empty outline), but stores the heading information in an extra file. This way, a #link("https://latex-tutorial.com/tutorials/table-of-contents/")[second compilation] can use the correct information.

- Typst is similar to LaTeX in this respect, but it does the second compilation automatically.

In all of these cases, there is an underlying assumption: updating the document's outline won't change the information the outline is based on -- that is, the headings and the corresponding page numbers. But now, imagine this unlucky scenario:

#raw(block: true, lang: "typ", read("assets/003/outline-1.typ").trim())

Three things are important here:

- the width of the page is chosen so the heading fits barely in one line in the outline
- the page numbering uses roman numerals
- this appears on page "iv", which is followed by "v" -- and the latter numeral takes less space than the former!

The effect is that these two results are possible:

Either, the outline entry fits in one line, but that line wrongly says the heading is on page "v"; or it breaks into a second line, shifting the heading to page "v", to accomodate for page number "iv"! Your document will give you one of the two -- and a warning: "Layout did not converge within 5 attempts".

== Leaving outlines behind

#let example-posts = (
  "https://forum.typst.app/t/why-is-state-final-not-final/1483",
  "https://forum.typst.app/t/how-should-i-reasonably-debug-and-resolve-layout-did-not-converge-warnings/719",
  "https://forum.typst.app/t/how-to-get-rid-of-layout-did-not-converge-warning-when-pagebreaking-on-odd-pages/2916",
  "https://forum.typst.app/t/why-does-layout-diverge-with-automatic-theorem-numbering/2434",
)
#let links(words) = example-posts.zip(words.split()).map(args => link(..args)).join[ ]

This example is of course artificial, but outlines are unfortunately just one area where something like this can happen. Usually the result is that the produced PDF has some subtle error (like a wrong page number somewhere) -- and unfortunately, debugging this specific warning is likely the single hardest thing there is in Typst,
resulting #links("in several forum posts") on the topic.

In this true form of the problem, it doesn't matter how often we attempt to recompile the document; the layout _will_ keep changing, i.e. it does not _converge_. Determining this is the case #link("https://en.wikipedia.org/wiki/Halting_problem")[is hard], so Typst takes a shortcut: it stops trying after five attempts. On the plus side, this means the example document above doesn't put the Typst compiler into an infinite loop; on the minus side, if your document _actually_ needed six (or ten, or twenty) attempts -- well, you need to get it down to five.

Before we go on, I want to point out that the underlying problem is not specific to Typst. If a problem like this is present in Word or LaTeX, updating the table of contents/recompiling your document will give you a small change, but no indicator _that_ it is there. Chances are, you will just not notice it.

I will admit that one thing makes the problem "worse" in Typst: since Typst has actual usable scripting capabilities, it is way easier to produce these problems yourself outside of artificial examples like the one above.

== The usual suspect: chained state updates

A common source of the "layout did not converge" problem in Typst is when using #link("https://typst.app/docs/reference/introspection/state/")[`state`]. Typst does not support mutability, so this doesn't work at all:


```typc
let i = 1
let increment() = {
  // error: variables from outside the function are read-only and cannot be modified
  i = i + 1
}
increment()
i
```
#{
}

`state` is a sort of escape hatch, but you still need to treat it a bit differently from regular mutable variables. Take this *wrong* example that you may come up with translating the code from above:

```typc
let i = state("i", 1)
let increment() = {
  // `state.get()` can only be used when context is known, so add `context` here
  // the rest is a direct translation from above
  context i.update(i.get() + 1)
}
increment()
context i.get()  // 2
```
#{
}

At first glance, this seems to work, but the problem surfaces when you increment more often:

```typc
let i = state("i", 1)
let increment() = {
  context i.update(i.get() + 1)
}
for _ in range(6) { increment() }
context i.get()  // 5 - oops!
```
#{
}

Starting at one and incrementing six times should give 7, but only four increments have really gone through. We'll look at why that is in a second, but first I want to show you the *correct* way of doing this:

```typc
let i = state("i", 1)
let increment() = {
  // don't use `i.get()` - instead pass a function to update
  i.update(value => value + 1)
}
for _ in range(6) { increment() }
context i.get()  // 7 - yay!
```
#{
}

In this case it was fairly easy to get your document to compile in five iterations. The rationale behind Typst's relatively low limit of five is that this is the case for most convergence problems, and since each attempt makes your document slower to compile, making the limit not too high is desirable.

== Analyzing the problem with `layout-ltd`

So why does the `update`/`get` combo not work, and how can we debug something like this? The bad news is that there is no comprehensive story for debugging _all_ problems of this sort yet; the good news is that we at least have one new tool we can use in the fight -- The #link("https://typst.app/universe/package/layout-ltd")[layout-ltd package]:

#quote(block: true)[
  A simple package to limit the number of iterations the compiler will run to resolve context. [...]

  "Approved" by one of the creators of typst:

  #quote(block: true)[
    This is cursed

    -- \@laurmaedje
  ]
]

How does this help us? Well, let's add it to our broken example above, and only allow one iteration. I'll also replace the loop with individual calls and add debugging output:

```typc
import "@preview/layout-ltd:0.1.0": layout-limiter
show: layout-limiter.with(max-iterations: 2)

let i = state("i", 1)
let increment() = {
  context [(#i.get())]  // output for debugging
  context i.update(i.get() + 1)
}
increment()  // "one"
increment()  // "two"
increment()  // "three"
// (three are enough for this explanation)
context i.get()
```
#{
}

In total, the output is `(1)(1)(1)1`: if we don't allow any layout iterations beyond the first, then every instance of `i.get()` simply reads the initial value set by `state("i", 1)`, i.e. 1, and that is the final result. Note that we also have three `i.update()` calls in here as well (they just don't _do_ anything yet), and they _all_ use 1+1 as the parameter.

If we increase the layout iterations to 2, it gets a bit more complicated and we get `(1)(2)(2)2` as the output.
- The `get()` calls in "one" still return 1,
- In "two", we can now observe the update from "one". Since that update set the state to 2, we get `(2)` as the output, and the update sets the value to 2+1.
- In "three", we observe the updates from "one" and "two" as produced by the previous iteration -- _but they both contain the value 2!_ So the last one wins, and the debug output in this call is `(2)` as well.
- The final output observes three updates from the previous iteration, all of them setting the state to 2.

You may have guessed what happens if we allow three iterations (output `(1)(2)(3)3`):
- "one" and "two" are unchanged.
- "three" now observes the previous iteration's updates: "one" set the state to 2, "two" set the state to 3, and so "three" outputs 3 and sets the state to 3+1.
- The final output observes three updates from the previous iteration, the one from "three" setting the state to 3 being the deciding one.

... and in the fourth iteration, this shorter version of the document would finally converge: `(1)(2)(3)4`

So we can see that the `update()`s depending on `get()`s cascade iteration by iteration, and more than four updates chained like this would require more than five iterations.

How does the situation look with the corrected code?

```typc
import "@preview/layout-ltd:0.1.0": layout-limiter
show: layout-limiter.with(max-iterations: 1)

let i = state("i", 1)
let increment() = {
  context [(#i.get())]  // output for debugging
  i.update(value => value + 1)
}
increment()  // "one"
increment()  // "two"
increment()  // "three"
context i.get()
```
#{
}

Like before, the output is `(1)(1)(1)1` for the first iteration: none of the updates are yet considered. But the second iteration already gives us the desired `(1)(2)(3)4`. How does that look in detail?

Like before, all updates are already part of the document, but instead of using 1+1 as the new value they contain functions.
- In "one", the `get()` sees the initial value of 1.
- In "two", the `get()` is preceded by one update, and it calculates `value + 1`. Taking the initial value as the starting point, that's 2.
- In "three", the second visible update doesn't override the first one, but it again calculates a changed state. In total, the calculation here is 1+1+1.
- And the final value sees three functional updates of that kind, resulting in 1+1+1+1.

No cascading effects! The updates themselves don't depend on the state values, and can thus all be applied in a single iteration (after the initial one).

== Neat things about `layout-ltd`

I think `layout-ltd` is a great tool for debugging convergence warnings; it has already helped me identify one fairly complex problem, involving a conditionally displayed #link("https://github.com/SillyFreak/typst-alexandria")[Alexandria] bibliography _and_ the outline.

One thing that's really valuable is: when using `layout-ltd` in combination with the web app or Tinymist, you can hover over variables to see their values _at that iteration_. For example, hovering over the `i.get()` of the debugging output of the previous example (you need to hover over the parentheses in particular), you will see "1 (×3)", "1, 2 (×2)", or "1, 2, 3", depending on the iteration -- mirroring what I described above.

A valuable tool in determining the actual impact of the "layout did not converge" warning is to compile your document once with the default five iterations, and then again with only four. You can then compare the results of the two compilations -- either manually, or e.g. with image compare tools if you compile to PNGs.

Lastly, I want to show two more short examples, because they demonstrate some other things that you may encounter during a `layout-ltd` debugging session.

=== Unresolved references

```typc
import "@preview/layout-ltd:0.1.0": layout-limiter
show: layout-limiter.with(max-iterations: 1)

[
  = Heading <heading>

  // label `<heading>` does not exist in the document
  See @heading
]
```
#{
}

Resolving references is another task that, like outlines, requires looking at parts of the document that may not have been produced yet. That means that during the first iteration, _all_ references will be unresolved. Likewise, if you create labelled content depending on some state, corresponding references may only resolve even later.

=== Failing code in context

```typc
import "@preview/layout-ltd:0.1.0": layout-limiter
show: layout-limiter.with(max-iterations: 1)

[#metadata("value")<lbl>]

context query(<lbl>).first().value
```
#{
}

It should not come as a surprise by now that in the code above, `query(<lbl>)` won't find anything in the first iteration, and thus `first()` will fail. Typst will suppress errors that happen in earlier layout iterations, but with `layout-ltd` you may see them.

Neither of these should not concern you; just be aware that this can happen and what it means in context of compiling your document.

== Conclusion

The "Layout did not converge within 5 attempts" warning can be caused by truly diverging document layouts, or layouts that simply need more iterations. In the latter case, the solution is to find the source of the extra iterations. I strongly recommend you don't ignore this warning, as it can have unpredictable impacts on how your document turns out.

Debugging this warning can be very frustrating, but fortunately it doesn't show up regularly when using Typst. With `layout-ltd`, we also have a new tool to debug this problem, which I hope will help with many common instances of this issue. I encourage you to try it, and if you still can't find the problem, search or post on the #link("https://forum.typst.app/")[Typst forum] for help.
