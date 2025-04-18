Raku TOP: Table-Oriented Programming (TOP) in the Raku programming
language

This package implements TOP in Raku. 

For more information on TOP (Table Oriented Programming): What is
Table-Oriented Programming?

  Raku TOP Introductory Documents

Raku Introductory Docs

  The Object Model Overview

Any classes below in () are not implemented yet

Conceptually, what we're moddeling is:

  * Relation

    * Table

      * (DataDictionary)

    * (View)

    * (TupleSet)

  * Tuple

  * (Section)

    * Field

    * (Lot)

  * Database

  * Join

Most of the above concepts are directly from Relational Set Theory. The
exceptions are:

  * DataDictionary: Just a set of tables that explain what the rest of the
  database is doing; may be implemented differently

  * Lot: A group of columns

  * TupleSet: A set of tuples, usually that are the result of a query

In addition to the above, we have:

  * Storage: This is data we can read/write; used for modelling SQL databases,
  but could also be in-memory tables, spreadsheets, CSV files, etc

  * Formatters: This is for outputting data. Could be tables drawn with CLI box
  characters, CSV files, etc

  * Parsers: This is for reading from tables. This includes reading in
  space-separated data, CSV files, etc

Formats and their Parameters

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
  Dan | Accept                                                                        ?        ?                  
  DataQueryWorkflows                                                                  Accept   ?       ?          


  Key to Formats

  * Yes: This item exists

  * No: No plans for this

  * Make: Plans for this, but nothing yet

  * Accept: No plans to make this, but would gladly accept it if someone made
  it

  * Tree: These ones will be made, but not until Tree-Oriented Programming has
  been inaugurated

  Raku TOP Class References

Note that the following links don't yet work on raku.land -- you'll need to
go to github to read them. 

Also, Database::Storage::CSV doesn't work yet (TODO), but the others
should; probably start with TOP, then go to Memory, then as you please. 

  * class TOP::Parser::CSV

  * class TOP::Parser::HalfHuman

  * class TOP::FieldMode::Error

  * class TOP::FieldMode::Automatic

  * class TOP::FieldMode::Overflow

  * class TOP::Formatter::WithBorders

  * class TOP::Formatter::HalfHuman

  * class TOP::FieldMode

  * class Database::Storage

  * class Database::Storage::CSV

  * class Database::Storage::Memory

  * class Database::Storage::Postgres

  * class TOP

  Plans for Raku TOP

For more information on the plans for Raku TOP, see Raku TOP TODO
