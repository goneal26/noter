# noter

A plugin for the micro text editor providing a set of features for wiki-style 
markdown notes.

This plugin is a bit opinionated in its current design, as it's built around how
I personally take markdown notes.

## Installation and Contributing

As of right now this isn't on the 
[Official Micro Plugin Channel](https://github.com/micro-editor/plugin-channel) 
but once it is you can install it through the plugin manager with 
`> plugin install noter`.

Otherwise, simply clone this repository to your micro config plugin folder- the 
plugin should be at a path like `~/.config/micro/plug/noter`. Then restart 
micro; you may need to run `> reload` to initialize any settings.

I have yet to test the plugin on operating systems other than Void Linux, and 
I have yet to test the plugin on other versions of micro. 

I can only guarantee that the plugin runs on micro versions at or above 
`2.0.14` (I originally developed it in version `2.0.15-dev.78`). In theory it
*should* work on any version >= `2.0.0`, as far as I know.

See [[help/noter]] for the main help file, or run `> help noter` after install.

## Roadmap

I already personally use micro as my primary text/code editor. However, for my
notes I use [Obsidian](https://obsidian.md/), and I would like to replicate 
enough of what I like about Obsidian in this plugin to where I don't need to use
Obsidian anymore.

Ideally once it's finished it'll have the features of the unofficial 
[microwiki](https://github.com/obedm503/microwiki) plugin, and I'll actively
be adding new features and accepting pull requests for some time.

In order to do this, I would like to eventually add these features:

- [x] Following wikilinks
- [ ] Better markdown syntax highlighting
- [ ] Templates
- [ ] Daily Notes
- [ ] Backlinks?
- [ ] Tags?
