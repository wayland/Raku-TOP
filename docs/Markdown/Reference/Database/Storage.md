NAME
====

Raku TOP Storage - The parent roles Raku TOP Storage classes

TITLE
=====

Raku TOP Storage

SUBTITLE
========

The parent roles Raku TOP Storage classes

AUTHOR
======

Tim Nelson - https://github.com/wayland

Database::Storage
=================

The parent class for all the different Database Storage classes (aka drivers, backends).

    role	Database::Storage

Methods
-------

### .useTable

    method	useTable(Table :$table, *%params)

Returns a table belonging to the database. Parameters vary depending on the Storage type.

Table::Storage
==============

    role	Table::Storage does Associative does Positional {

Attributes
----------

**Field @.fields**

Stores the fields

**%.field-indices**

For looking up fields by name

Methods
-------

### .new

Creates a Table::Storage.

    .new(Database::Storage :$database, Relation :$frontend-object, Str :$action, Str :%fields)

Parameters to .new are:

**Relation $frontend-object**

The frontend object that is using this storage object.

**Database::Storage :$database**

The Database::Storage with which this Table::Storage is connected.

**Str $action**

The action to take -- see the parameter of the same name on the frontend object

**Str %fields**

If relevant, the fields to use in creating/altering the table

**Str $field-mode = 'Automatic'**



$!field-mode could be one of the following:

  * Automatic: extra fields create new columns (default); like a spreadsheet

  * Error: extra fields create an error; like a RDBMS

  * overflow: extra fields get stuck in a (JSON?) hash/object/assoc field; the name of the field is in $!overflow-field-name

**Str $overflow-field-name**



The name of the field the overflow fields get put in

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

