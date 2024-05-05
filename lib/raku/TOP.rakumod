
# Things to check after upgrading from Raku 2022.04
# -	Can I uncomment the stuff in gist without crashing?  
# -	Can I use the pre-initialised $!field-mode variable?  

use v6.c;

use	Hash::Ordered;
use	Hash::Agnostic:ver<0.0.11>:auth<zef:lizmat>;

role	TOP::Core {}

class	Tuple is Hash::Ordered {}

class	Database {...}

role	Relation is SetHash does TOP::Core does Hash::Agnostic does Positional {...}

class	Field does Positional {
	has	Relation	$!relation	is built is required;	# The relation which contains this field
	has	Str		$!name		is built is required;	# The name of the field

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

role	Relation is SetHash does TOP::Core does Associative does Positional {}

class	Table does Relation is export {
	has	Str				$.name		is built;
	has	Database		$!database	is built;
	has	Str				$!backend	is built = 'Memory';
	has	Lock	$!loaded-lock = Lock.new();
	has		$.backend-object handles <
		elems AT-POS EXISTS-POS DELETE-POS ASSIGN-POS BIND-POS
		AT-KEY BIND-KEY CLEAR DELETE-KEY EXISTS-KEY
		makeTuple fill_from_aoh
		fields
	>;
	multi method	STORE(\values, :$INITIALIZE) { $!backend-object.STORE(values, :$INITIALIZE); }

	# Hash::Agnostic overrides new and doesn't do TWEAK et. al. -- if that gets fixed, this can go away
	method new(Database :$database, Str :$backend, Str :$name, Str :$action = 'use', :%parameters) {
		say "new";
		my $rv = callsame;
		$rv.TWEAK(:$database, :$backend, :$name, :$action, :%parameters);
		say "new2" ~ $rv;
		return $rv;
	}

	submethod	TWEAK(Database :$database, Str :$backend, Str :$name, Str :$action = 'use', :%parameters) {
		say "TWEAKing\n";
		# This section because Hash::Agnostic overrides new and doesn't do TWEAK
		defined $database and $!database = $database;
		$!backend = defined($backend) ?? $backend !! 'Memory';
		defined $name and $!name = $name;
		say "Set name to $!name";
		$!loaded-lock = Lock.new();
		# End Hash::Agnostic fix
		defined $!database and do {
			$!backend = $!database.backend;
		};
		say "Action: " ~ $action;
		if $action eq 'use' {
			say "using";
			if defined $!database {
				say "defined";
				$!backend-object = $!database.backend-object.useTable(table => self, |%parameters);
				say "after";
			} else {
				die "Can't use a table without a defined database; either use a database, or use fromfile or create";
			}
		} else {
			if ! defined $!database {
				$!database = Database.new(
					backend => $!backend,
				);
			}
			$!backend-object = $!database.backend-object.useTable(table => self, |%parameters);
		}
		say "returning";
		return self;
	}

	method  of() { return Mu; }

	method raku {
		self.^name ~ " \{...\}" ~ ' .raku-needs-fixing';
	}
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
			backend => $!backend,
			action => 'use',
			name => $name,
			parameters => %params,
		);
		say "uT1" ~ $table.raku;

		return $table;
	}	
}

