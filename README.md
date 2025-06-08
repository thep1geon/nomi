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

## Usage

### Dependencies

- Fasm
- ld linker
- Zig

### Running the compiler

```bash
    zig build run &> star.s && gcc star.s -o star
    ./star
```

## What can the compiler do right now?

Right now the compiler has the source code hard coded in the main.zig file. You will
have the change that if you want to change what is compiled.

The compiler will output the assembly (Fasm) to stderr, so you will have to
send that to a file yourself and compile it with fasm and then link it with 'ld'. The
language is a very small subset of Nomi. Only supporting one function, and the body
of that function must be a function call or a block containing a function call.
And then that function call can only support one argument which must be a 64bit
number.

There are plans to switch to a different method of compilation, but that
will not come until later. This was more of an exercise to get things up and running.
Now that we have a working compiler, regardless of how bad it may be, we can
work on adding more features one at a time which makes things much easier. The
motto for this project is "one thing at a time".

## What's in a name?

The name Nomi comes from a few different places. Most notably, it is heavily
inspired by my girlfriend's nickname, _Nemo_. Nomi is a loose combination of her
nickname and her real name. Nomi also has a few meanings I think are very neat.
The two meanings that stand out to me are beautiful (Hebrew and Japanese) and ocean (Japanese).
Both meanings are perfect and accurately reflect her and her names.

A motto I've come up with is: "Built from beauty for power"
