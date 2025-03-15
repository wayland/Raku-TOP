Raku TOP: Table-Oriented Programming (TOP) in the Raku programming
language

This package implements TOP in Raku. 

  * For more information on TOP (Table Oriented Programming):
  https://wayland.github.io/table-oriented-programming/TOP/Introduction/What.xml

  * Information on the plans for Raku TOP:
  https://wayland.github.io/table-oriented-programming/Raku-TOP/Introduction.xml

  Raku TOP Introductory Documents

Raku Introductory Docs

  Raku TOP Class References

Note that the following links don't yet work on raku.land -- you'll need to
go to github to read them. 

Also, the CSV one doesn't work yet, but the others should; probably start
with TOP, then go to Memory, then as you please. 

  * class CSV

  * class HalfHuman

  * class WithBorders

  * class HalfHuman

  * class Storage

  * class CSV

  * class Memory

  * class Postgres

  * class TOP

Formats and their parameters

Some formats are only really used as storage (eg. Memory, Postgres). Some
things are only ever used as input/output (eg. WithBorders is generally not
very useful except as output).

  Format                                                                              Storage  Parser  Formatter  Tree Format
  Memory                                                                              Yes      No      No         
  Postgres                                                                            Yes      No      No         
  HalfHuman                                                                           No       Yes     Yes        
  WithBorders                                                                         No       No      Yes        
  CSV                                                                                 Yes      Yes     Make       
  HTML                                                                                Make     Make    Make       XML
  Spreadsheet                                                                         Make     No      No         XML
  JSON                                                                                Make     Make    Make       JSON
  Pod6                                                                                ?        ?       Make       AST
  SQLite                                                                              Accept   No      No         
  MySQL                                                                               Accept   No      No         
  Postgres option with not using cursors (has to support both cursor and non-cursor)  Accept   No      No         


  Key to Formats

  * Yes: This item exists

  * No: No plans for this

  * Make: Plans for this, but nothing yet

  * Accept: No plans to make this, but would gladly accept it if someone made
  it

  * Tree: These ones will be made, but not until Tree-Oriented Programming has
  been inaugurated
