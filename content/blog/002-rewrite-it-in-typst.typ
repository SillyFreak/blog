#import "/template/blog-post.typ": *

#show: blog-post(
  title: "Rewrite it (the Blog) in Typst",
  author: "SillyFreak",
  description: "Rewrite it (the Blog) in Typst",
  published: "2025-06-29",
  // edited: "2025-06-29",
  tags: ("typst", "meta"),
	excerpt: ```typ
  Starting now, the posts you see on this blog are written with #link("https://typst.app/")[Typst] -- my current favorite tool to play and work with. In this post I'll go over the technical details of making this blog Typst-powered.
	```,
)

If you know me online or in real life, it has been impossible to miss how excited about #link("https://typst.app/")[Typst] I am. I felt motivated to write about Typst on a few occasions, but the prospect of writing about that new typesetting system _not using Typst_ tempered that motivation quite a bit... Well, that excuse won't work anymore, since this blog is now Typst-based!

I like to describe Typst like this: "imagine you had a typesetting system as powerful as LaTeX, but writing felt like Markdown and scripting felt like Python (or better, actually)." That may not exactly sound like a technology for creating HTML content, but that is currently changing: Typst now has #link("https://typst.app/docs/reference/html/")[experimental HTML export], and projects like #link("https://myriad-dreamin.github.io/shiroa/")[shiroa], #link("https://myriad-dreamin.github.io/typst.ts/")[typst.ts], or #link("https://github.com/overflowcat/astro-typst")[astro-typst] are already building on that early support to enable actual websites. A _big_ shoutout to their creators!

== The ingredients

Let's lay out what major pieces of software are involved:

- #link("https://astro.build/")[Astro] for the web and content management aspects
- #link("https://tailwindcss.com/")[Tailwind] for some light styling
- #link("https://github.com/overflowcat/astro-typst")[astro-typst] for integrating Typst into the thing
- #link("https://typst.app/universe/package/zebraw")[zebraw] for code syntax highlighting in HTML

To start off, I used Astro's official #link("https://github.com/withastro/astro/tree/main/examples/blog")[blog template], a well-structured, minimal template that I trusted to have sensible defaults for things I didn't want to spend much time on -- performance tweaks, SEO and so on. I then scanned Myriad-Dreamin's #link("https://github.com/Myriad-Dreamin/tylant")[tylant], an Astro template that integrates Typst, for the relevant parts and adapted them to my needs. For example, that template gets some Typst code from a git submodule, which I'm not a fan of, so I got rid of that peculiarity.

Most of the other work was then fairly mundane and not Typst specific: setting Astro up to find blog posts and offer them under my preferred URL scheme (`/2025/06/29/rewrite-it-in-typst`), adding Tailwind and recreating/re-applying the existing styles, and setting up automatic deployment.

There were however a few tweaks that I think may be interesting for people going in a similar direction:

== Conditional styling for non-HTML preview

One of the nice things about Typst is that it has instant preview; when you add a whole web app to that mix in the form of `npm run dev`, that experience is highly degraded compared to simply using #link("https://myriad-dreamin.github.io/tinymist/")[Tinymist]! Even though the non-HTML appearance of a blog post doesn't matter in the end, it's nice to see what you're writing in a bit more detail.

So I created a tiny "template" that blog posts would be based on, to add some of the content that is rendered by Astro in the final product:

#zebraw(
  highlight-lines: (6, 15, 22),
  ```typ
  #let blog-post(
    // ...
  ) = body => {
    // `target()` returns either "paged" or "html" -- and we ensure it exists even
    // when HTML is not supported
    let target = dictionary(std).at("target", default: () => "paged")

    // the <frontmatter> is how astro-typst makes post metadata available to Astro
    [#metadata((
      // ...
    )) <frontmatter>]

    show: rest => context {
      // `set page()` doesn't work for HTML output, so use `set ... if`
      set page(height: auto, margin: 1cm) if target() == "paged"
      // ...
      rest
    }

    // when not outputting to HTML, we show the info from the front matter
    // directly in the document
    context if target() == "paged" [
      = #title

      #published #if edited != none [#sym.dot #edited]

      #tags.join[ #sym.dot ]

      #eval(excerpt.text, mode: "markup")

      #line(length: 100%)
    ]

    body
  }
  ```
)

== Syntax highlighting in HTML-exported code snippets

One thing I seem to have missed while migrating adaptations from the tylant template was rendering of code blocks. Fortunately it wasn't hard to #link("https://github.com/Myriad-Dreamin/shiroa/blob/928726c3a783cfe003e2d31cd773de24665ced69/packages/shiroa/templates.typ#L35-L42")[track down the critical settings in shiroa] and adapt them for myself:

#zebraw(
  highlight-lines: (4, 21,),
  ```typ
  #import "@preview/zebraw:0.5.5": zebraw

  // `zebraw()` is exported with some defaults for use by blog posts
  #let zebraw = zebraw.with(
    block-width: 100%,
    wrap: false,
  )

  #let blog-post(
    // ...
  ) = body => {
    // ...

    show: rest => context {
      // ...

      import "@preview/zebraw:0.5.5": zebraw-init

      // only for HTML export, we want to adjust the insets since the line
      // spacing of zebraw is a bit too loose for my taste
      if target() == "html" {
        // replace `zebraw-init` with a function that has an extra parameter
        // applied
        zebraw-init = zebraw-init.with(
          inset: (top: 0em, right: 0.34em, bottom: 0em, left: 0.34em),
        )
      }

      // the other settings apply to both HTML and PDF export/live preview
      show: zebraw-init.with(
        lang: false,
        numbering: false,
      )
      show: zebraw
      rest
    }

    // ...

    body
  }
  ```
)

== Rendering an excerpt manually from Typst source code

The final puzzle piece (so far) was rendering an excerpt or blurb on overview pages; the text would be defined as part of the post's front matter and passed to Astro as Typst source code:

````typ
#show: blog-post(
  // ...
	excerpt: ```typ
  Starting now, the posts you see on this blog are written with
  #link("https://typst.app/")[Typst] -- my current favorite tool to play and
  work with. In this post I'll go over the technical details of making this
  blog Typst-powered.
	```,
)
````

My first attempt on this was using astro-typst #link("https://github.com/overflowcat/astro-typst?tab=readme-ov-file#as-a-component")[as a component]:

```html
<Typst code={code} target="html" />
```

However, this turned out to generate `<html>` tags etc. too, making the final markup invalid. It took a bit of searching, but the necessary functions for extracting just the body are also available in astro-typst:


#zebraw(
  highlight-lines: (4,),
  ```js
  import { renderToHTML } from "astro-typst/src/lib/typst";

  const excerpt = (data.excerpt && showExcerpt)
    ? (await renderToHTML({ mainFileContent: data.excerpt, body: true }, null)).html
    : null;
  ```
)
```html
<div set:html={excerpt} />
```

== Conclusion

I'm sure I will stumble over other things that still need some adaptation -- for example, I haven't tried adding images or math formulas yet -- but considering that Typst's HTML support is still experimental, this project (and others) have been a fairly smooth experience! This is of course thanks to both the Typst team and the Typst community; in this case chiefly #link("https://i.myriad-dreamin.com/")[Myriad-Dreamin], who as the maintainer of Tinymist, typst.ts and shiroa is a real powerhouse!

I hope setting this foundation will motivate me to write more here, be it about Typst or other topics.
