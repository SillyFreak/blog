#import "/template/blog-post.typ": *

#show: blog-post(
  title: "The Typst Package Lifecycle",
  author: "SillyFreak",
  description: "The Typst Package Lifecycle",
  published: "2025-08-15",
  // edited: "2025-08-15",
  tags: ("typst",),
  excerpt: ```typ
  Writing and publishing Typst packages requires some repeated steps. Here is an overview of what's involved.
  ```,
)

I write a lot of Typst packages and also co-maintain the Typst community's #link("https://github.com/typst-community/typst-package-template")[typst-package-template].
As such, I'm very interested in making the package authoring experience as smooth as possible.
The package template helps with a lot of stuff, but I think it doesn't serve everyone perfectly.
Its #link("https://en.wikipedia.org/wiki/Continuous_integration")[CI] automation is based on bash scripts, which is problematic for Windows and to a lesser extent also OS X users who want to perform the same tasks locally.
It also means that the automation parts are harder to maintain and less flexible than they could be.

And also, simply, these automation scripts have grown too much.
The package template should be just that: a _package template_, not a collection of package management tools.
It's unavoidable that a package template will contain some scripts; after all, it should relieve us package authors of work.
But those scripts should call well-made tools such as #link("https://typst-community.github.io/tytanic/")[Tytanic] instead of trying to implement them in an inferior way.

As a first step towards trimming these scripts, I think it's worth spelling out what writing and publishing packages entails.
I'm trying to think from first principles here; my bias will make this align a lot with the current package template, but I'm trying to describe the more general processes.
Not all of these will be relevant to _all_ packages, but I hope to capture the steps that could possibly be involved.
// Let me know on #link("https://discord.gg/2uDybryKPe")[Discord] or the #link("https://forum.typst.app/")[Forum] if I missed something.

= The package writing lifecycle  // looks -- to me at least -- roughly as follows:

- *Create a new repository.*
  Right now, I use the #link("https://github.com/typst-community/typst-package-template")[package template] repo to create this right on Github, then I adapt settings such as the package name in various places.
  Other ecosystems have different approaches to initializing a new project; for example NPM has a command #link("https://docs.npmjs.com/cli/v11/commands/npm-init")[`npm init`] that lets you select an NPM package which acts as a boilerplate and initialization script.
  #link("https://github.com/cargo-generate/cargo-generate")[`cargo generate`] seems to be similar, but it's not Rust's standard solution for this purpose: #link("https://doc.rust-lang.org/cargo/commands/cargo-init.html")[`cargo init`] is the built-in facility. It doesn't let you select a template, instead it only sets some basic properties like the package name.

  One advantage of having this done by a tool instead of directly copying a template repo is that it allows for more flexibility.
  For example, right now the package template contains an #link("https://github.com/typst-community/typst-package-template/blob/main/docs/manual.typ")[empty `manual.typ`] file.
  Users can't configure the template, just clone it, so we keep it minimal.
  Configuring the package as a Typst template or selecting a license would be other use cases.
  Had we a tool that offers template configuration, we could offer more opinionated options.

- *Write the code.*
  This is the one that scripts and tools won't be able to automate:
  a package without the code to function won't work.

  A feature that's useful in this stage though are _editable installs_.
  For example in Python, #link("https://docs.astral.sh/uv/concepts/projects/dependencies/#editable-dependencies")[`uv add --editable`] and #link("https://pip.pypa.io/en/stable/cli/pip_install/#install-editable")[`pip install --editable`] can install a local package by linking to it, meaning changes in source code are reflected without reinstalling.
  An editable install lets you try out your package without having to reinstall it every time you change something.
  This kind of installation has its limitations though: Typst packages can `exclude` files in their `typst.toml`, but an editable install will simply contain all project files.

- *Test your code.*
  For this we have #link("https://typst-community.github.io/tytanic/")[Tytanic], which lets us run Typst test files and compare the result either against another Typst file or pre-compiled images. Upcoming features of Tytanic are testing templates and HTML export, so I think we're doing pretty well there.

  Testing can and should also be done in CI, which has the benefit that each test is performed in a fresh environment, not "polluted" by local settings present on a developer's machine:
  no extra fonts, locally installed packages, uncommitted changes on the local file system, etc.

- *Write documentation.*
  Good documentation is fundamental for having software that's useful to others.
  Typical Typst package documentation consists of a guide, applying the package to some use case, and a reference, listing all provided modules, functions and constants that users can find in the package.
  For the latter, we have #link("https://typst.app/universe/package/tidy")[Tidy];; like with code, the writing itself is our job.
  One approach to authoring technical documentation that someone recently shared on Discord is #link("https://diataxis.fr/")[Diátaxis];; the link still sits unread in a background tab of mine... hopefully some day!

  Documentation needs to be published.
  One way is to prepare a PDF manual and link to that; since that is what Tidy helps most with, that is what I currently do.
  More convenient for someone just casually browsing potentially interesting packages is HTML documentation.
  #link("https://myriad-dreamin.github.io/shiroa/")[shiroa] can help with that, but as far as I'm aware it doesn't help you generate a reference from Tidy-style doc comments.
  The second part to publishing as HTML is hosting; shiroa's docs themselves are hosted on Github Pages, so #link("https://github.com/Myriad-Dreamin/shiroa/blob/main/.github/workflows/gh_pages.yml")[its CI configuration] can serve as inspiration for that.

  Last but not least, the `README`.
  This is what is shown on Universe, so it will usually be the first contact potential users have with a package.
  A concise description and example, ideally with screenshots of the results, are important here.

- *Prepare for release.*
  Once the content (code and docs) is in place, there's a bunch of stuff to do before a release:

  - Increment the package version number (major, minor or patch).
    This has to happen in the `typst.toml` file as well as all documentation and examples.
    I haven't used it manually, but I imagine #link("https://github.com/typst/package-check")[typst/package-check] would be useful for this.
  - Add a new release to the changelog.
    Describe changes there if you haven't done so over the normal course of development.
  - If you keep track of it, record the release date in relevant places.
  - Perform a pre-release test.
    Your code works, but will it work when installed from Universe?
    Ideally, you test this by installing the package (exactly as it would be from Universe) and then running tests against that installation: no `#import "lib.typ"`, instead `#import "@preview/package:0.1.1"`.

    That may sound like overkill, but it _can_ catch errors.
    For example, if a file is `exclude`d in `typst.toml`, accessing it will succeed in your project repository but not in a proper install. But granted, it's comparatively easy to avoid such errors simply by being careful.
  - Rebuild docs if applicable.
    If you have a PDF manual, that PDF needs to be updated.
    If you use HTML, that can probably be handled by CI in the actual publishing step.

- *Bundle your package.*
  Now that the package is ready for release, it needs to be brought into a shape fit for publishing, which I call "bundling".
  There are two ways bundling can be viewed/two targets for it:

  - To publish to Universe, all non-development files should be collected and copied to the target location.
    For example, it makes no sense to upload test cases to Universe.
    The package template uses a file called `.typstignore` to exclude these.

    Should files in `.gitignore` be skipped as well?
    Intuitively I think yes, but there could be files that should be part of your package and are created during a build step -- for example a WASM plugin.
    Personally, I don't put my WASM plugins into `.gitignore` to make my plugin-powered packages easier to install from the repo, but that would be an argument to not skip `.gitignore`'d files during bundling, only `.typstignore`'d ones.
  - To build an installable package (such as those hosted on Universe: https://packages.typst.org/preview/example-0.1.0.tar.gz), files `exclude`'d in `typst.toml` need to be skipped as well.
    This kind of installable bundle is what will end up in your cache (when importing directly from Universe) or your local package directory (when installing a package through a package manager or otherwise).

- *Publish the results.*
  The last step in that long chain is to actually make the results available to the public.
  This step consists of

  - Creating a Git tag in your repository to permanently identify the code that went into this release.
  - Creating a Github release under that tag.
    According to your preferences, that release can contain content from the changelog as the description, list contributors to the release, contain bundles for users and package managers to download, and whatever else you find important.
  - For public packages, creating a pull request to #link("https://github.com/typst/packages/")[typst/packages].
  - For private packages, deploying in some other way.

  Needless to say, the bundling and publishing steps can be heavily automated.
  That makes the process less tedious and less susceptible to manual errors.

In summary, once your package repository is created, there are some recurring tasks that make up the package development experience: coding, testing, documenting, and eventually publishing. Especially the testing and publishing parts can be automated to a big extent, and there are several tools that support us in writing and publishing documentation.

= Installing packages

I have alluded to this, but kept my comments on it short before, since installing Typst packages is not specific to _authoring_ your own packages.
Still, there are a few things to mention.

In the simplest case, you don't need to do anything for installation.
If the package you want to use is on Universe, Typst will fetch and cache the package automatically for you.
However, there are several reasons why that might not be the case:

- The package you need, or its latest update, has not been published (yet).
- You are looking to contribute to the package and need the development version.
- You are running tests in CI and want to install the package to be tested.
- The package is private, i.e. it is in principle complete, but simply isn't on Universe; it can be found somewhere else though -- probably somewhere credentials are required.

The way I see it, installing a package requires knowing three things about it:

- *Source:*
  Where does the package come from?
  Options include:

  - A local directory
  - A Git repository that can be cloned or scanned for releases
  - A URL pointing to a bundled package (including URLs pointing to Universe)

- *Destination:*
  Where should the install go?

  - Typst's installation location; this will be the most common destination since it means Typst can now import the package.
    This option also requires specifying the namespace to install to.
  - A custom directory; this is convenient when the files should be further processed.
    For example, preparing a Universe pull request can be viewed as installing the package into a clone of the #link("https://github.com/typst/packages/")[typst/packages] repo.
  - A pull request: as an alternative to the above, using a git repository as the destination would also be an option -- although I feel that it's easier and sufficient to build this up from the simpler "install to directory" option.
  - A zip or tar.gz archive; by treating this as an installation location, we are basically unifying installation and bundling into a single concept.

- *Mode:*
  How should the files be prepared, and which should be included?
  This means basically the three options mentioned before:

  - An editable install (which will not make sense for all sources and destinations)
  - A bundle for publishing: exclude based on `.typstignore`
  - A bundle for installing: additionally exclude based on `exclude` in `typst.toml`

By supporting various combinations of these three factors, "installation" covers a lot of common package tasks:
preparing pull requests and release bundles, installing locally, downloading packages from the internet, and allowing to integrate with additional scripts (which are unavoidable, even if we want to reduce their scope).
