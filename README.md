# Nomi

I've been wanting to write a compiler for a very long time now, and this is my
first honest attempt at it. I've decided to pivot from making a C compiler to just
starting with my own language. I want to keep C compatablity and interop, but the
language will look more high level than C. I'm going for a Zig-eque language but
handcrafted. That saying there is anything wrong with Zig or that I feel like I
can make a better Zig, but I want to append / amend C. There are not a whole lot
of plans, but there are a few things I want to implement into my take on the C language:

- [ ] **Interfaces**
- [ ] **Better type system to allow for things like generics without macros**
- [ ] Optionals builtin to the language
- [ ] Better error system (errors as types)
- [ ] Slices
- [ ] **Defer**
- [ ] Custom backend (for shits and giggles)

*Note: the ones in bold are more important*

Of course the first compiler for my language (which I have yet to name) will be 
written in ~C~ Zig. But there are definitely plans to helf-host my language and bootstrap
the compiler.

Everything will be written from scratch only relying on the ~C~ Zig standard library.
Though, there will not be any effort to make this cross-platform. This project is
purely for learning and will jumpstart future ideas of writing an OS in this
language one day.

## TODO List

- [] Better printing of compiler types (Location, ast, etc.)
- [] Improve error system for compiler internals.
- [] External functions from Nomi (written in FASM) (extern func sys_exit(i32) void;)
- [] Start work on IR layer to abstract frontend and backend
- [] Start work on a type system
- [] Start work on user declared functions and calling user declared functions
- [] More types ("Strings")
- [] Variables
- [] Functions which takes args
- [] Hello, World! (No libc)
- [] Semantic Analysis (Ensuring functions return, etc.)


## Usage

### Dependencies

- Zig
- Fasm
- ld linker

### Running the compiler

```bash
    zig build # Build the compiler
    ./zig-out/bin/nomic start.nom start.o # Run the compiler and save the object file in start.o
    ld start.o -o start # Link start.o to an ELF executable
    ./start # Run the newly compiled executable
    echo $? #To see the exit code of start
```

There are plans to rework this process. But this is the simplest way of handling
it so far.

## What can the compiler do right now?

Currently, the compiler only supports one function being in a file. Within that
function, you can call external functions (nothing is checked yet) which take one
argument which is a number with a width greater than 32. We don't link with libc,
so the only functions you can call are the ones hardcoded in the assmebly file
generated behind the scenes before it's assembled by the compiler.

The compiler will emit an object file for you to link yourself. There are plans
to change this in the future, but this lets me do something else before I introduce
compiling multiple files or mixing files and object files. Basically, everything
in the compiler will improve at once. We have to allow for more options to parsed
and then we can emit an executable file. But this is not much of a priority right now.

## What's in a name?

### Noh-mee

The name Nomi comes from a few different places. Most notably, it is heavily
inspired by my girlfriend's nickname, _Nemo_. Nomi is a loose combination of her
nickname and her real name. Nomi also has a few meanings I think are very neat.
The two meanings that stand out to me are beautiful (Hebrew and Japanese) and ocean (Japanese).
Both meanings are perfect and accurately reflect her and her names.

A motto I've come up with is: "Built from beauty for power"
