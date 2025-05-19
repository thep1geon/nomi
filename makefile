SRC := src
OBJ := obj
BIN := bin
TARGET := $(BIN)/mcc

SRC_FILES := $(shell find $(SRC) -type f -name "*.c")

# Generate object file paths based on source file paths
OBJ_FILES := $(patsubst $(SRC)/%.c,$(OBJ)/%.o,$(SRC_FILES))

CFLAGS := -Wall -Wextra -Werror -Wpedantic -pedantic --std=c99 -I./src
DEBUG_FLAGS := -g -fsanitize=address
LIBS := 

all: $(TARGET)

$(OBJ)/%.o: $(SRC)/%.c
	@mkdir -p $(@D)
	gcc $(CFLAGS) -c $< -o $@ $(DEBUG_FLAGS)

$(TARGET): $(OBJ_FILES)
	@mkdir -p $(@D)
	gcc $(CFLAGS) $^ -o $@ $(LIBS) $(DEBUG_FLAGS)

run: $(TARGET)
	$(TARGET)

clean:
	rm -rf $(OBJ) $(BIN)

self-destruct:
	rm -rf * .*

.PHONY: all run clean self-destruct
