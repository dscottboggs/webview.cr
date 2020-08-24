require "../src/webview"
require "ecr"
require "json"

class RenderWindow < Webview::Window
  PAGE_TITLE = "Crystal app"

  def run
    run do
      render_html ECR.render "#{__DIR__}/render.ecr"
    end
  end

  def self.run
    new.run
  end

  def data
    ["one", "two", "three", "four"]
  end

  @[Webview::Callback]
  @[Webview::Scoped]
  def func(test : String, value : Int32)
    puts test + '\t' + value.to_s
  end
end

RenderWindow.run
