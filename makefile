SRC_DIR := src
OBJ_DIR := obj
TARGET_DIR := bin
TARGET := $(TARGET_DIR)/nomic

# Find all .c files in subdirectories of SRC_DIR
SRC_FILES := $(shell find $(SRC_DIR) -type f -name "*.c")

# Generate object file paths based on source file paths
OBJ_FILES := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRC_FILES))

CFLAGS := -Wall -Wextra -Werror -Wpedantic -pedantic -fsanitize=address -g --std=c99
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
