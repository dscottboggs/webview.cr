
DEPENDENCY_DIR := include
DEPENDENCY_HEADER := $(DEPENDENCY_DIR)/webview.h
DEPENDENCY := $(DEPENDENCY_DIR)/webview.cc
DEPENDENCY_OUTPUT := ext/webview.o
C_FLAGS := -fPIC -shared $(shell pkg-config --cflags --libs gtk+-3.0 webkit2gtk-4.0) -I$(DEPENDENCY_DIR)
CRYSTAL_FLAGS := --error-trace --release -Dpreview_mt
SAMPLES := sample/render sample/simple


all: $(DEPENDENCY_OUTPUT) $(SAMPLES)

sample/simple: $(DEPENDENCY_OUTPUT)
	crystal build -o sample/simple $(CRYSTAL_FLAGS) sample/simple.cr

sample/render: $(DEPENDENCY_OUTPUT)
	crystal build -o sample/render $(CRYSTAL_FLAGS) sample/render.cr

$(DEPENDENCY_OUTPUT):
	c++ $(DEPENDENCY) $(C_FLAGS) -o $(DEPENDENCY_OUTPUT)

clean:
	rm -r $(DEPENDENCY_OUTPUT)
	rm $(SAMPLES)