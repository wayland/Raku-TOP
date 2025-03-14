NAME
====

Raku TOP - Table Oriented Programming in Raku

AUTHOR
======

Tim Nelson - https://github.com/wayland

TITLE
=====

Raku TOP

SUBTITLE
========

Table Oriented Programming in Raku

TOP::Core
=========

    role	TOP::Core {...}

This is the common code that's shared across all TOP objects; this is intended to be a role on all TOP classes.

method load-library
===================

method load-library(Str :$type = 'Database::Driver::Memory', *%parameters)

Loads the library in question, and makes an object of the named type

Tuple
=====

    class	Tuple is Hash::Ordered {}

This is the Tuple class from which all other Tuple classes descend.

It's descended from Hash::Ordered because the columns may well need to be ordered. In the case of SQL, it's less important, but in the case of a spreadsheet, it's important.

Field
=====

    class Field does Positional ...

This class represents a field/column in a Relation. It can be read positionally, but should also know and store other relevant attributes about the field. Fields should generally have a name; in an SQL-like setting, it's the actual field name, and in a spreadsheet-like setting, it should generally be the column label (A, B, etc), unless specified otherwise.

The elements in the Field can be accessed positionally. So $field[0] returns the value for this field for the zeroth record/row.

Attributes
----------

**Str $.name**

The Field name.

Methods
-------

### .new

Creates a new Field.

    .new(Relation :$relation, Any:U $type)

**Relation :$relation**

The Relation which contains the field. Required.

**Any:U :$type**

The Field type. Optional. Just pass in the actual type (eg. Str -- no quotes needed). See also .type method, below.

### type

    method 	type(Any:U $value = Nil)

Parameters:

  * Any:U $value = Nil

This method will:

  * Lets you store a type (like the $type parameter to .new)

  * Attempts to deduce a type from the existing data

Here's how it works:

  * If a type is passed in, it will be set as the type of the Field

  * If the type (new or existing) is not Nil, it will be returned

  * If the type is Nil, but there are elements in the Field, it will attempt to deduce the correct type

  * Otherwise, it returns Nil

The process for deducing types is to call `(list).are()` on the list of values that are present in the field.

Relation
========

    role	Relation is SetHash does TOP::Core does Associative does Positional {}

The Relation class' main function at this point is to be composed int the Table class; at some point there will also be a View class, at which point it will become more relevant.

Table
=====

    class	Table does Relation is export {

The Table class is one of the main drivers of TOP. It represents the various backend table classes to the Raku language, so that they can all be accessed via the same API.

Attributes
----------

**$.backend-object**



Holds the backend object (Table::Driver::Postgres, Table::Driver::Memory, etc) that talks to the table in its backend store; the translation layer between Table and the datastore.

**Str $.name**



The table name.

Methods
-------

### .new

Creates a new Table.

    .new(Database :$database, Str :$backend = 'Memory', Str :$action = 'use')

**Database :$database**



The database to which this table should be attached.

**Str :$backend = 'Memory';**



The name of the backend to use when creating this table. The default is that it's an in-memory table.

**Str :$action = 'use'**



What kind of action to take when creating the table.

<table class="pod-table">
<thead><tr>
<th>action</th> <th>definition</th> <th>Error if</th> <th>Will alter</th> <th>Fields</th>
</tr></thead>
<tbody>
<tr> <td>create</td> <td>force create</td> <td>Present</td> <td>No</td> <td>Yes</td> </tr> <tr> <td>alter</td> <td>alter existing</td> <td>Absent</td> <td>Yes</td> <td>Yes</td> </tr> <tr> <td>use</td> <td>no creation</td> <td>Absent</td> <td>No</td> <td>No</td> </tr> <tr> <td>can-create</td> <td>create if not existing</td> <td>No</td> <td>No</td> <td>If Absent</td> </tr> <tr> <td>ensure</td> <td>create or alter</td> <td>No</td> <td>Yes</td> <td>If not conformant</td> </tr>
</tbody>
</table>

### grep

Implements grep on Relation. 

Database
========

    class	Database {...}

This is the Database class from which all other Database classes descend.

Attributes
----------

**$.backend-object**



The backend object that talks to the data store for us.

Methods
-------

### .new

Creates a new Database (ie. database object -- may be attaching to an existing database)

    .new(Str$.backend = 'Memory')

Parameters to .new are:

**Str $.backend = 'Memory'**



The backend that will be used by this database. The default is that it's the in-memory backend.

### method useTable

    method	useTable(:$name)

Creates and returns an object representing the named table in this database.

