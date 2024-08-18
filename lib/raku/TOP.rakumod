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

=begin pod
=head1 Database

	class	Database {...}

This is the Database class from which all other Database classes descend.

=end pod

class	Database {...}

role	Relation is SetHash does TOP::Core does Hash::Agnostic does Positional {...}

class	Field does Positional {
	has	Relation	$!relation	is built is required;	# The relation which contains this field
	has	Str			$.name		is built is required;	# The name of the field
	has	Any:U		$!type		is built = Nil;			# The type of the field (optional)

	# Make a method that a) lets you store a type, and b) attempts to deduce a type from the existing data
	# Process for deducing types: Call (list).are() on the list of values
	method 	type($value = Nil) {
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

role	DoubleInit {
	multi method new(*%attrinit) {
		my $self = callsame;
		say "Parents are " ~ $self.^parents.map({ $_.^name }).join(', ');
		$self.PHASE2(|%attrinit);
	}
}

##### Relations

role	Relation is SetHash does TOP::Core does Associative does Positional {}

class	Table does Relation is export {
	has	Str				$.name		is built is rw; # rw is so it can be set by backend classes where useful
	has	Database		$!database	is built;
	has	Str				$!backend	is built = 'Memory';
	has	Lock	$!loaded-lock = Lock.new();
	# Would like to make this a Table::Driver (which would include subclasses) once I solve the recursive use issue
	has		$.backend-object handles <
		elems EXISTS-POS DELETE-POS ASSIGN-POS BIND-POS
		AT-KEY BIND-KEY CLEAR DELETE-KEY EXISTS-KEY
		makeTuple fill_from_aoh
		fields
	>;
	multi method	STORE(\values, :$INITIALIZE) { $!backend-object.STORE(values, :$INITIALIZE); }
	# When debugging is done, this next can be a one-liner
	multi method	AT-POS(\position) is raw {
		my $p := $!backend-object.AT-POS(position);
		say "Table frontend: " ~ $p.VAR.^name;
		say "beo: " ~ $p.^name;
		say $p.raku;
		say "starting name";
		say "Name: " ~ $p<name>;
		return-rw $p;
	}

	# Hash::Agnostic overrides new and doesn't do TWEAK et. al. -- if that gets fixed, this can go away
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

	=begin pod

	=head3 method useTable

	    method	useTable(Table :$table, Bool :$action, %fields => {})

	=begin table
	action		| definition			| Error if	| Will alter | Fields		|
	=============================================================================
	create		| force create			| Present	| No		| Yes			|
	alter		| alter existing		| Absent	| Yes		| Yes			|
	use			| no creation			| Absent	| No		| No			|
	can-create	| create if not existing | No		| No		| If Absent		|
	ensure		| create or alter		| No		| Yes		| If not conformant	|
	=end table
	=end pod

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

	method  of() { return Mu; }
}

class	Database {
	has	Str	$.backend	is built = 'Memory';
	has		$.backend-object;	# Public for use by Table; make protected with friend

	has		%loaded-drivers;
	has	Lock	$!loaded-lock = Lock.new();

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
			# The above ended up with circular references; need to figure out what the fix is; possibly move Database::Driver into this file

			# Create the object
			M.new(|%parameters);
		}

		without $driver { .throw }

		$!backend-object = $driver;

		return $driver;
	}

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

