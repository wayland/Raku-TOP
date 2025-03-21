Raku TOP: Table-Oriented Programming (TOP) in the Raku programming language
===========================================================================

This package implements TOP in Raku. 

  * For more information on TOP (Table Oriented Programming): [https://wayland.github.io/table-oriented-programming/TOP/Introduction/What.xml](https://wayland.github.io/table-oriented-programming/TOP/Introduction/What.xml)

  * Information on the plans for Raku TOP: [https://wayland.github.io/table-oriented-programming/Raku-TOP/Introduction.xml](https://wayland.github.io/table-oriented-programming/Raku-TOP/Introduction.xml)

Raku TOP Introductory Documents
-------------------------------

[Raku Introductory Docs](https://wayland.github.io/table-oriented-programming/Raku-TOP/Introduction.xml)

Raku TOP Class References
-------------------------

Note that the following links don't yet work on raku.land -- you'll need to go to github to read them. 

Also, the CSV one doesn't work yet, but the others should; probably start with TOP, then go to Memory, then as you please. 

  * [class CSV](docs/Markdown/Class/CSV.md)

  * [class HalfHuman](docs/Markdown/Class/HalfHuman.md)

  * [class WithBorders](docs/Markdown/Class/WithBorders.md)

  * [class HalfHuman](docs/Markdown/Class/HalfHuman.md)

  * [class Storage](docs/Markdown/Class/Storage.md)

  * [class CSV](docs/Markdown/Class/CSV.md)

  * [class Memory](docs/Markdown/Class/Memory.md)

  * [class Postgres](docs/Markdown/Class/Postgres.md)

  * [class TOP](docs/Markdown/Class/TOP.md)

Formats and their parameters
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

