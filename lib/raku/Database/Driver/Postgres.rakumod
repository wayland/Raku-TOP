use	Database::Driver;
use	TOP;
use	DBIish;
use	Slang::Otherwise;

class	Cursor::Driver::Postgres {...}
class	Table::Driver::Postgres does Table::Driver {...}


# Postgres driver
class	Database::Driver::Postgres does Database::Driver {
	has	$.database-name;
	has	$.handle;
	has	%!tableObjects;

	submethod	TWEAK(:$database-name, :$username is copy) {
		say "t1";
		$!database-name or die "Error: no database name passed in";
		$username or $username = Database::Driver::Postgres.get_username();
say "t2 {$database-name} ## {$username}";

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
say "Matching $fieldname '{%pgpass{$fieldname}}' against {$regexp.raku}";
					(%pgpass{$fieldname} ~~ /<$regexp>/) and do { say "succeeding"; succeed; }
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
say 'Er' ~ %*ENV.raku;
		for <LOGNAME USER USERNAME> -> $varname {
			$username = %*ENV{$varname};
			$username and last;
		}
		$username or do {
say "H1 " ~ %*ENV{'HOME'};
say "H2 " ~ %*ENV{'HOME'}.split(/\//);
say "H3 " ~ %*ENV{'HOME'}.split(/\//).tail;
			$username = %*ENV{'HOME'}.split(m{\/}).tail;
		};

		return $username;
	}

	method	useTable(Table :$table, Str :$action = 'use', :%fields = {}) {
		my Str $name = $table.name;
		say "useTable $name";

		%!tableObjects{$name} = Table::Driver::Postgres.new(
			database => self,
			frontend-object => $table,
			fields => %fields,
			action => $action,
		);
say "found";
		return %!tableObjects{$name};
	}
}

class	Tuple::Postgres is Tuple {
	has	Table::Driver::Postgres	$!table is built is required;
	has	Int						$.position;	# Position within the table
	has	Bool					$.auto-update-database = True; # Indicates whether AT-KEY should update the database when written
	has	Proxy					$!proxy;

	submethod	TWEAK(:%initial-values) {
		# Set up hash values
		%initial-values.kv.map: -> $key, $value { self.Tuple::AT-KEY($key) = $value };

		return True;
	}

	method	AT-KEY($key) is raw {
		my $fullself = self;
		my $p := Proxy.new(
			FETCH => {
				my $rv = $fullself.Tuple::AT-KEY($key);
				$rv;
			},
			STORE => -> $, \value {
				$fullself.Tuple::AT-KEY($key) = value;
				$!auto-update-database and $!table[$!position] = self;
			}
		);
		return-rw $p;
	}
}

class	Table::Driver::Postgres does Table::Driver does Hash::Agnostic {
	has	Database::Driver::Postgres	$!database is built is required;
	has	Cursor::Driver::Postgres	$!basic-cursor handles <EXISTS-POS elems>;
	has	Str							%!primary-keys;
	has	Bool						$!needs-refresh = True;
	has	Int							$!at-pos-cache-position = Nil;
	has								$!at-pos-cache-item;

#	has				$!use-cache;
	# Currently public for access by Field object -- make protected/friend if useful
#	has	Tuple		@.cache handles <EXISTS-POS DELETE-POS ASSIGN-POS BIND-POS>;

	# Required to resolve between parent classes
	method	new(:$database) {
		my $rv = callsame;

		return $rv;
	}

	submethod	TWEAK(
		Database::Driver::Postgres :$database
	) {
		# Set up object
		if $!init-create {
			die "Create not implemented yet";
			#			%!tableObjects{$name} = Table::Driver::Postgres.new(
			#				database => self,
			#				frontend-object => $table,
			#			);
		} elsif $!init-alter {
			die "Alter not implemented yet";
		} else {
			say "Not altering or creating";
		}
		say "Table object created";

		my $handle = self.query(qq:to/EOT/);
			SELECT c.column_name, c.data_type
			FROM information_schema.table_constraints tc
			JOIN information_schema.constraint_column_usage AS ccu USING (constraint_schema, constraint_name)
			JOIN information_schema.columns AS c ON c.table_schema = tc.constraint_schema
				AND tc.table_name = c.table_name AND ccu.column_name = c.column_name
			WHERE constraint_type = 'PRIMARY KEY' and tc.table_name = '{$!frontend-object.name}';
		EOT
		for $handle.allrows() -> $row {
			my ($key, $value) = $row;
			%!primary-keys{$key} = $value;
		}
	}

	method	exists(Str :$true-error, Str :$false-error) {
		my Bool $exists =  self.create_fields_from_columns();
		$exists and $true-error.defined and die "{$true-error} in database '{$!database.database-name}'";
		! $exists and $false-error.defined and die "{$false-error} in database '{$!database.database-name}'";
		return $exists;
	}

	method	create_fields_from_columns() {
		if %!field-indices.elems { return True; }
		my @rows = self.fetch_columns();
		my %column-map = %(
			column-name => 'column_name',
			data-type => 'data_type',
			database-name => 'table_catalog',
			table-name => 'table_name',
			schema-name => 'table_schema',
		);
		my %useful-columns;
		for @rows -> $row {
			%useful-columns = %column-map.kv.map: -> $key, $val { $key => $row{$val} };
			say 'useful-columns: ';
			say %useful-columns;
			my $key = %useful-columns<column-name>;
			self.add-field(relation => $!frontend-object, name => $key);
		} otherwise {
			return False;
		}
		return True;
	}

	method	fetch_columns() {
		my $statement-handle = self.query(qq:to/STATEMENT/);
			SELECT *
			FROM information_schema.columns
			WHERE
				table_schema = 'public'
				AND table_name = '{$!frontend-object.name}'
			;
			STATEMENT
			return($statement-handle.allrows(:array-of-hash));
	}


	method	create-table-from-fields(Bool $alter = False) {
		if ! @!fields.elems { die "Error: can't create table from fields when no fields exist"; }
		my @column-specs;
		my %extras = %(
			'alpha-3' => "PRIMARY KEY",
		);
		for @!fields -> $field {
			my $extra = %extras{$field.name}:exists ?? %extras{$field.name} !! '';
			@column-specs.push: qq["{$field.name}" {self.postgres-type-from-raku-type($field.name)} {$extra}];
		}
		say 'column-specs';
		say @column-specs;
		my $column-specs = @column-specs.join(', ');
		self.query("CREATE TABLE {$!frontend-object.name} ($column-specs)");
	}

	# We're intending that this work for:
	# -	Raku Num, Int -> Numeric types (and maybe we could refine this with eg. Raku int16, etc -- https://docs.raku.org/language/nativetypes)
	# -	Raku Str -> Character Types
	# -	Raku DateTime types (DateTime, Date, Duration) -> Date/Time types
	# -	Raku Bool -> Boolean types
	# Eventually:
	# -	Raku array/hash -> JSON, XML, or array types
	# https://www.postgresql.org/docs/current/datatype.html
	method	postgres-type-from-raku-type(Str $field-name) {
		my $raku-type = self.{$field-name}.type();
		my %type-translations = %{
			'Int' => 'bigint',
			'Num' => 'numeric',
			'Str' => 'text',
				'Cool' => 'text',
				'IntStr' => 'text',
			'DateTime' => 'timestamp with time zone',
			'Date' => 'date',
			'Duration' => 'interval',
			'Bool' => 'boolean',
		};
		my $postgres-type = %type-translations{$raku-type.^name};
		return $postgres-type;
	}

	method	fill_from_aoh(@rows) {
		say "fill_from_aoh not fully implemented yet";
		my Any:U %field-types;
		for @rows -> $row {
			for $row.kv -> $field-name, $field-value {
				if %field-types{$field-name}:exists {
					%field-types{$field-name} = ($field-value, %field-types{$field-name}).are();
				} else {
					%field-types{$field-name} = $field-value.WHAT;
				}
			}
		}
		for %field-types.kv -> $field-name, $field-type {
			%!field-indices{$field-name}:exists or
				self.add-field(relation => $!frontend-object, name => $field-name, type => $field-type);
		}
		self.create-table-from-fields();
		for @rows -> $row {
			my @fieldnames;
			my @fieldvalues;
			for $row.kv -> $fieldname, $fieldvalue is copy {
				$fieldvalue.can('elems') and $fieldvalue.elems == 0 and $fieldvalue = '';
				push @fieldnames, $fieldname;
				push @fieldvalues, self.escape($fieldvalue, :as-string);
			}
			my $field-names = @fieldnames.map({ qq{"$_"} }).join(', ');
			my $field-values = @fieldvalues.join(', ');
			self.query("INSERT INTO {$!frontend-object.name} ($field-names) VALUES ($field-values);");
		}
	}

	method  of() { return Mu; }


	method	query(Str $sql) {
		#say "SQL is " ~ $sql;
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
	method	AT-POS(\position) is raw {
		my $p := Proxy.new(
			FETCH => {
#				say "Table P AT-POS FETCH {position}";
				if defined($!at-pos-cache-position) and position == $!at-pos-cache-position {
					$!at-pos-cache-item;
				} else {
					$!at-pos-cache-position = position;
					$!at-pos-cache-item = Tuple::Postgres.new(
						table => self,
						position => position,
						initial-values => %( $.basic-cursor.AT-POS(position) ),
					);
					say "starting acpi";
					say "apci: " ~ $!at-pos-cache-item{'name'};
				}
				$!at-pos-cache-item;
			},
			STORE => -> $, \value {
				say "Table P AT-POS STORE {position}";
				my $item = $.basic-cursor.AT-POS(position);
				my %where;
				if %!primary-keys.elems {
					for %!primary-keys.keys -> $key {
						%where{$key} = $item{$key};
					}
				} else {
					%where = %( $item.kv ); # Everything is part of the primary key
				}
				my $set-string = self.hash-to-sql(value);
				my $where-string = self.hash-to-sql(%where, join => 'AND');

				my $result = self.query(qq[UPDATE {$!frontend-object.name} SET $set-string WHERE $where-string]);
			},
		);
		say "Table backend: " ~ $p.VAR.^name;
		return-rw $p;
	}

	method	escape(Str $text is copy, Bool :$as-string = False) {
		$text ~~ s/\'/''/;
		return $as-string ?? qq{'$text'} !! $text;
	}

	# Formats are:
	# -	equals: key = value, suitable for use in SET and WHERE clauses
	# -	insert: Returns two ordered, comma-separated list suitable for use in INSERT statements
	method	hash-to-sql(%hash, :$format = 'equals', :$join = ',') {
		given $format {
			when 'equals' {
				return %hash.kv.map(-> $key, $value {
					qq["$key" = {self.escape($value, :as-string)}];
				}).join(' ' ~ $join ~ ' ');
			}
			when 'insert' {
				say "insert";
				my @fieldnames;
				my @fieldvalues;
				for %hash.kv -> $fieldname, $fieldvalue {
					push @fieldnames, $fieldname;
					dd $fieldvalue;
					push @fieldvalues, self.escape($fieldvalue, :as-string);
				}
				my $field-names = @fieldnames.map({ qq{"$_"} }).join(', ');
				my $field-values = @fieldvalues.join(', ');
				return $field-names, $field-values;
			}
			default {
				die "Error: Unknown format '$format'";
			}
		}
	}
}

class	Cursor::Driver::Postgres does Positional {
	has	Database::Driver::Postgres	$!database		is built is required;
	has	Str							$!cursor-name	is built is required;
	has	Str							$!table-name	is built is required;
	has								$!handle;
	has Bool						$!writable = False;
	has	Bool						$!scrollable = False;
	has	Bool						$!needs-update = False;

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
		say "Cursor SQL is " ~ $sql;
		return $!database.handle.execute($sql);
	}

	# Positional interface, used for rows
	#	Must: elems, AT-POS, EXISTS-POS
	#	May: DELETE-POS, ASSIGN-POS, BIND-POS, STORE
	method	AT-POS(\position) {
		my $result = self.query(qq[FETCH ABSOLUTE {position+1} FROM "$!cursor-name";]);
		return $result.allrows(:array-of-hash)[0];
	}

	method	EXISTS-POS(\position) {
		return position < self.elems;
	}

	method	elems() {
		my $result = self.query(qq{MOVE FORWARD ALL FROM "$!cursor-name";});
		return $result.rows;
	}

#	method	AT-POS() {
#	}
}

