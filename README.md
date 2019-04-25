Rack::SassC
===========

Rack middleware for processing sass/scss files. The current version has many 
limitations but feel free to send pull requests if you find a bug or if you wish 
to improve the functionnalities.

The current behaviour implies these limitations:

The files are processed each time they are requested. Since by default it does 
it only when not in production, the speed penalty is kind of acceptable. But I 
intend to improve it and use modification time.

The location of the public directory and directory names for CSS and SCSS are 
editable, but both are assumed to be directly placed inside the public 
directory.

The files cannot be nested, they are assumed to be directly inside the SCSS 
directory, and the generated files are therefore created directly inside the CSS 
directory.

There is no special error handling yet. Any error will raise a typical error 
page.

Installation
------------

Add this line to your application's Gemfile:

```ruby
gem 'rack-sassc'
```

And then execute:

```ruby
bundle install
```

Or install it yourself as:

```ruby
gem install rack-sassc
```

Usage
-----

In your `config.ru`:

```ruby
require 'rack/sassc'

use Rack::SassC
```

This is the basic usage with default behaviour, which is equivalent to using 
these options:

```ruby
require 'rack/sassc'

use Rack::SassC, {
  check: ENV['RACK_ENV'] != 'production',
  public_location: 'public',
  syntax: :scss,
  css_dirname: :css,
  scss_dirname: :scss,
  create_map_file: true,
}
```

Here is the explanation for each option:

`check` determines if the files are processed or not. Setting it to `false` is 
equivalent to not having the middleware at all. By default it is `true` if the 
rack environment is NOT `production`. The value of `check` can also be a Proc 
which receives the `env` on each request.

`public_location` is where you serve static files on your app. It is set to 
"public" by default. Whatever path you set it to will be expanded.

`scss_dirname` and `css_dirname` are just the name of the directories in which 
we search for template files and we generate css/map files.

`syntax` is `:scss` or `:sass`. It is used for the engine, but also for the 
extension of template files, which means they have to match.

`create_map_file` is self explanatory. No map file will be created if set to 
`false`.

Additionally, you can pass another option called `engine_opts`. It will be 
merged with the default options of the SassC engine. For example if you don't 
want a compressed output, you could do this:

```ruby
use Rack::SassC, {
  engine_opts: {style: :nested}
}
```

The default options for the engine are the following:

```ruby
{
  style: :compressed, 
  syntax: @opts[:syntax],
  load_paths: [location(@opts[:scss_dirname])],
}
```

Or this when no map file is to be created:

```ruby
{
  style: :compressed, 
  syntax: @opts[:syntax],
  load_paths: [location(@opts[:scss_dirname])],
  source_map_file: "#{filename}.css.map",
  source_map_contents: true,
}
```

Alternatives
------------

As far as I know the only alternative to this library is 
[SasscRack](https://github.com/hkrutzer/sasscrack) by 
[hkrutzer](https://github.com/hkrutzer) which arguably has a much better name 
than mine `;-)`

