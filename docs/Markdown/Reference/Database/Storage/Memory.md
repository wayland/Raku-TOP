NAME
====

Raku *::Storage::Memory - Raku classes to implement the in-memory table store

TITLE
=====

Raku *::Storage::Memory

SUBTITLE
========

Raku classes to implement the in-memory table store

AUTHOR
======

Tim Nelson - https://github.com/wayland

Table::Storage::Memory
======================

    class	Table::Storage::Memory does Table::Storage {

Usage
=====

### The Easy Options

    Table.new(name => 'countries', action => 'can-create'),

The default database (if none is specified) is a Memory database, so there's not much you need to specify when using one of these.

### The Flexible Option

    $memdb = Database.new(
	    name => 'MyMemoryDatabase',
    );
    $memdb.useTable(name => 'countries');

The parameters to Database.useTable are basically the same as are passed to Table.new().

