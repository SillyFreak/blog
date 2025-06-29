#let blog-post(
  title: none,
  author: none,
  description: none,
  published: none,
  edited: none,
  tags: none,
  excerpt: none,
) = body => {
  let target = dictionary(std).at("target", default: () => "paged")

  [#metadata((
    title: title,
    author: author,
    description: description,
    published: published,
    edited: edited,
    tags: tags,
    excerpt: if excerpt != none { excerpt.text },
  )) <frontmatter>]

  show: rest => context {
    import "@preview/zebraw:0.5.5": zebraw-init, zebraw

    set page(height: auto, margin: 1cm) if target() == "paged"

    if target() == "html" {
      zebraw-init = zebraw-init.with(
        inset: (top: 0em, right: 0.34em, bottom: 0em, left: 0.34em),
      )
    }

    show: zebraw-init.with(
      lang: false,
      numbering: false,
    )
    show: zebraw.with(
      block-width: 100%,
      wrap: false,
    )
    rest
  }

  context if target() == "paged" [
    = #title

    #published #if edited != none [#sym.dot #edited]

    #tags.join[ #sym.dot ]

    #eval(excerpt.text, mode: "markup")

    #line(length: 100%)
  ]

  body
}