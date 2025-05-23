NAME
====

TOP::Formatter::WithBorders - Format table on CLI to have borders

AUTHOR
======

Tim Nelson - https://github.com/wayland

TITLE
=====

TOP::Formatter::WithBorders

SUBTITLE
========

Formatting tables on the CLI to have Unicode borders

TOP::Formatter::WithBorders
===========================

    class    TOP::Formatter::WithBorders {}

The class for formatting tables so that they have borders made out of characters. Currently these are the Unicode box-drawing characters, but someday ASCII may be added as an option. 

Many of the functions in this class are called by Database::Storage::format()

Parameters that can be passed to Database::Storage (with defaults)

  * `$format => 'WithBorders'`

  * `$show-headers => True`

  * `$outer-line-type => 'Double'` (other options are Light and Heavy)

  * `$inner-line-type => 'Light'` (other options are Double and Heavy)

