# My C Compiler (MCC)

I've been wanting to write a compiler for a very long time now, and this is my
first honest attempt at it. The plan is to implement a C compiler and then modify
the my C language as I see fit. There are not a whole lot of plans, but there
are a few things I want to implement into my take on the C language:

- [ ] **Interfaces**
- [ ] **Better type system to allow for things like generics without macros**
- [ ] Optionals builtin to the language
- [ ] Better error system
- [ ] Slices
- [ ] **Defer**
- [ ] Custom back end to make cross compilation easier

*Note: the ones in bold are more important*

Of course the first compiler for my language (which I have yet to name) will be 
written in C. But there are definitely plans to helf-host my language and bootstrap
the compiler.

Everything will be written from scratch only relying on the C standard library and
the C99 standard. Though, there will not be any effort to make this cross-platform.
This project is purely for learning and will jumpstart future ideas of writing
an OS in this language one day.
