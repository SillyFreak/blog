#import "/template/blog-post.typ": *

#show: blog-post(
  title: "Forays into Moodle development",
  author: "ensko",
  description: "Forays into Moodle development",
  published: "2025-07-14",
  // edited: "2025-07-14",
  tags: ("moodle",),
  excerpt: ```typ
  One of my goals for this summer is make updating Moodle courses from a Git repo realistic. These are my first steps.
  ```,
)

This post may end up being all over the place, but I hope one or two people end up finding some of this helpful.

== About Moodle

For those of you who don't know, #link("https://moodle.org/")[Moodle], the "modular object-oriented dynamic learning environment", is an immensely popular open-source e-learning software. It's written in PHP and at the time of writing, version 5.0 has just been released, so keep that in mind if you take any concrete information from here!

Moodle's initial release was back in August 2002 according to Wikipedia, and despite its impressiveness, its age is showing. Most navigation is server side; editing a detail of some assignment means loading a new page with a form, then submitting that form, triggering a second reload of the page, and so on. "Newer" UI concepts like drag-and-drop for reordering course contents are used in places, but these are introduced in a need-based fashion, so the overall experience is still very old-school, with some inconsistent but welcome modernizations mixed in.

(I can't really blame Moodle for that, though. If Microsoft doesn't manage to properly overhaul its system control panel in a way that actually improves it, why should I expect more from an open source project?)

== My Goal

All this is to say: Moodle does a lot of stuff, but if one could do it more... _comfortably_, I wouldn't mind. In particular, my ideal workflow for creating content such as learning resources is this:

- write some content in a Markdown or Typst file in my preferred editor
- all content is saved automatically instead of by submitting a web form
- once I'm satisfied with the content, commit and push the new files to a Git repository
- after waiting for a CI job, the content is visible to my students
- I can freely use branches, the history, etc. to manage drafts, rollback changes, collaborate, and so on.

... so basically like writing this blog! Except that the CI job needs to get the files into the correct database entries, instead of deploying static files to a web server.

I'm purposefully leaving out a lot right now: an assignment, for example, does not just consist of plain content; it also has a lot of specialized metadata like deadlines, grading schemes, visibility and availability requirements, etc. On top of that, an assignment is part of a specific course, and a section in that course, and comes at a specific position within that course, and so on.

So I'm limiting myself to a very small portion of all the things one can do in Moodle for now: I want to be able to replace the _content_ of some _existing_ resource via CI, without touching any other metadata. If I have to create the resource using the web interface, save its ID as metadata along the file on Github, but then can edit the resource (and multiple resources at the same time!) without having to touch the web UI, that would already be a great productivity boost!

And once that's achieved, hopefully adding some more metadata like titles and due dates becomes relatively simple.

== Interfacing with Moodle

If you're familiar with modern web dev, you're probably used to frontends written in some Javascript frontend framework that interfaces with a backend via a REST API, or maybe GraphQL. This makes it relatively easy to interface with the backend using something other than the web user interface, since the backend communicates with a program (the frontend) anyway.

Of course, that's not exactly a new invention. Before we started making "frontend apps", this methodology was called "asynchronous JavaScript and XML" or "Ajax", and #link("https://en.wikipedia.org/wiki/Ajax_%28programming%29")[Wikipedia] puts its appearance at 1999. We have mostly replaced XML with JSON, but at the core it's still the same.

At Moodle's inception Ajax was still a pretty new idea, and consequently Moodle is a more "traditional" kind of PHP web application. There is no dedicated frontend application running in the browser. Instead, submitting a form results in the backend sending a new complete HTML page to be displayed. This is ultimately simpler, but often results in re-sending a lot of unchanged information -- and importantly for _me_, it couples the backend with one specific kind of consumer: a human sitting in front of a browser!

#figure(image("assets/004/Ajax-vergleich-en.svg"), caption: [
  By DanielSHaischt, via Wikimedia Commons - Own work using: https://commons.wikimedia.org/wiki/File%3AAjax-vergleich.svg, CC BY-SA 3.0, https://commons.wikimedia.org/w/index.php?curid=29724785
])

This is of course a bit of an oversimplification; there are parts of Moodle that use Ajax -- but considering the huge amount of functionality that Moodle has amassed, and the relative recency of Ajax in the Moodle codebase, support for it is spotty. So what functionality _is_ available via web services for other clients? Well, basically what's needed by the #link("https://download.moodle.org/mobile")[Moodle mobile app].

And that app is not made for teachers editing courses. Bummer!

... so we need to add our own endpoints!

== Getting dirty with the Moodle codebase

... and to do that I need to write PHP -- yay! I admit, that's not exactly a thrilling prospect for me. I'll spare you a rant; I don't have a ton of PHP experience anyway, and none of it recent. If you want a well-researched but likewise over a decade out-of-date bashing of PHP, go right to #link("https://eev.ee/blog/2012/04/09/php-a-fractal-of-bad-design/")[PHP: a fractal of bad design] instead. One thing I'll note though: I was surprised to find that, in addition to `var_dump` and `var_export`, PHP has sprouted an additional `var_representation` since the last time I used it!

Anyway, back to Moodle. It wasn't exactly easy to get started; my goal was to achieve basically two things:

- use existing PHP functions to interact with "page" activities (i.e. simple content, even more basic than assignments where students can upload a solution), particularly replacing the content in there
- provide a web service to expose that functionality over the network.

My starting point was naturally the #link("https://moodledev.io/general/development/gettingstarted")[Getting Started Guide] for Moodle development; #link("https://github.com/moodlehq/moodle-docker")[moodle-docker] turned out to work flawlessly to easily install and run a Moodle server. Next came a look through the #link("https://moodledev.io/docs/5.0/apis/core")[API Guides] -- here things got a bit more challenging.

=== Programmatically setting page contents

None of the listed modules seemed to be relevant. I ended going directly to the sources, and spent a lot of time reading code in the `course` module -- which is not even listed as a core API -- and the `mod/page` module, the specific #link("https://moodledev.io/docs/5.0/apis/plugintypes/mod")[activity module] I was interested in.

If you're going down this path too, your reading of the code and docs may benefit from knowing a bit of terminology I was able to gather:

- In general, _courses_ can be structured into _sections_ and eventually contain _modules_. The sections were not really relevant for my purposes; they structure the course visually, but otherwise don't impact courses too much.
- The term _module_ is heavily overloaded, though. Strictly speaking, a module or _activity module_ is a kind of Moodle plugin, e.g. the `page` plugin, which resides in `mod/page` in the Git repository. The term can also refer to an _instance_ of such a module, though. In the web front end, that is usually referred to as an _activity_; in the codebase, the term _course module_ is fairly common, probably because module instances basically represent the m:n relationship between module and course.
  - The short form for course module is _cm_, and you'll have to handle _cmids_ frequently. The course module ID is the ID of that m:n table.
  // A course module has three important foreign keys: the course ID, the module ID (referring e.g. to `page` itself), and the plugin instance ID (referring to the instance of `page`).

Only much later did I realize by tracing some code paths, that the functions I really needed were `get_coursemodule_from_id` from `lib/datalib.php` and `update_module` from `course/lib.php`. An early attempt on that fruitful path looked roughly like this:

#zebraw(line-range: (2, none), ```php
<?php
$moduleinfo = get_coursemodule_from_id('page', $cmid, 0, false, MUST_EXIST);

// update the optional description
$moduleinfo->intro = "<p>new a</p>";
// update the proper page contents
$moduleinfo->content = "<p>new b</p>";

update_module($moduleinfo);
```)

The `intro` and `content` fields are indeed what they are called in the loaded object, but this doesn't change the actual page contents. The problem? `update_module` is geared towards processing data produced by a form, and overrides these two fields with what the supposed form's WYSIWYG inputs contained. In the code above, it doesn't find any of that, and thus doesn't change the contents.

With the following modifications, I was finally able to update the page contents:

#zebraw(line-range: (2, none), ```php
<?php
$moduleinfo = get_coursemodule_from_id('page', $cmid, 0, false, MUST_EXIST);

// the Moodle form stores the module ID in an extra field that is required by `update_module`
$moduleinfo->coursemodule = $cmid;
// this is the structure set by the WYSIWYG editor in the update form
$moduleinfo->introeditor = [
  "text" => "<p>new a</p>",
  "format" => FORMAT_HTML,
  // the itemid refers to a temporary file that may be used to set the content;
  // we don't use that and want to avoid related processing
  "itemid" => IGNORE_FILE_MERGE,
];
$moduleinfo->page = [
  "text" => "<p>new b</p>",
  "format" => FORMAT_HTML,
  // while the intro is part of the "general" module info,
  // this is specific to the "page" module type. The two need slightly different treatment.
  "itemid" => null,
];

update_module($moduleinfo);
```)

(This actually only worked from within the web service we're doing next due to permission checks, so if you're trying this exactly as written, don't be surprised if you get access errors. You'd also need to add some imports too; better just read on.)

=== Providing a web service

First task accomplished; the next step is to make that code available to my scripts as a web service. #link("https://moodledev.io/docs/5.0/apis/subsystems/external")[External services] live in plugins, and a #link("https://moodledev.io/docs/5.0/apis/plugintypes/local")[local plugin] is the right type for my purpose. Just like activity modules live in `mod/`, local plugins go into `local/`.

I made the mistake of also consulting `local/readme.txt`, which (apart from one link updated two years ago) has last been edited #link("https://github.com/moodle/moodle/commits/v5.0.1/local/readme.txt")[in 2015] -- so don't do that! It recommends some outdated practices such as using an `externallib.php` file instead of individual classes per web service function.

Likewise, be aware that the external services documentation page links to a few resources on https://docs.moodle.org/dev/, which is by its own statements no longer maintained (the newer developer docs are hosted under https://moodledev.io/). While for example the list of #link("https://docs.moodle.org/dev/Web_service_API_functions")[web service API functions] is still useful and isn't missing anything I could have used, keep that in mind when navigating the docs.

Anyway, after initial hiccups, adding my own plugin was relatively painless. Fortunately, my plugin does not save any data in the database on its own, which means I don't need to care about some of the more complex parts of plugins like DB schemata, backups, export, etc. I chose the name `resourceservice` for my plugin, added my `version.php` (see #link("https://moodledev.io/docs/5.0/apis/commonfiles#versionphp")[here]):

```php
<?php
defined('MOODLE_INTERNAL') || die();

$plugin->version = 2025070900;
$plugin->component = 'local_resourceservice';
```

... the mandatory translation file `lang/en/local_resourceservice.php` (see #link("https://moodledev.io/docs/5.0/apis/commonfiles#langenplugintype_pluginnamephp")[here]):

```php
<?php
$string['pluginname'] = 'Resource service plugin';
```

... my `db/services.php` (see #link("https://moodledev.io/docs/5.0/apis/subsystems/external/description#service-declarations")[here]):

```php
<?php
$functions = [
  'local_resourceservice_save_page_content' => [
    'classname'   => 'local_resourceservice\external\save_page_content',
    'description' => 'Replaces the intro and content of a specified page',
    'type'        => 'write',
    'ajax'        => true,
  ],
];

$services = [
  'resourceservice' => [
    'functions' => [
      'local_resourceservice_save_page_content',
    ],
    'shortname' =>  'resourceservice',
    'restrictedusers' => 0,
    'downloadfiles' => 1,
    'uploadfiles'  => 1,
  ],
];
```

... and finally my `classes/external/save_page_content.php` (see #link("https://moodledev.io/docs/5.0/apis/subsystems/external/functions#an-example-definition")[here]):

```php
<?php
namespace local_resourceservice\external;

use core_external\external_function_parameters;
use core_external\external_value;

require_once($CFG->dirroot.'/course/modlib.php');

class save_page_content extends \core_external\external_api {
  public static function execute_parameters() {
    return new external_function_parameters([
      'cmid' => new external_value(PARAM_INT, 'course module ID of the page to update'),
    ]);
  }

  public static function execute_returns() {
    return new external_value(PARAM_TEXT, 'the result');
  }

  public static function execute(int $cmid): string {
    ['cmid' => $cmid] = self::validate_parameters(self::execute_parameters(), ['cmid' => $cmid]);

    $moduleinfo = get_coursemodule_from_id('page', $cmid, 0, false, MUST_EXIST);

    $moduleinfo->coursemodule = $cmid;
    $moduleinfo->introeditor = [
      "text" => "<p>new a</p>",
      "format" => FORMAT_HTML,
      "itemid" => IGNORE_FILE_MERGE,
    ];
    $moduleinfo->page = [
      "text" => "<p>new b</p>",
      "format" => FORMAT_HTML,
      "itemid" => null,
    ];

    update_module($moduleinfo);

    return "ok";
  }
}
```

Just to be clear -- this code is _not_ cleaned up yet. Obviously I'm not even taking the contents as parameters to the function, and I'm returning `"ok"` instead of useful data or nothing at all, but I also have not added any permission checks yet; `update_module` says it does some, but I have not thought this through to make sure they are sufficient. It _is_ a functional proof of concept, though!

=== Setting up a testing environment

I'm telling you that all this works, but I haven't shown you how to run it yet. There's still a bit of Moodle configuration (creating a user, enabling the web service, etc.) necessary before using the web service. I'm not a fan of doing that manually, especially when I don't necessarily want to keep the Moodle Docker containers around and would have to repeat the settings. So here is one final PHP script based on #link("https://gist.github.com/timhunt/51987ad386faca61fe013904c242e9b4")[a gist by Tim Hunt]:

```php
<?php

define('CLI_SCRIPT', true);

// this script resides in `local/resourceservice/cli/webservicesetup.php`
// and want to require `config.php` from the root directory
require_once(__DIR__.'/../../../config.php');
require_once($CFG->dirroot.'/user/lib.php');
require_once($CFG->dirroot.'/webservice/lib.php');

$systemcontext = context_system::instance();

// Enable web services and REST protocol.
set_config('enablewebservices', true);
set_config('webserviceprotocols', 'rest');

// Create a web service user.
$webserviceuserid = user_create_user([
  'username' => 'resourceservice-user',
  'email' => 'resourceservice@example.com',
  'firstname' => 'Resource Service',
  'lastname' => 'User',
  'mnethostid' => $CFG->mnet_localhost_id,
  'confirmed' => 1,
]);

// Create a web service role.
$wsroleid = create_role('WS Role for Resource Service', 'ws-resourceservice-role', '');
set_role_contextlevels($wsroleid, [CONTEXT_SYSTEM]);
assign_capability('webservice/rest:use', CAP_ALLOW, $wsroleid, $systemcontext->id, true);

// Give the user the role.
role_assign($wsroleid, $webserviceuserid, $systemcontext->id);

// Enable the externalquiz webservice.
$webservicemanager = new webservice();
$service = $webservicemanager->get_external_service_by_shortname('resourceservice');
$service->enabled = true;
$webservicemanager->update_external_service($service);

// Authorise the user to use the service.
// skipped because I set `'restrictedusers' => 0` in `db/services.php`
// $webservicemanager->add_ws_authorised_user((object) ['externalserviceid' => $service->id, 'userid' => $webserviceuserid]);

// Create a token for the user.
$token = \core_external\util::generate_token(EXTERNAL_TOKEN_PERMANENT, $service, $webserviceuserid, $systemcontext);
print($token);
```

With all of this in place, you can set up #link("https://github.com/moodlehq/moodle-docker")[moodle-docker] and initialize everything:

```bash
git clone --depth 1 https://github.com/moodlehq/moodle-docker
cd moodle-docker

# see the "Quick start" section of the moodle-docker README
export MOODLE_DOCKER_WWWROOT=./moodle
export MOODLE_DOCKER_DB=pgsql
git clone --depth 1 -b v5.0.1 git://git.moodle.org/moodle.git $MOODLE_DOCKER_WWWROOT
cp config.docker-template.php $MOODLE_DOCKER_WWWROOT/config.php
bin/moodle-docker-compose up -d
bin/moodle-docker-wait-for-db

# now, make sure all the plugin files described here
# are present in `moodle/local/resourceservice/`

# see the "Use containers for manual testing" section of the README
bin/moodle-docker-compose exec webserver php admin/cli/install_database.php \
  --agree-license --fullname="Docker moodle" --shortname="docker_moodle" \
  --summary="Docker moodle site" --adminpass="test" --adminemail="admin@example.com"

# initialize the webservice and test user, print the token
bin/moodle-docker-compose exec webserver php local/resourceservice/cli/webservicesetup.php

# ... do stuff with the container

# Shut down and destroy containers
bin/moodle-docker-compose down
```

After running all these setup steps, you should see an API token for the newly generated test user on the console; you'll need that shortly.

What all these scripts have not set up is the actual course and page. So you'll still need to do the following steps in the Moodle web interface:

- log in as the admin user
- create a new course
- add the test user to the course with the teacher role
- create a page resource in that course, and note down the ID shown in the URL (if it's the first on this Moodle instance, the ID should be 2)

== Putting the new service to use

I'm not sure how the final scripts around this project will look like, but for now I'm testing with #link("https://hexatester.github.io/moodlepy/")[moodlepy]:

```py
from moodle import Moodle

url = 'http://localhost:8000/webservice/rest/server.php'
token = 'TODO'  # replace with the token from the setup

moodle = Moodle(url, token)

cmid = 2  # replace with the page ID you saw in the URL in your browser
result = (moodle('local_resourceservice_save_page_content', cmid=cmid))
print(result)
```

... and if everything went well, you should see `ok` printed to your console!

== Conclusion

This was a fairly long post, but we also covered a lot of ground. Moodle is a big piece of software, and while it didn't have the feature I needed (editing resources via a web API) out of the box, one thing that Moodle does really well is allowing you to add your own functionality in the form of plugins -- the #link("https://moodledev.io/docs/5.0/apis/plugintypes")[Plugin Types] page lists _dozens_ of kinds of plugins. We implemented one plugin of the `local` type, and offered a web service through it.

Moodle's documentation can be lacking at times, but since it's open source software, you can still get the information at least. I can't imagine how I would have figured out how the `update_module` function treats its arguments without looking at the source code, for example. I also can't imagine many pieces of software where the documentation would have been detailed enough to figure that out, so yay open source!

The actual implementation was only a few lines of code, so the work is really in the research. It's hard to recall every details of the journey, but I hope I included enough relevant links to be helpful for your own projects.

Good luck in your Moodle endeavors!
