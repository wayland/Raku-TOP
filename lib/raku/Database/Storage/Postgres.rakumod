use	Database::Storage;
use	TOP;
use	DBIish;
use	Slang::Otherwise;

# Pre-declarations so that we can use class names
class	Cursor::Storage::Postgres {...}
class	Table::Storage::Postgres does Table::Storage {...}


=begin pod

=NAME Postgres Storage - The Postgres driver for Raku TOP

=TITLE Postgres Storage

=SUBTITLE The Postgres driver for Raku TOP

=AUTHOR Tim Nelson - https://github.com/wayland

=head1 Database::Storage::Postgres

=begin code

class	Database::Storage::Postgres does Database::Storage {

=end code

Currently uses a cursor for all reads.  What we'd like to change is:

=item1 The user can specify a mode:
=item2 B<Key:> Uses a key field (default: primary key) to track rows; doesn't matter if we miss some when paginating, etc (ie. if others have been added into the sequence)
=item2 B<NumKey:> Like Key, but the key has to be numeric
=item2 B<Sort+Key:> Like Key, but also applies an ordering to the table (ie. an ordering other than by Key)
=item2 B<Cursor:> Uses cursors to match things up; could be suitable for eg. batch jobs

The current (only) behaviour is Cursor.  We'd like to make the other options available, and default to NumKey (since it's probably the quickest, and loads the database least).

=head2 Methods

=end pod


class	Database::Storage::Postgres does Database::Storage {
	has	$.database-name;
	has	$.handle;
	has	%!tableObjects;

	# Set up the Database Storage
	submethod	TWEAK(:$database-name, :$username is copy) {
		# Check the parameters
		$!database-name or die "Error: no database name passed in";
		$username or $username = Database::Storage::Postgres.get_username();

		# Read PostgreSQL config and map into fields that can be passed to DBIish.connect
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
					(%pgpass{$fieldname} ~~ /<$regexp>/) and do { succeed; }
				}
			}
			default { die "Did not match any .pgpass entries"; }
		}
		%pgpass<database> eq '*' and %pgpass<database> = $!database-name;

		# Set up actual connection to database
		$!handle = DBIish.connect('Pg', |%pgpass);
	}

	# Fetch OS username on local (Unix) system
	# Needs to be callable as a class method so that it can be called from TWEAK, above
	method	get_username {
		my $username;
		for <LOGNAME USER USERNAME> -> $varname {
			$username = %*ENV{$varname};
			$username and last;
		}
		$username or do {
			$username = %*ENV{'HOME'}.split(m{\/}).tail;
		};

		return $username;
	}

	=begin pod
	=head3 .useTable

	=begin code
	method	useTable(Table :$table, Str :$action = 'use', :%fields = {}) {
	=end code

	=defn Table :$table
	The frontend table object that's going to reference this backend
	=defn Str :$action = 'use'
	Documented in TOP Table.new()

	=defn :%fields = {}
	The fields to be used on the table.

	=end pod
	method	useTable(Table :$table, Str :$action = 'use', :%fields = {}) {
		my Str $name = $table.name;

		%!tableObjects{$name} = Table::Storage::Postgres.new(
			database => self,
			frontend-object => $table,
			fields => %fields,
			action => $action,
		);
		return %!tableObjects{$name};
	}
}

# Represents a Postgres tuple
class	Tuple::Storage::Postgres is Tuple {
	has	Table::Storage::Postgres	$!table is built is required;	# The table in which the Tuple is stored
	has	Int						$.position;						# Position within the table
	has	Bool					$.auto-update-database = True;	# Indicates whether AT-KEY should update the database when written

	submethod	TWEAK(:%initial-values) {
		# Set up initial values in this tuple
		%initial-values.kv.map: -> $key, $value { self.Tuple::AT-KEY($key) = $value };

		return True;
	}

	# Sets/fetches one cell in this Tuple
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


class	Table::Storage::Postgres does Table::Storage does Hash::Agnostic {
	has	Cursor::Storage::Postgres	$!basic-cursor handles <EXISTS-POS>;	# Holds the cursor that does some of the work for us -- see note at top about how we'd like this to be more optional
	has	Str							%!column-keys;							# Maps a Field name to its primary key in information_schema.columns
#	has	Bool						$!needs-refresh = True;

	# Persistent cache for .AT-POS; only caches a single item
	has	Int							$!at-pos-cache-position = Nil;
	has								$!at-pos-cache-item;

	# Required to resolve between parent classes
	method	new(Database::Storage :$database) {
		my $rv = callsame;

		return $rv;
	}

	# Can't delegate because we want it to call the basic-cursor method which will instantiate the object
	method	elems() {
		return $.basic-cursor.elems;
	}

	submethod	TWEAK(
		Database::Storage::Postgres :$database
	) {
		# Set up object
		if $!init-create {
			# TODO: Implement create
			die "Create not implemented yet";
			#			%!tableObjects{$name} = Table::Storage::Postgres.new(
			#				database => self,
			#				frontend-object => $table,
			#			);
		} elsif $!init-alter {
			# TODO: Implement alter
			die "Alter not implemented yet";
		} else {
			say "Not altering or creating -- we'll give it a go";
		}

		# Populate %!column-keys (see Attributes, above)
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
			%!column-keys{$key} = $value;
		}
	}

	# Returns True if the table exists; see Table::Storage for more info
	method	raw-exists() {
		my Bool $exists =  self.create_fields_from_columns();
		return $exists;
	}

	# Use the columns in the Postgres database to create Field objects
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

	# Fetches a list of all the columns in the Postgres database for this table
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

	# Creates a table in the Postgres database from the Fields connected to this Table object
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
		my $column-specs = @column-specs.join(', ');
		self.query("CREATE TABLE {$!frontend-object.name} ($column-specs)");
	}

	# What it does: Given the name of a Field, returns the name of the Postgres type that matches the Raku type associated with that field
	# We're intending that this work for:
	# -	Raku Num, Int -> Numeric types (and maybe we could refine this with eg. Raku int16, etc -- https://docs.raku.org/language/nativetypes)
	# -	Raku Str -> Character Types
	# -	Raku DateTime types (DateTime, Date, Duration) -> Date/Time types
	# -	Raku Bool -> Boolean types
	# Eventually:
	# -	Raku array/hash -> JSON, XML, or array types
	# https://www.postgresql.org/docs/current/datatype.html
	method	postgres-type-from-raku-type(Str $field-name) {
		# Gets the Raku type of the field name that was passed in
		my $raku-type = self.{$field-name}.type();
		# Sets up table of type translations
		# TODO: we should find somewhere more useful to store this.
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
		# Gets the Postgres type associated with the Raku type
		my $postgres-type = %type-translations{$raku-type.^name};
		return $postgres-type;
	}

	# Uses an Array of Hash to fill in the rows of the table
	# TODO:
	# - Create a "fill" function that takes another Table as the source
	# -	On Table::Storage::Memory, make a fill function that takes an AOH
	# -	Remove this function, since it can be replaced with "fill"
	method	fill_from_aoh(@rows) {
		say "fill_from_aoh will be replaced with 'fill' someday";
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
			self.insert-row($row);
		}
	}

	method insert-row($newTuple) { # $newTuple could be either a Tuple or a $row (see fill_from_aoh)
		my @fieldnames;
		my @fieldvalues;
		for $newtuple.kv -> $fieldname, $fieldvalue is copy {
			$fieldvalue.can('elems') and $fieldvalue.elems == 0 and $fieldvalue = '';
			push @fieldnames, $fieldname;
			push @fieldvalues, self.escape($fieldvalue, :as-string);
		}
		my $field-names = @fieldnames.map({ qq{"$_"} }).join(', ');
		my $field-values = @fieldvalues.join(', ');

		self.query("INSERT INTO {$!frontend-object.name} ($field-names) VALUES ($field-values);");
	}

	multi method	add-row(@fields) {
		my Tuple $newTuple = callsame;
		self.insert-row($newTuple);
	}
	multi method	add-row(%fields) {
		my Tuple $newTuple = callsame;
		self.insert-row($newTuple);
	}

	# Runs a SQL query on this database
	# TODO: possibly this should be moved to the $!database itself
	method	query(Str $sql) {
		#say "SQL is " ~ $sql;
		return $!database.handle.execute($sql);
	}

	# If $!basic-cursor is defined, return it, otherwise make it
	method	basic-cursor() {
		defined $!basic-cursor and return $!basic-cursor;
		my $table-name = $!frontend-object.name;
		$table-name or die "Error: Unnamed table!";
		my $cursor-name = "{$table-name}_basic_cursor";
		$!basic-cursor = Cursor::Storage::Postgres.new(
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
				if ! (defined($!at-pos-cache-position) and position == $!at-pos-cache-position) {
					$!at-pos-cache-position = position;
					$!at-pos-cache-item = Tuple::Storage::Postgres.new(
						table => self,
						position => position,
						initial-values => %( $.basic-cursor.AT-POS(position) ),
					);
				}
				$!at-pos-cache-item;
			},
			STORE => -> $, \value {
#				say "Table P AT-POS STORE {position}";
				my $item = $.basic-cursor.AT-POS(position);
				my %where;
				if %!column-keys.elems {
					for %!column-keys.keys -> $key {
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
#		say "Table backend: " ~ $p.VAR.^name;
		return-rw $p;
	}

	# SQL string escaping function for next function
	# TODO:  should probably be moved to $!database
	# $as-string says whether it should be quoted like a string or not
	method	escape(Str $text is copy, Bool :$as-string = False) {
		$text ~~ s/\'/''/;
		return $as-string ?? qq{'$text'} !! $text;
	}

	# Converts a Raku hash to a string suitable for use in SQL
	# Formats are:
	# -	equals: key = value, suitable for use in SET and WHERE clauses
	# -	insert: Returns two ordered, comma-separated lists suitable for use in INSERT statements
	# TODO:  should probably be moved to $!database
	method	hash-to-sql(%hash, :$format = 'equals', :$join = ',') {
		given $format {
			when 'equals' {
				return %hash.kv.map(-> $key, $value {
					qq["$key" = {self.escape($value, :as-string)}];
				}).join(' ' ~ $join ~ ' ');
			}
			when 'insert' {
				my @fieldnames;
				my @fieldvalues;
				for %hash.kv -> $fieldname, $fieldvalue {
					push @fieldnames, $fieldname;
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

# Represents a cursor on a database
class	Cursor::Storage::Postgres does Positional {
	has	Database::Storage::Postgres	$!database		is built is required;
	has	Str							$!cursor-name	is built is required;
	has	Str							$!table-name	is built is required;
	has								$!handle;
	has Bool						$!writable = False;
	has	Bool						$!scrollable = False;
	has	Bool						$!needs-update = False;
	has Int							$!position;	# The current cursor position; zero-indexed, so one less than the Postgres number

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
	}

	# TODO: Look at moving to $!database
	method	query(Str $sql) {
		#say "Cursor SQL is " ~ $sql;
		return $!database.handle.execute($sql);
	}

	# Positional interface, used for rows
	#	Must: elems, AT-POS, EXISTS-POS
	#	May: DELETE-POS, ASSIGN-POS, BIND-POS, STORE
	method	AT-POS(\position) {
		$!position = position;
		my $result = self.query(qq[FETCH ABSOLUTE {position+1} FROM "$!cursor-name";]);
		return $result.allrows(:array-of-hash)[0];
	}

	method	EXISTS-POS(\position) {
		return position < self.elems;
	}

	method	elems() {
		self.query(qq{MOVE ABSOLUTE 0 FROM "$!cursor-name";});
		my $result = self.query(qq{MOVE FORWARD ALL FROM "$!cursor-name";});
		$!position = $result.rows - 1;
		return $result.rows;
	}
}

