#let target = dictionary(std).at("target", default: () => "paged")

/// checks the `target()` (currently, `"paged"` and `"html"` are supported) and returns the
/// associated value in the passed named arguments. If there is none and there is a `default`
/// argument, that value is returned; otherwise there's a panic.
///
/// This function is contextual
///
/// Examples:
///
/// ```typc
/// match-target(html: "a", paged: "b")  // returns either "a" or "b"
/// match-target(html: "a", default: "b")  // returns either "a" or "b"
/// match-target(html: "a")  // returns either "a" or panics
/// ```
///
/// -> any
#let match-target(
  /// the possible options. only named arguments with the keys `paged`, `html` and `default` are
  /// allowed.
  /// -> arguments
  ..targets,
) = {
  assert.eq(targets.pos(), (), message: "positional arguments are not allowed")
  let targets = targets.named()
  for key in targets.keys() {
    assert(key in ("paged", "html", "default"), message: "unknown target: `" + key + "`")
  }
  let target = target()
  if target in targets {
    targets.at(target)
  } else if "default" in targets {
    targets.default
  } else {
    panic("no value specified for current target `" + target + "`")
  }
}

/// Wrapper around `match-target()` for target-specific show rules. All values should be functions
/// that you'd ordinarily give as `foo` to a `show: foo` rule. If no default is specified, it is set
/// to `it => it`, i.e. non-covered targets remain unchanged.
///
/// This function is _not_ contextual; it returns a function that provides its own context so that
/// it can be used in show-everything rules (see examples below) that don't provide their own
/// context.
///
/// Example:
///
/// ```typ
/// #show: show-target(paged: strong, html: doc => ...)
/// // is equivalent to
/// #show: show-target(paged: strong)
/// #show: show-target(html: doc => ...)
/// // is equivalent to (pseudocode)
/// #show: strong if target() == "paged"
/// #show: doc => ... if target() == "html"
/// ```
#let show-target(..targets) = body => context {
  match-target(default: it => it, ..targets)(body)
}

/// Wrapper around `match-target()` for target-specific values that should default to `none`;
/// particularly content, for which `none` simply has no effect. If no default is specified, it is
/// set to `none`.
///
/// This function is contextual
///
/// Example:
///
/// ```typ
/// #on-target(paged: [foo])  // returns either [foo] or none
///
/// #(1, 2, ..on-target(paged: (3,)), 4)  // returns either (1, 2, 3, 4) or (1, 2, 4)
/// ```
#let on-target(..targets) = {
  match-target(default: none, ..targets)
}
