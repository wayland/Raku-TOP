NAME
====

Postgres Storage - The Postgres Storage classes for Raku TOP

TITLE
=====

Postgres Storage

SUBTITLE
========

The Postgres Storage classes for Raku TOP

AUTHOR
======

Tim Nelson - https://github.com/wayland

Database::Storage::Postgres
===========================

    class	Database::Storage::Postgres does Database::Storage {

Currently uses a cursor for all reads. What we'd like to change is:

  * The user can specify a mode:

    * **Key:** Uses a key field (default: primary key) to track rows; doesn't matter if we miss some when paginating, etc (ie. if others have been added into the sequence)

    * **NumKey:** Like Key, but the key has to be numeric

    * **Sort+Key:** Like Key, but also applies an ordering to the table (ie. an ordering other than by Key)

    * **Cursor:** Uses cursors to match things up; could be suitable for eg. batch jobs

The current (only) behaviour is Cursor. We'd like to make the other options available, and default to NumKey (since it's probably the quickest, and loads the database least).

Methods
-------

### .useTable

    method	useTable(Table :$table, Str :$action = 'use', :%fields = {}) {

**Table :$table**

The frontend table object that's going to reference this Storage

**Str :$action = 'use'**

Documented in TOP Table.new()

**:%fields = {}**

The fields to be used on the table.

