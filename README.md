# mruby-bin-mrbmacs-termbox2

Terminal frontend for mrbmacs using
[Scintilla](https://www.scintilla.org/) and
[termbox2](https://github.com/termbox/termbox2).

![mrbmacs-termbox2](docs/screenshot.png "mrbmacs-termbox2")

## Requirements

- Ruby and Rake
- Git
- C and C++17 compilers
- A POSIX-compatible terminal

> **Note:** Only terminals with 24-bit (truecolor) support are supported.
> mrbmacs-termbox2 always requests termbox2's `OUTPUT_TRUECOLOR` output mode;
> 256-color or 16-color terminals will render incorrectly.

The build downloads mruby and the required mrbgems.

## Build

```sh
git clone https://github.com/masahino/mruby-bin-mrbmacs-termbox2.git
cd mruby-bin-mrbmacs-termbox2
rake
```

The executable is generated at `mruby/bin/mrbmacs-termbox2`.

## Test

```sh
rake test
```

## Run

```sh
./mruby/bin/mrbmacs-termbox2
./mruby/bin/mrbmacs-termbox2 path/to/file
```

The frontend supports the shared mrbmacs command-line options:

```text
-q                 do not load the init file
-l, --load FILE    load Ruby file
-d, --debug        enable debug logging
-h, --help         show help
-v, --version      show version
```

## Main dependencies

- [mruby-mrbmacs-base](https://github.com/masahino/mruby-mrbmacs-base)
- [mruby-termbox2](https://github.com/masahino/mruby-termbox2)
- [mruby-scintilla-base](https://github.com/masahino/mruby-scintilla-base)
- [mruby-scintilla-termbox2](https://github.com/masahino/mruby-scintilla-termbox2)

The default build also includes the mrbmacs LSP, DAP, AI chat, agent, and
theme extensions configured in `build_config.rb`.

## License

MIT. See [LICENSE](LICENSE).
