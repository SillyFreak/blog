#import "libs.typ": zebraw.zebraw

#let zebraw = zebraw.with(
  block-width: 100%,
  wrap: false,
)

#let blog-post(
  title: none,
  author: none,
  description: none,
  published: none,
  edited: none,
  draft: false,
  tags: none,
  excerpt: none,
) = body => {
  import "libs.typ": (
    zebraw.zebraw-init,
    bullseye.show-target, bullseye.on-target,
  )

  [#metadata((
    title: title,
    author: author,
    description: description,
    published: published,
    edited: edited,
    draft: draft,
    tags: tags,
    excerpt: if excerpt != none { excerpt.text },
  )) <frontmatter>]

  // paged: setup page, link styling
  show: show-target(paged: rest => {
    set page(height: auto, margin: 1cm)
    show link: underline
    show link: set text(blue.darken(40%))
    rest
  })

  set figure(numbering: none)

  // setup zebraw
  show: rest => context {
    show: zebraw-init.with(
      lang: false,
      numbering: false,
      ..on-target(html: (
        inset: (top: 0em, right: 0.34em, bottom: 0em, left: 0.34em)
      )),
    )
    show: zebraw
    rest
  }

  // show metadata preview for paged display
  context on-target(paged: [
    = #title

    #published #if edited != none [#sym.dot #edited]

    #tags.join[ #sym.dot ]

    #eval(excerpt.text, mode: "markup")

    #line(length: 100%)
  ])

  show figure: show-target(html: it => {
    html.elem("figure", attrs: (class: "flex flex-col"), {
      html.frame(it.body)
      it.caption
    })
  })

  body
}