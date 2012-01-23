Casset
======

Casset is a very powerful, fine-grained, configurable asset-management library for Ruby.
It features an adapter for Sinatra, which is documented here.

Casset boasts:

  - Very easy control over which assets are displayed on what page.
  - Combining assets into "packfiles", to reduce the number of network connections.
  - Minifying assets with the minifier of your choice.
  - Parsing assets, supporting SASS, CoffeeScript, and anything else you can imagine.
  - Including assets in external files or inline.
  - Sourcing assets from external files, or from a string.
  - On-file caching of assets in `public/`, so they can be served as static files by your webserver.
 
Installing
----------

Casset isn't yet published on Rubygems (it will be in a little bit), so choose one of the following:

### gem/rake

```bash
$ git clone git://github.com/canton7/casset.git
$ cd casset
$ sudo rake install
```

### bundler

Add the following to your `Gemfile`:

```ruby
gem 'casset', :git => 'git://github.com/canton7/casset.git', :require => 'sinatra/casset'
```

Then run `bundle install`.

(Very) Quick Start
------------------

This is a very, very basic usage example.

I'm going to cover the case of a modular-style app, but Casset will work with Classic style as well.

Your main sinatra file:

```ruby
require 'sinatra/base'
require 'sinatra/casset'

class MyApp < Sinatra::Base
	register Sinatra::Casset
	get '/' do
		erb :index, :layout => true
	end
end
```

In `index.erb`:

```erb
# Say which assets this view needs
<%
# Assuming that public/js/file.js, public/js/another_file.js, and public/css/some_css_file.css exist
assets {
	js 'file.js', 'another_file.js'
	css 'some_css_file.css'
}
%>
This is my view's content
```

In `layout.erb`:

```erb
<html><head>
<%= assets.render %>
</head><body>
<%= yield %>
</body></html>
```

What we did there was to add some JS and CSS files to casset in our view (we could equally have done it in our route), then told Casset where to render them in our layout.  
Those files will be minified and combined, with the resulting two files written to `public/cache/`, which are then linked to.

Quick Syntax Intro
------------------

Just a quick note on Casset's syntax:

All of Casset's features are accessed through the `assets` method.  
You can either call methods directly, or through a block passed to `assets`, as shown below:

```ruby
# Single-command style
assets.js 'some_file.js'

# Block style 1
assets {
	js 'some_file.js'
}

# Block style 2
assets do |a|
	a.js 'some_file'
end
```

This syntax is available both as a helper (so it can be used in routes and views), and as a class method, so it can be used on `configure` blocks, etc.

I'll mix and match which syntax I use throughout this readme, but you're free to use whatever you like.

Groups Introduction
-------------------

To delve much deeper into Casset, we need to first understand groups.

A group is a set of JS and/or CSS assets which are (nearly) always included together.
An example might be 'global', 'jquery-ui', or 'admin_assets'.

When we combine assets, we stick them in the same file (called a "pack file"), to reduce the number of network connections and therefore overhead.
However, this means that if we include one extra asset in that pack file, we have to send the entire new pack file to the browser, not just the extra file.
There's no real way for a piece of software to determine which assets should be grouped together, so we leave this up to the user.

With this in mind, there are some pretty cool things we can do with groups:

  - You can enable or disable entire groups with a single command.
  - You can define dependencies between groups, so that if one group is enabled, everything that it depends on is enabled as well.

Although most groups are assumed to be fairy immutable (you're free to break this rule if you know what you're doing), there is one that isn't: `:page`.
This group is the intended destination of all assets which don't belong to any other group.
You'll see more on this in a minute.

Adding assets
-------------

There are two ways to add assets to Casset: By creating a new group (and specifying assets for it), or by adding assets to a group (and the group will be created if it doesn't already exist).

These are best shown by example:

```ruby
# Add a JS file to the default group (called :page)
assets.js 'myfile.js'

# Add two JS files and a CSS file to a new group, called :main
assets.js  :main, 'myfile.js', 'myotherfile.js'
assets.css :main, 'myfile.css'

# Create a new group, called :admin, with some files
assets.add_group :admin, :js => ['file1.js', 'file2.js'], :css => 'file.css'
# Add an extra file to :admin
assets.css :admin, 'file2.css'
```

Why two syntaxes? It all comes down to options.

Casset accepts lots of options (which the rest of this document will describe), each applies to a particular 'level' (global level, group level, file level, and some others).
However, options cascade downwards through the hierarchy.
This means that you can specify some options for all files (e.g. `:minify => false`), then override it for a particular group, then override it *again* for a particular file within that group.

Both `assets.add_group` and `assets.js` / `assets.css` accept options.
However, the former applies its options to the whole group, while the latter apply their options to just the file(s) specified.

(For convenience, group-only options that are passed to `casset.js` / `casset.css` are, in fact, applied to the group, but it's best to ignore this for now).

Parsing, Combining and Minifying
--------------------------------

### Parsing 

Parsing allows you to write you files in SASS, SCSS, CoffeeScript, or whatever floats your boat, and let Casset handle the chore of compiling them into JS/CSS and caching the result.

First, though, you need to define your own parser.
Why doesn't Casset provide you with built-in parsers?
Well, this way lets you customise your parser however you like, for almost no effort.

When defining a parser, you tell Casset whether you want it to act on JS or CSS files, and what file extensions to apply the parser to.
Then you give it a block, into which Casset which pass the content to be parsed, and from which you return the parsed content.
Simples.

```ruby
require 'sass'

# Somewhere in your app, before your routes. Probably in a `configure` block:
assets.add_parser(:css, 'scss') do |content|
	Sass.compile(content, :style => :expanded)
end
```

This then allows you to add CSS files as show below, and have them parsed into CSS.

```ruby
assets.css 'my_file.scss'
```

### Combining

Combining is the act of taking a group and sticking that group into as few pack files as possible, to reduce the overhead of extra network connections.

By default, combining is turned on.
To turn it off, or set combining options for groups and individual files:

```ruby
# Control combining for everything
assets.config(:combine => false)

# Override for a particular group
assets.add_group :my_group, :js => 'file.js', :combine => true
# Or, if the group already exists
assets.group_options :my_group, :combine => true

# To override for an individual file
assets.js :my_group, 'file.js', :combine => false
```

### Minifying

Minifying is the act of taking some JS or CSS, and making it look really ugly while also making it really small.
This, obviously, reduces the network bandwidth needed to sent the file to the client.

Minifying shares things in common with Parsing and Combining -- you need to define your own minifiers (again), but you can turn minifying off/on for everything, groups, and individual files.

Again, you start be defining a new minifier (same approach as for parsers, except you don't need to specify the file extension):

```ruby
require 'jsmin'

assets.set_minifier(:js) do |content
	JSMin.minify(content)
end

# We can enable/disble minification for everything
assets.config(:min => false)

# Or override that for a new group
assets.add_group :group_name, :min => true
# Or an existing group
assets.group_options :group_name, :min => true

# Or override for an individual file
assets.js :group_name, 'file.js', :min => false
```

