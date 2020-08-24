require "json"
require "../src/webview"

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
