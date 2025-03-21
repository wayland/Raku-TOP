NAME
====

Raku TOP Driver - The common driver for Raku TOP backends

TITLE
=====

Raku TOP Driver

SUBTITLE
========

The common driver for Raku TOP backends

AUTHOR
======

Tim Nelson - https://github.com/wayland

Database::Driver
================

The parent class for all the different Database Drivers (backends).

    role	Database::Driver

Methods
-------

### .useTable

    method	useTable(Table :$table, *%params)

Returns a table belonging to the database. Parameters vary from driver to driver.

Table::Driver
=============

    role	Table::Driver does Associative does Positional {

Attributes
----------

**Field @.fields**

Stores the fields

**%.field-indices**

For looking up fields by name

Methods
-------

### .new

Creates a Table::Driver.

    .new(Database::Driver :$database, Relation :$frontend-object, Str :$action, Str :%fields)

Parameters to .new are:

**Relation $frontend-object**

The frontend object that is using this backend object.

**Database::Driver :$database**

The Database::Driver with which this Table::Driver is connected.

**Str $action**

The action to take -- see the parameter of the same name on the frontend object

**Str %fields**

If relevant, the fields to use in creating/altering the table

### exists

Returns True if the table already exists.

    method	.exists(Str :$true-error, Str :$false-error)

If $true-error is passed, and the table exists, the function will die with the passed error. If $false-error is passed, and the table doesn't exist, the function will die with the passed error.

### format

Outputs the current table using the specified formatter. This is for outputting tables in ASCII, Unicode Box, CSV, and maybe someday HTML. 

Parameters are:

#### Str $format = 'HalfHuman';

Specifies what the output format is

#### %parameters

Parameters passed to TOP::Formatter::*.new()

### parse

Reads data into a table from the specified format. As with the above, this is for reading tables in ASCII, Unicode Box, CSV, and the like. 

Parameters are:

#### Str $format = 'HalfHuman';

Specifies what the input format is

#### %parameters

Parameters passed to TOP::Parser::*.new()

### .add-field

Adds a field to the table

    .add-field(Table :$relation, Str :$name, Any:U :$type)

**Str $name**

The name of the field being added

**Any:U $type**

The type of the field, as a Raku type

