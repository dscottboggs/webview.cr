require "json"
require "./lib/webview"

module Webview
  # Marks a method as a callback which can be called from Javascript.
  #
  # An extra value can be passed through to be received by the called method
  # when the javascript function is called. This value is not accessible from
  # Javascript. Internally, this value is stored as a `Pointer(Void)`, so the
  # type of the `extra` data must be specified, either as the `extra_type`, or
  # by adding a type restriction to the `extra` argument of the annotated
  # method.
  #
  # ### Examples:
  #
  # ```
  # @[Callback(extra: "some data", extra_type : String)]
  # def foo(extra data)
  #   puts data # => "some data"
  # end
  #
  # @[Callback(extra: "some data")]
  # def foo(extra : String)
  #   puts extra # => "some data"
  # end
  # ```
  #
  # ### Arguments
  # There are 3 options for how arguments are received from Javascript. By
  # default, the arguments are parsed from the received string and cast to
  # the types they are restricted to. This means that, unless you use the
  # `RawArguments` or `ArgumentType` annotations alongside this one, you
  # *must* specifiy the types of *all* arguments.
  #
  # ### Examples:
  # ```
  # @[Callback]
  # def foo(some : String, data : Int32) # OK - types annotated
  #   # foo("data", 1234) called from Javascript
  #   puts some # => "data"
  #   puts data # => 1234
  # end
  #
  # @[Callback]
  # def foo(some, data) # Not ok -- compile-time error
  # end
  # ```
  annotation Callback; end
  # When this is used, the raw string values received from LibWebview are passed to the
  # annotated function.
  annotation RawArguments; end
  # When this annotation is used, the type specified will be used to
  # deserialize the received data, and the deserialized data is passed to the
  # callback.
  #
  # ### Example:
  # ```
  # @[Callback]
  # @[ArgumentType(Array(Int32))]
  # def foo(data)
  #   # foo([1, 2, 3]) called from Javascript
  #   puts data.join '-' # => 1-2-3
  # end
  # ```
  annotation ArgumentType; end
  # TODO
  annotation Scoped; end

  private macro list_to_union(list)
    Union({{list.splat}})
  end

  # A webview window.
  #
  # To use webview.cr, inherit this class and overload the `#run` method.
  #
  # ```
  # class MyWindow < Webview::Window
  #   def run
  #     run do
  #       go_to "https://crystal-lang.org"
  #     end
  #   end
  # end
  # ```
  abstract class Window
    @view : LibWebview::WebviewT
    @@callbacks = [] of Proc(Pointer(UInt8), Pointer(UInt8), Pointer(Void), Nil)
    HTML_RENDER_PREFIX = "data:text/html,"
    TEXT_RENDER_PREFIX = "data:text/text,"

    def initialize(debug = false, window = nil, title = "Crystal App")
      @view = LibWebview.create debug ? 0 : 1, window
      raise "Error creating webview" if @view.null?
      LibWebview.set_title @view, title

      {% for _callback in @type.methods.map { |m| {m, m.annotation(Callback)} }.select &.[1] %}
        {%
          callback = _callback[0]
          ann = _callback[1]
          extra = ann[:extra]
          extra_type = ann[:extra_type]
        %}
        %callback = ->(%seq : Pointer(UInt8), %req : Pointer(UInt8), %extra : Pointer(Void)) {
          {% args = callback.args.reject(&.name.== :extra) %}
          {% if callback.annotation RawArguments %}
            # Pass the raw arguments to the callback, directly as they were received from LibWebview
            {% if callback.args.size > 0 %}
              {{callback.args[0].internal_name}} = String.new %seq
            {% end %}
            {% if callback.args.size > 1 %}
              {{callback.args[1].internal_name}} = String.new %req
            {% end %}
            {% if callback.args.size > 2 && extra && (etype = extra_type || callback.args[2].type) %}
              {{callback.args[2].internal_name}} = Box({{etype}}).unbox %extra
            {% end %}
          {% elsif (callback.args.size > 0) && (_argtype = callback.annotation(ArgumentType)) && (argtype = _argtype.try(&.[0])) %}
            # Argument is a single value of the specified type
            {{callback.args[0].internal_name}} = {{argtype}}.from_json %req # TODO check arg types are right
            {% if callbacks.args.size > 1 %}
              {{callback.args[1].internal_name}} = Box({{extra_type || callback.args[1].type || raise "please specify the type of the \"extra\" value passed to #{callback.name} (with @[Callback(extra_type: T)]), or explicitly declare the type of the second argument of the same"}})
                .unbox %extra
            {% end %}
          {% elsif args.size == 0 %}
          # no args, just paste the body
          {% else %}
            # Deserialize body into a tuple of all argument types
            %all_args = Tuple({{args.map { |arg| arg.restriction.types.join("|").id || raise "callback arguments must be typed, please add annotation to #{callback.name}'s \"#{arg.name}\" argument" }.splat}})
              .from_json String.new %req
            # assign to the variables named in the arguments
            {% if args.size == 1 %}
            {{args[0].internal_name}} = %all_args[0]
            {% else %}
            # definitely not 0 because of the macro branches
            {{args.map(&.internal_name).join(",").id}} = %all_args
            {% end %}
            # fill in the extra data if present
            {% if ext = callback.args.find &.name.== :extra %}
              {% if etype = extra_type || ext.restriction %}
                {{ext.internal_name}} = Box({{etype}}).unbox %extra
              {% else %}
                {{raise raise "please specify the type of the \"extra\" value passed to #{callback.name} (with @[Callback(extra_type: T)]), or explicitly declare the type of the argument named \"extra\" of the same"}}
              {% end %}
            {% end %}
          {% end %}
          # Paste the method body
          {{callback.body}}
          Pointer(Void).null
        }
        @@callbacks << %callback # MUST store a reference to the CB so the GC doesn't free it
        raise "callback is closure" if %callback.closure?
        %name = {% if callback.annotation(Scoped) %}call("{{callback.name}}"){% else %}"{{callback.name}}"{% end %}
        LibWebview.bind @view, %name, %callback,
          {% if extra && extra_type %}Box.box({{extra}}){% else %}Pointer(Void).null{% end %}
      {% end %}
    end

    private def run(&)
      if js = script
        LibWebview.init @view, js
      end
      try_to_resize_to 400, 600
      with self yield @view
      LibWebview.run @view
      LibWebview.destroy @view
    end

    # Overload this as the entrypoint of your application, and call `run` from
    # inside, setting up the webview in the block.
    #
    # ```
    # def run
    #   run do
    #     go_to "https://example.com"
    #   end
    # end
    # ```
    abstract def run

    # navigate to the given URL. This is equivalent to calling
    # `window.location = url` in Javascript.
    def location=(url : String)
      LibWebview.navigate @view, url
    end

    # An alias for `location=` for places where the receiver can be implicit.
    def go_to(url : String)
      self.location = url
    end

    # Render the received HTML page.
    #
    # This is the same as `#location=` with a URL that starts with "data:text/html,"
    def render_html(html : String)
      render_string HTML_RENDER_PREFIX, html
    end

    # Render the received plaintext
    #
    # This is the same as `#location=` with a URL that starts with "data:text/text,"
    def render_text(text : String)
      render_string TEXT_RENDER_PREFIX, text
    end

    private def render_string(prefix : String, string : String)
      LibWebview.navigate @view, prefix + string
    end

    # Set the window title.
    def title=(new_title : String)
      LibWebview.set_title @view, new_title
    end

    # Set the size of the window to a fixed value.
    def size=(dimensions : Tuple(Int32, Int32))
      LibWebview.set_size @view, dimensions[0], dimensions[1], LibWebview::Hint::FIXED
    end

    # Set the minimum size the window can be resized to.
    def minimum_size=(dimensions : Tuple(Int32, Int32))
      LibWebview.set_size @view, dimensions[0], dimensions[1], LibWebview::Hint::MIN
    end

    # Set the maximum size the window can be resized to.
    def maximum_size=(dimensions : Tuple(Int32, Int32))
      LibWebview.set_size @view, dimensions[0], dimensions[1], LibWebview::Hint::MAX
    end

    # Set the default size of the window.
    def default_size=(dimensions : Tuple(Int32, Int32))
      LibWebview.set_size @view, dimensions[0], dimensions[1], LibWebview::Hint::NONE
    end

    # Resize the window to a fixed value.
    def resize(width, height)
      self.size = {width, height}
    end

    # Set the minimum size the window can be resized to.
    def resize_to_at_least(width, height)
      self.minimum_size = {width, height}
    end

    # Set the maximum size the window can be resized to.
    def resize_to_at_most(width, height)
      self.maximum_size = {width, height}
    end

    # Set the default size of the window.
    def try_to_resize_to(width, height)
      self.default_size = {width, height}
    end

    # This must return a string which is valid javascript, which will be executed each
    # time a new page is loaded. It is guaranteed that code is executed before
    # `window.onload`.
    #
    # By default (as in, unless the class is inherited and the method
    # overloaded), this is `nil`, and no code is injected.
    def script : String?
    end

    # Evaluate arbitrary Javascript
    def eval(code : String)
      LibWebview.eval @view, code
    end

    # The name the named `@[Scoped]` method as it will appear in Javascript
    private def call(method)
      %[#{{{ @type.name.gsub /\W/, "$" }}}$$#{method}]
    end
  end
end
