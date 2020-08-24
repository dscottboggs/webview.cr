@[Link("gtk+-3.0 webkit2gtk-4.0", ldflags: "#{__DIR__}/../../ext/webview.o")]
lib LibWebview
  enum Hint
    NONE  # Width and height are default size
    MIN   # Width and height are minimum bounds
    MAX   # Width and height are maximum bounds
    FIXED # Window size can not be changed by a user
  end
  alias WebviewT = Void*
  # Creates a new webview instance. If debug is non-zero - developer tools will
  # be enabled (if the platform supports them). Window parameter can be a
  # pointer to the native window handle. If it's non-null - then child WebView
  # is embedded into the given parent window. Otherwise a new window is created.
  # Depending on the platform, a GtkWindow, NSWindow or HWND pointer can be
  # passed here.
  fun create = webview_create(LibC::Int, Void*) : WebviewT
  # Destroys a webview and closes the native window.
  fun destroy = webview_destroy(WebviewT) : Void
  # Runs the main loop until it's terminated. After this function exits - you
  # must destroy the webview.
  fun run = webview_run(WebviewT) : Void
  # Stops the main loop. It is safe to call this function from another other
  # background thread.
  fun terminate = webview_terminate(WebviewT) : Void
  # Posts a function to be executed on the main thread. You normally do not need
  # to call this function, unless you want to tweak the native window.
  @[Raises]
  fun dispatch = webview_dispatch(WebviewT, (WebviewT, Void*) -> Void*, Void*) : Void
  # Returns a native window handle pointer. When using GTK backend the pointer
  # is GtkWindow pointer, when using Cocoa backend the pointer is NSWindow
  # pointer, when using Win32 backend the pointer is HWND pointer.
  fun get_window = webview_get_window(WebviewT) : Void*
  # Updates the title of the native window. Must be called from the UI thread.
  fun set_title = webview_set_title(WebviewT, LibC::Char*) : Void
  # Updates native window size. See LibWebview::Hint.
  fun set_size = webview_set_size(WebviewT, LibC::Int, LibC::Int, LibC::Int) : Void
  # Navigates webview to the given URL. URL may be a data URI, i.e.
  # "data:text/text,<html>...</html>". It is often ok not to url-encode it
  # properly, webview will re-encode it for you.
  fun navigate = webview_navigate(WebviewT, LibC::Char*) : Void
  # Injects JavaScript code at the initialization of the new page. Every time
  # the webview will open a the new page - this initialization code will be
  # executed. It is guaranteed that code is executed before window.onload.
  fun init = webview_init(WebviewT, LibC::Char*) : Void
  # Evaluates arbitrary JavaScript code. Evaluation happens asynchronously, also
  # the result of the expression is ignored. Use RPC bindings if you want to
  # receive notifications about the results of the evaluation.
  fun eval = webview_eval(WebviewT, LibC::Char*) : Void
  # Binds a native C callback so that it will appear under the given name as a
  # global JavaScript function. Internally it uses webview_init(). Callback
  # receives a request string and a user-provided argument pointer. Request
  # string is a JSON array of all the arguments passed to the JavaScript
  # function.
  @[Raises]
  fun bind = webview_bind(WebviewT, LibC::Char*, (LibC::Char*, LibC::Char*, Void*) -> Void*, Void*) : Void
  # Allows to return a value from the native binding. Original request pointer
  # must be provided to help internal RPC engine match requests with responses.
  # If status is zero - result is expected to be a valid JSON result value.
  # If status is not zero - result is an error JSON object.
  fun return = webview_return(WebviewT, LibC::Char*, LibC::Int, LibC::Char*) : Void
end
