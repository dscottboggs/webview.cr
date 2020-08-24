
DEPENDENCY_DIR := include
DEPENDENCY_HEADER := $(DEPENDENCY_DIR)/webview.h
DEPENDENCY := $(DEPENDENCY_DIR)/webview.cc
DEPENDENCY_OUTPUT := ext/webview.o
C_FLAGS := -fPIC -shared
CRYSTAL_FLAGS := --error-trace --release -Dpreview_mt
SAMPLES := sample/render sample/simple

ifeq ($(OS),Windows_NT)
    C_FLAGS += -mwindows -L./dll/x64 -lwebview -lWebView2Loader
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        C_FLAGS += $(shell pkg-config --cflags --libs gtk+-3.0 webkit2gtk-4.0)
    endif
    ifeq ($(UNAME_S),Darwin)
        C_FLAGS += -std=c++11 -framework WebKit
    endif
endif

all: $(DEPENDENCY_OUTPUT) $(SAMPLES)

sample/simple: $(DEPENDENCY_OUTPUT)
	crystal build -o sample/simple $(CRYSTAL_FLAGS) sample/simple.cr

sample/render: $(DEPENDENCY_OUTPUT)
	crystal build -o sample/render $(CRYSTAL_FLAGS) sample/render.cr

$(DEPENDENCY_OUTPUT):
	-mkdir ext
	c++ $(DEPENDENCY) $(C_FLAGS) -o $(DEPENDENCY_OUTPUT)

clean:
	-rm $(DEPENDENCY_OUTPUT)
	-rm $(SAMPLES)