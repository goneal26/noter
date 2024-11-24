# Noter Plugin

A micro plugin providing a set of features for wiki-style markdown notes.

This plugin is a bit opinionated in its current design, as it's built around how
I personally take markdown notes.

## Wikilinks

Wikilinks in markdown appear as text between double-brackets: 

```

[[this is a link]]

```

Put your cursor on the wikilink and run `> wikilink` to open the link as a 
markdown file. The buffer you currently have open will automatically be saved 
before you open the link.

If the file does not exist, you will be prompted to create one.

The command assumes that the markdown file is in the same directory as the file
that is currently open. Relative paths do work but they aren't really intended
to be used.

The command ignores leading and trailing whitespace in the wikilink's inner
text. I can't guarantee that links with whitespace in the inner text will work
every time- I generally use `snake_case` for my links. The wikilink inner text
also **cannot** span multiple lines.

As of right now, `> wikilink` tries to bind itself to `Alt-o`.

As of right now, the command *will only run in markdown files*, by design. 
I may add an option that will allow otherwise in the future.

I figured it would be "safer" this way, as I think it would be annoying to 
create a markdown file if I accidentally pressed `Alt-o` when my cursor was,
say, inside of a multi-line Lua comment.

## Options

The `openinnewtab` option (`false` by default) determines whether following a
wikilink will open it in a new tab.

The `markdownonly` option (`true` by default) determines whether this plugin's
commands can be used outside of markdown files.
