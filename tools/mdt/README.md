MDT - The Mendel Development Tool
=================================

## What is this?

MDT is a simple tool to aid in working with single board computers that the
Mendel Linux distribution runs on. It consists of a whole bunch of pre-existing
open source tooling, coupled with some simple wrappers written in python to ease
their use.

It also provides an easy way to interact with these boards without having to
fight with serial consoles, IP addresses, and other fiddly bits, reducing
barrier to entry when working with these boards.

With minimal effort, MDT should also be portable to existing systems such as
Debian and Ubuntu, if needed. This, however, is out of the scope of this
project.

## How do I use it?

Install it via pip like this:

```
pip install mendel-development-tool
```

Note that if you run this as a non-root user, the executable will be stored in
`$HOME/.local/bin` which may not be in your PATH environment variable, so you'll
want to add it.
