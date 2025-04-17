Raku TOP: Table-Oriented Programming (TOP) in the Raku programming language
===========================================================================

This package implements TOP in Raku. 

For more information on TOP (Table Oriented Programming): [What is Table-Oriented Programming?](https://wayland.github.io/table-oriented-programming/TOP/Introduction/What.xml)

Raku TOP Introductory Documents
-------------------------------

[Raku Introductory Docs](https://wayland.github.io/table-oriented-programming/Raku-TOP/Introduction.xml)

The Object Model Overview
-------------------------

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

Most of the above concepts are directly from Relational Set Theory. The exceptions are:

  * DataDictionary: Just a set of tables that explain what the rest of the database is doing; may be implemented differently

  * Lot: A group of columns

  * TupleSet: A set of tuples, usually that are the result of a query

In addition to the above, we have:

  * Storage: This is data we can read/write; used for modelling SQL databases, but could also be in-memory tables, spreadsheets, CSV files, etc

  * Formatters: This is for outputting data. Could be tables drawn with CLI box characters, CSV files, etc

  * Parsers: This is for reading from tables. This includes reading in space-separated data, CSV files, etc

Formats and their Parameters
============================

Some formats are only really used as storage (eg. Memory, Postgres). Some things are only ever used as input/output (eg. WithBorders is generally not very useful except as output).

<table class="pod-table">
<thead><tr>
<th>Format</th> <th>Storage</th> <th>Parser</th> <th>Formatter</th> <th>Tree Format</th>
</tr></thead>
<tbody>
<tr> <td>Memory</td> <td>Yes</td> <td>No</td> <td>No</td> <td></td> </tr> <tr> <td>Postgres</td> <td>Yes</td> <td>No</td> <td>No</td> <td></td> </tr> <tr> <td>HalfHuman</td> <td>No</td> <td>Yes</td> <td>Yes</td> <td></td> </tr> <tr> <td>WithBorders</td> <td>No</td> <td>No</td> <td>Yes</td> <td></td> </tr> <tr> <td>CSV</td> <td>Yes</td> <td>Yes</td> <td>Make</td> <td></td> </tr> <tr> <td>HTML</td> <td>Make</td> <td>Make</td> <td>Make</td> <td>XML</td> </tr> <tr> <td>Spreadsheet</td> <td>Make</td> <td>No</td> <td>No</td> <td>XML</td> </tr> <tr> <td>JSON</td> <td>Make</td> <td>Make</td> <td>Make</td> <td>JSON</td> </tr> <tr> <td>Pod6</td> <td>?</td> <td>?</td> <td>Make</td> <td>AST</td> </tr> <tr> <td>SQLite</td> <td>Accept</td> <td>No</td> <td>No</td> <td></td> </tr> <tr> <td>MySQL</td> <td>Accept</td> <td>No</td> <td>No</td> <td></td> </tr> <tr> <td>Postgres option with not using cursors (has to support both cursor and non-cursor)</td> <td>Accept</td> <td>No</td> <td>No</td> <td></td> </tr> <tr> <td>Dan | Accept</td> <td>?</td> <td>?</td> <td></td> <td></td> </tr> <tr> <td>DataQueryWorkflows</td> <td>Accept</td> <td>?</td> <td>?</td> <td></td> </tr>
</tbody>
</table>

Key to Formats
--------------

  * **Yes**: This item exists

  * **No**: No plans for this

  * **Make**: Plans for this, but nothing yet

  * **Accept**: No plans to make this, but would gladly accept it if someone made it

  * **Tree**: These ones will be made, but not until Tree-Oriented Programming has been inaugurated

Raku TOP Class References
-------------------------

Note that the following links don't yet work on raku.land -- you'll need to go to github to read them. 

Also, Database::Storage::CSV doesn't work yet (TODO), but the others should; probably start with TOP, then go to Memory, then as you please. 

  * [class TOP::Parser::CSV](docs/Markdown/Reference/TOP/Parser/CSV.md)

  * [class TOP::Parser::HalfHuman](docs/Markdown/Reference/TOP/Parser/HalfHuman.md)

  * [class TOP::FieldMode::Error](docs/Markdown/Reference/TOP/FieldMode/Error.md)

  * [class TOP::FieldMode::Automatic](docs/Markdown/Reference/TOP/FieldMode/Automatic.md)

  * [class TOP::FieldMode::Overflow](docs/Markdown/Reference/TOP/FieldMode/Overflow.md)

  * [class TOP::Formatter::WithBorders](docs/Markdown/Reference/TOP/Formatter/WithBorders.md)

  * [class TOP::Formatter::HalfHuman](docs/Markdown/Reference/TOP/Formatter/HalfHuman.md)

  * [class TOP::FieldMode](docs/Markdown/Reference/TOP/FieldMode.md)

  * [class Database::Storage](docs/Markdown/Reference/Database/Storage.md)

  * [class Database::Storage::CSV](docs/Markdown/Reference/Database/Storage/CSV.md)

  * [class Database::Storage::Memory](docs/Markdown/Reference/Database/Storage/Memory.md)

  * [class Database::Storage::Postgres](docs/Markdown/Reference/Database/Storage/Postgres.md)

  * [class TOP](docs/Markdown/Reference//TOP.md)

Plans for Raku TOP
------------------

For more information on the plans for Raku TOP, see [Raku TOP TODO](https://wayland.github.io/table-oriented-programming/Raku-TOP/TODO.xml)

