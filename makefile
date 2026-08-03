CC = gcc
CFLAGS = -Wall -Wextra -Wpedantic -Werror -std=c11 -Isrc -Iexternal/linenoise -O2
OS := $(shell uname)

ifeq ($(OS),Windows_NT)
  TARGET = bin/repl2.exe
else
  TARGET = bin/repl2
endif

SRC = $(wildcard src/*.c) external/linenoise/linenoise.c
OBJ = $(SRC:%.c=obj/%.o)

.PHONY: all run debug clean

all: $(TARGET)

$(TARGET): $(OBJ)
	mkdir -p bin
	$(CC) $(OBJ) -o $(TARGET)

# Vendored third party (see THIRD_PARTY_LICENSES/). linenoise uses termios and
# ioctl calls that -Wpedantic rejects, and needs _GNU_SOURCE on some
# platforms - not held to this project's own warning level.
obj/external/linenoise/linenoise.o: external/linenoise/linenoise.c
	mkdir -p $(dir $@)
	$(CC) $(filter-out -Wpedantic -Werror,$(CFLAGS)) -D_GNU_SOURCE -c $< -o $@

obj/%.o: %.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

run: all
	./$(TARGET)

debug: CFLAGS += -g -O0
debug: clean all

clean:
	rm -rf obj bin
