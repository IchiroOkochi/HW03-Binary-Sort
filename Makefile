# ***
# *** Cross-platform Makefile (Windows + Linux/macOS)
# ***

WARNING = -Wall -Wshadow --pedantic
ERROR   = -Wvla -Werror
GCC     = gcc -std=c99 -g $(WARNING) $(ERROR)

SRCS = main.c binary_sort.c
OBJS = $(SRCS:%.c=%.o)

# -------- Platform detection --------
# If OS=Windows_NT but we're inside MSYS/MinGW Bash, prefer POSIX tools.
ifeq ($(OS),Windows_NT)
  UNAME_S := $(shell uname -s 2>NUL)
  ifneq (,$(findstring MINGW,$(UNAME_S)))
    WINDOWS_BASH := 1
  endif
endif

ifeq ($(OS),Windows_NT)
  ifdef WINDOWS_BASH
    # Windows, but POSIX shell available (Git Bash/MSYS)
    EXE   := binary_sort
    RUN   := ./$(EXE)
    DIFF  := diff
    RM    := rm -f
    SHELL := /usr/bin/sh
  else
    # Pure Windows (PowerShell/cmd)
    EXE   := binary_sort.exe
    RUN   := .\$(EXE)
    DIFF  := fc
    RM    := del /Q
    # Use cmd for recipes so redirection/globs behave as expected
    SHELL := cmd
  endif
else
  # Linux/macOS
  EXE   := binary_sort
  RUN   := ./$(EXE)
  DIFF  := diff
  RM    := rm -f
  SHELL := /bin/sh
endif

# -------- Build rules --------
.PHONY: all binary_sort testall test1 test2 show1 show2 clean
all: binary_sort

# Keep the target name 'binary_sort' for compatibility
binary_sort: $(EXE)

$(EXE): $(OBJS)
	$(GCC) $(OBJS) -o $(EXE)

# Compile .c -> .o
.c.o:
	$(GCC) -c $< -o $@

# -------- Tests --------
testall: test1 test2

test1: binary_sort
	$(RUN) inputs/presorted_list.bin output1.bin
	$(DIFF) output1.bin expected/expected1.bin

show1: test1
	hexdump -C inputs/presorted_list.bin > presorted_list_hex.txt
	hexdump -C output1.bin > output1_hex.txt
	hexdump -C expected/expected1.bin > expected1_hex.txt

test2: binary_sort
	$(RUN) inputs/short_list.bin output2.bin
	$(DIFF) output2.bin expected/expected2.bin

show2: test2
	hexdump -C inputs/short_list.bin > short_list_hex.txt
	hexdump -C output2.bin > output2_hex.txt
	hexdump -C expected/expected2.bin > expected2_hex.txt

# -------- Clean --------
# Suppress "file not found" messages on Windows by redirecting errors.
clean:
	-$(RM) $(EXE) *.o *.txt output* 2>NUL || true
