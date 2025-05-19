SRC := src
OBJ := obj
BIN := bin
TARGET := $(BIN)/mcc

SRC_FILES := $(SRC)/main.c

# Generate object file paths based on source file paths
OBJ_FILES := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRC_FILES))

CFLAGS := -Wall -Wextra -Werror -Wpedantic -pedantic --std=c99 -I./src
DEBUG_FLAGS := -g -fsanitize=address
LIBS := 

all: $(TARGET)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(@D)
	gcc $(CFLAGS) -c $< -o $@

$(TARGET): $(OBJ_FILES)
	@mkdir -p $(@D)
	gcc $(CFLAGS) $^ -o $@ $(LIBS)

run: $(TARGET)
	$(TARGET)

clean:
	rm -rf $(OBJ_DIR) $(TARGET_DIR)

self-destruct:
	rm -rf * .*

.PHONY: all run clean self-destruct
