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
