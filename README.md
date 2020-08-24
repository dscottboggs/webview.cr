# webview.cr

[![Build Status](https://cloud.drone.io/api/badges/dscottboggs/webview.cr/status.svg)](https://cloud.drone.io/dscottboggs/webview.cr)

A library for creating desktop applications using Crystal and web technologies.
It uses a lightweight web view for rendering HTML and CSS, and features a
utility for ergonomic calls to Crystal from Javascript and vice-versa.

## Installation

1. (Linux/BSD only) Install `webkit2gtk` from your package manager:
   |OS|Package name|Notes|
   |--|------------|-----|
   |Arch/Manjaro|webkit2gtk||
   |Ubuntu|webkit2gtk-4.0-dev||
   |OpenSUSE|webkit2gtk3-devel||
   |Fedora|webkit2gtk3-devel||
   |Alpine|webkit2gtk-dev||
   |Debian|libwebkit2gtk-4.0-dev||
   |OpenBSD/FreeBSD|webkit2-gtk3|requires wxallowed mount(8) option|

2. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  webview:
  github: dscottboggs/webview
```

3. Run `shards install`

## Usage

```crystal
require "webview.cr"

class SimpleWebWindow < Webview::Window
  def script
    <<-JS
      console.log("hello, there")
      some_callback("Hello to Crystal from Javascript")
    JS
  end

  @[Webview::Callback]
  def some_callback(text : String)
    puts text
  end

  def run
    run do
      puts "running"
      go_to "https://crystal-lang.org/reference"
      sleep 1
      eval <<-JS
        console.log("evaluating arbitrary code")
      JS
      some_callback "can also be called from Crystal!"
    end
    puts "done"
  end
end

SimpleWebWindow.new.run
```

There is a runnable version of this example in the `samples` directory. All
samples can be built by running `make` from the project directory.

```sh
make
sample/simple
sample/render
```

## Development

Contributions are welcome. Since this a graphical tool, and the results are
usually visual as opposed to something that can be tested in code, please write
a runnable example which exercises any new code paths. See the samples
directory.

Of course, if your contributions can be tested with `crystal spec`, those tests
are more than welcome.

### Planned/desired features:

- Webpack integration
- Scripts for bootstrapping the `yarn` environment and having a smooth and
  defined process for integrating complicated environments that come with web
  projects.
- Integration with existing Crystal web frameworks like Lucky, Athena, or Amber.

## Contributing

1. Fork it (<https://github.com/dscottboggs/webview/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [D. Scott Boggs](https://github.com/dscottboggs) - creator and maintainer
