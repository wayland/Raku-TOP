use	Database::Driver;
use TOP;
use	DBIish;

class	Cursor::Driver::Postgres {...}
class	Table::Driver::Postgres does Table::Driver {...}


# Postgres driver
class	Database::Driver::Postgres does Database::Driver {
	has	$.database-name;
	has	$.handle;
	has	%!tableObjects;

	submethod	TWEAK(:$database-name) {
		say "t1";
		$!database-name or die "Error: no database name passed in";
		my $username = Database::Driver::Postgres.get_username();

		# PostgreSQL config
		my @lines = (%*ENV<HOME> ~ "/.pgpass").IO.slurp.split(/\n/);
		my %pgpass;
		given * {
			for [
				{ field => 'database', regexp => /^({$database-name})$/, },
				{ field => 'user', regexp => /^($username)$/, },
				{ field => 'database', regexp => /^\*$/, },
			] -> %fields {
				my ($fieldname, $regexp) = map { %fields{$_} }, <field regexp>;
				for @lines -> $line {
					$line ~~ /^\s*$/ and next;
					%pgpass = <host port database user password> Z=> split(/\:/, $line);
					# In theory, "succeed" should not work here.  In theory, there's a "leave" keyword that *should* work here
					(%pgpass{$fieldname} ~~ /<$regexp>/) and succeed;
				}
			}
			default { die "Did not match any .pgpass entries"; }
		}
		%pgpass<database> eq '*' and %pgpass<database> = $!database-name;

		$!handle = DBIish.connect('Pg', |%pgpass);
	}

	method	table_object(:$table-name = Any, :$tableclass = DominionDocuments::Database::SheetFromTable, :$toname = Any) {
		defined($table-name) or return %!tableObjects{$toname};

say "Making {$tableclass.raku} ($table-name, $toname)";
		%!tableObjects{$toname} = $tableclass.new(
			:$table-name,
			session => self,
		);

		return %!tableObjects{$toname};
	}

	# Class method; calls 'new'
	method	create(*%params) {
		qx/createdb {$params{database-name}}/;
		Database::Driver::Postgres.new(|%params);
	}

	# Should be callable as a class method
	method	get_username {
		my $username;
		for <LOGNAME USER USERNAME> -> $varname {
			$username = $*ENV{$varname};
			$username and last;
		}

		return $username;
	}

	method	useTable(Table :$table) {
		my Str $name = $table.name;
		say "useTable $name";
		%!tableObjects{$name} = Table::Driver::Postgres.new(
			database => self,
			frontend-object => $table,
		);
say "found";
		return %!tableObjects{$name};
	}
}

class	Table::Driver::Postgres does Table::Driver does Hash::Agnostic {
	has	Database::Driver::Postgres	$!database is built is required;
	has	Relation	$!frontend-object	is built is required;
	has	Cursor::Driver::Postgres	$!basic-cursor;

	has				$!use-cache;
	# Currently public for access by Field object -- make protected/friend if useful
	has	Tuple		@.cache handles <EXISTS-POS DELETE-POS ASSIGN-POS BIND-POS>;

	# Only required because Hash::Agnostic is broken
	method	new(:$database) {
		say "TDP n1";
		my $rv = callsame;
		say "TDP n2";
		#$rv.TWEAK(:$database);
		say "TDP n3";

		return $rv;
	}

	submethod	TWEAK(:$database, :$frontend-object) {
		# Only required because Hash::Agnostic is broken
		defined $database and $!database = $database;
		defined $frontend-object and $!frontend-object = $frontend-object;
		# End Hash::Agnostic breakage
		say "TDP TWEAK";
		my $statement-handle = self.query(qq:to/STATEMENT/);
		SELECT *
		FROM information_schema.columns
		WHERE
			table_schema = 'public'
			AND table_name = '{$!frontend-object.name}'
		;
		STATEMENT
		for $statement-handle.allrows(:array-of-hash) -> $row {
			my %column-map = %(
				column-name => 'column_name',
				data-type => 'data_type',
				database-name => 'table_catalog',
				table-name => 'table_name',
				schema-name => 'table_schema',
			);
			my %useful-columns = %column-map.kv.map: -> $key, $val { $key => $row{$val} };
			say %useful-columns;
			my $key = %useful-columns<column-name>;
			%!field-indices{$key}:exists or do {
				self.{$key} = Field.new(relation => $!frontend-object, name => $key);
			};

		}
	}

	method	fill_from_aoh(@rows) {
		say "fill_from_aoh not implemented yet";
	}

	method raku {
		self.^name ~ " \{...\}" ~ ' .raku-needs-fixing';
	}
	method  of() { return Mu; }


	method	query($sql) {
		say "SQL is " ~ $sql;
		return $!database.handle.execute($sql);
	}

	method	basic-cursor() {
		defined $!basic-cursor and return $!basic-cursor;
		my $table-name = $!frontend-object.name;
		$table-name or die "Error: Unnamed table!";
		my $cursor-name = "{$table-name}_basic_cursor";
		$!basic-cursor = Cursor::Driver::Postgres.new(
			:$cursor-name,
			:$table-name,
			database => $!database,
		);
		return $!basic-cursor;
	}

	# Positional interface, used for rows
	#	Must: elems, AT-POS, EXISTS-POS
	#	May: DELETE-POS, ASSIGN-POS, BIND-POS, STORE
	# Just delegate these to @.rows, if possible
	method AT-POS(\position) {
		self.basic-cursor.AT-POS(position);
	}

	method	elems() {
		return self.basic-cursor.elems;
	}
}

class	Cursor::Driver::Postgres does Positional {
	has	Database::Driver::Postgres	$!database		is built is required;
	has	Str							$!cursor-name	is built is required;
	has	Str							$!table-name	is built is required;
	has								$!handle;
	has Bool						$!writable = False;
	has	Bool						$!scrollable = False;

	submethod	TWEAK() {
		if $!writable and $!scrollable {
			die "Error: Cursor cannot be both writable and scrollable at this time (Postgres doesn't support it, and we haven't built workarounds)";
		}
		my $scrollable-text = $!scrollable ?? " SCROLL " !! '';
		my $sql;
		if $!writable {
			die "Writable cursors not implemented yet; need to add 'FOR UPDATE' and get rid of 'WITH HOLD' (and thus put it in a transaction)";
		} else {
			$sql = qq{DECLARE "$!cursor-name" $scrollable-text CURSOR WITH HOLD FOR SELECT * FROM "$!table-name"};
		}
		$!handle = self.query($sql);
		say "Cursor " ~ $!handle.rows;
	}

	method	query(Str $sql) {
		#say "Cursor SQL is " ~ $sql;
		return $!database.handle.execute($sql);
	}

	method	AT-POS(\position) {
		my $result = self.query(qq[FETCH ABSOLUTE {position+1} FROM "$!cursor-name";]);
		return $result.allrows(:array-of-hash)[0];
	}

	method	elems() {
		my $result = self.query(qq{MOVE FORWARD ALL FROM "$!cursor-name";});
		return $result.rows;
	}
}

