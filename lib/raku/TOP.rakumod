use v6.e.PREVIEW;

use	Hash::Ordered;

=begin pod

=head1 TOP::Core

=begin code

role	TOP::Core {}

=end code

This is the common code that's shared across all TOP objects; this is intended
to be a role on all TOP classes.

=end pod

role	TOP::Core {}

=begin pod
=head1 Tuple

	class	Tuple is Hash::Ordered {}

This is the Tuple class from which all other Tuple classes descend.

It's descended from Hash::Ordered because the columns may well need to be
ordered.  In the case of SQL, it's less important, but in the case of a
spreadsheet, it's important.

=end pod

class	Tuple is Hash::Ordered {}

# This is a stub for the database class, and is here so that other classes can
# use it as a type.  See below for real class
class	Database {...}

# This is a stub for the Relation class, so that other classes can use it as a
# type.  See below for real class.
role	Relation is SetHash does TOP::Core does Hash::Agnostic does Positional {...}

=begin pod
=head1 Field

	class Field does Positional ...

This class represents a field/column in a Relation.  It can be read positionally,
but should also know and store other relevant attributes about the field.
Fields should generally have a name; in an SQL-like setting, it's the actual
field name, and in a spreadsheet-like setting, it should generally be the
column label (A, B, etc), unless specified otherwise.

The elements in the Field can be accessed positionally.  So $field[0] returns
the value for this field for the zeroth record/row.

=head2 Attributes

=end pod

class	Field does Positional {
	=begin pod
	=defn Str $.name
	The Field name.
	=end pod
	has	Str			$.name		is built is required;	# The name of the field

	=begin pod
	=head2 Methods
	=head3 .new

	Parameters to .new are:
	=defn Relation	:$relation
	The Relation which contains the field.  Required.
	=end pod
	has	Relation	$!relation	is built is required;	# The relation which contains this field

	=begin pod
	=defn Any:U	:$type
	The Field type.  Optional.  Just pass in the actual type (eg. Str -- no
	quotes needed).  See also .type method, below.
	=end pod
	has	Any:U		$!type		is built = Nil;			# The type of the field (optional)

	=begin pod

	=head3 type

		method 	type(Any:U $value = Nil) {

	Parameters:

	=item Any:U $value = Nil

	This method will:
	=item Lets you store a type (like the $type parameter to .new)
	=item Attempts to deduce a type from the existing data

	Here's how it works:
	=item If a type is passed in, it will be set as the type of the Field
	=item If the type (new or existing) is not Nil, it will be returned
	=item If the type is Nil, but there are elements in the Field, it will
	attempt to deduce the correct type
	=item Otherwise, it returns Nil

	The process for deducing types is to call C<(list).are()> on the list of
	values that are present in the field.
	=end pod
	method 	type(Any:U $value = Nil) {
		$value ~~ Nil or $!type = $value;
		$!type ~~ Nil or return $!type;
		self.elems and do {
			return $!relation.map({ $_{$!name} }).are();
		}
		return Nil;
	}

	# Positional interface, used for rows
	#	Must: elems, AT-POS, EXISTS-POS
	#	May: DELETE-POS, ASSIGN-POS, BIND-POS, STORE
	# Just delegate these to @.rows, if possible
	method elems() {
		return $!relation.elems;
	}

	method	AT-POS(\position) is rw {
		Proxy.new(
			FETCH => {
				$!relation[position]{$!name};
			},
			STORE => -> $, \value {
				$!relation[position]{$!name} = value;
			},
		);
	}

	method	EXISTS-POS(\position) {
		$!relation.rows.EXISTS-POS(position) or return False;
		return $!relation.rows[position]{$!name}:exists;
	}
}

##### Relations

=begin pod
=head1 Relation

	role	Relation is SetHash does TOP::Core does Associative does Positional {}

The Relation class' main function at this point is to be composed int the
Table class; at some point there will also be a View class, at which point it
will become more relevant.

=end pod
role	Relation is SetHash does TOP::Core does Associative does Positional {}

=begin pod
=head1	Table

	class	Table does Relation is export {

The Table class is one of the main drivers of TOP.  It represents the various
backend table classes to the Raku language, so that they can all be accessed
via the same API.

=head2 Attributes

=defn $.backend-object

Holds the backend object (Table::Driver::Postgres, Table::Driver::Memory, etc)
that talks to the table in its backend store; the translation layer between
Table and the datastore.
=end pod
=comment See below for declaration of $.backend-object

class	Table does Relation is export {
	=begin pod
	=defn Str $.name

	The table name.
	=end pod
	has	Str				$.name		is built is rw; # rw is so it can be set by backend classes where useful

	=begin pod
	=head2 Methods
	=head3 .new
	Parameters to .new include:
	=defn Database :$database

	The database to which this table should be attached.

	=end pod
	has	Database		$!database	is built;

	=begin pod
	=defn Str :$backend = 'Memory';

	The name of the backend to use when creating this table.  The default is
	that it's an in-memory table.

	=end pod
	has	Str				$!backend	is built = 'Memory';

	# TODO: Can we eliminate this?
	has	Lock	$!loaded-lock = Lock.new();

	# See above for doco on $.backend-object
	# Would like to make this a Table::Driver (which would include subclasses) once I solve the recursive use issue
	# TODO: Can we use a stub somewhere?
	has		$.backend-object handles <
		elems EXISTS-POS DELETE-POS ASSIGN-POS BIND-POS
		AT-KEY BIND-KEY CLEAR DELETE-KEY EXISTS-KEY
		makeTuple fill_from_aoh
		fields
	>;
	multi method	STORE(\values, :$INITIALIZE) { $!backend-object.STORE(values, :$INITIALIZE); }
	# TODO: When debugging is done, this next can be a one-liner
	multi method	AT-POS(\position) is raw {
		my $p := $!backend-object.AT-POS(position);
		say "Table frontend: " ~ $p.VAR.^name;
		say "beo: " ~ $p.^name;
		say $p.raku;
		say "starting name";
		say "Name: " ~ $p<name>;
		return-rw $p;
	}

	=begin pod
	=defn Str :$action = 'use'

	What kind of action to take when creating the table.  See method C<Database::useTable>
	(below) for more information.

	=end pod
	# Hash::Agnostic overrides new and doesn't do TWEAK et. al. -- if that gets fixed, this can go away
	# TODO: Try to remove this next function; may need to take lizmat's suggestion of blessing the object -- https://irclogs.raku.org/raku/2024-08-17.html#15:41
	multi method new(Database :$database, Str :$backend, Str :$name, Str :$action = 'use', *%parameters) {
		my $n = nextcallee;
		say "=== nextcallee ===";
		dd $n;
		say $n.raku;
		say $n.WHAT;
		my $rv = callsame;
		$rv.TWEAK(:$database, :$backend, :$name, :$action, |%parameters);
		return $rv;
	}

	# TODO: After code cleanup (see new, above), see if we need to comment this function
	submethod	TWEAK(Database :$database, Str :$backend, Str :$name, Str :$action = 'use', *%parameters) {
		say "TWEAKing ## $backend ## $name ## $action\n";
		dd %parameters;
		# This section because Hash::Agnostic overrides new and doesn't do TWEAK
		defined $database and $!database = $database;
		$!backend = defined($backend) ?? $backend !! 'Memory';
		defined $name and $!name = $name;
		say "Preset name to $!name";
		$!loaded-lock = Lock.new();
		# End Hash::Agnostic fix
		defined $!database and do {
			$!backend = $!database.backend;
		};
		if ! defined $!database {
			$!database = Database.new(
				:$!backend,
			);
		}
		dd $!database;
		say "Name is $!name";
		say "returning";

		$!backend-object = $!database.backend-object.useTable(
			table => self,
			:$action,
			|%parameters
		);
		# Has to be after the backend creation because some object types derive the name from other attributes
		defined self.name or die "Error: all tables must be named!";
	}

	# TODO: Can we remove this now that Hash::Agnostic is fixed?
	method  of() { return Mu; }
}

=begin pod
=head1 Database

	class	Database {...}

This is the Database class from which all other Database classes descend.

=head2 Attributes

=end pod

class	Database {
	=begin pod
	=defn $.backend-object

	The backend object that talks to the data store for us.
	=end pod
	has		$.backend-object;	# Public for use by Table; make protected with friend

	has		%loaded-drivers;	# TODO: In some future iteration, this will store a list of the drivers that have been loaded
	has	Lock	$!loaded-lock = Lock.new();

	=begin pod
	=head2 Methods
	=head3 .new()
	Parameters to .new() are:

	=defn Str $.backend = 'Memory'

	The backend that will be used by this database.  The default is that it's
	the in-memory backend.
	=end pod
	has	Str	$.backend	is built = 'Memory';

	submethod	TWEAK(Str :$backend, :%parameters) {
		my $driver = $!loaded-lock.protect: {
			my $module = "Database::Driver::$!backend";
			say "m: $module";

			# Load the relevant module
			my \M = (require ::($module));

			# Check that it's a real driver
#			unless M ~~ Database::Driver {
#				warn "$module doesn't do Database::Driver role!";
#			}
			# TODO: The above ended up with circular references; need to figure out what the fix is; possibly move Database::Driver into this file

			# Create the object
			M.new(|%parameters);
		}

		without $driver { .throw }

		$!backend-object = $driver;

		return $driver;
	}

	# TODO: The formatting on the following table should use tabs -- try to improve it after the Pod6 rewite

	=begin pod

	=head3 method useTable

	    method	useTable(Table :$table, Bool :$action, %fields => {})

	=begin table
	action     | definition             | Error if | Will alter | Fields
	================================================================================
	create     | force create           | Present  | No         | Yes
	alter	   | alter existing         | Absent   | Yes        | Yes
	use        | no creation            | Absent   | No         | No
	can-create | create if not existing | No       | No         | If Absent
	ensure     | create or alter        | No       | Yes        | If not conformant
	=end table
	=end pod

	method	useTable(:$name, *%params) {
		say "Database.useTable";
		my Table $table = Table.new(
			database => self,
			:$!backend,
			action => 'use',
			:$name,
			parameters => %params,
		);
		say "uT1" ~ $table.raku;

		return $table;
	}	
}

