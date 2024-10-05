use     Database::Driver;
use     TOP;

class	Database::Driver::Memory {...}

=begin pod

=NAME Raku *::Driver::Memory - Raku classes to implement the in-memory table store

=TITLE Raku *::Driver::Memory

=SUBTITLE Raku classes to implement the in-memory table store

=AUTHOR Tim Nelson - https://github.com/wayland

=head1 Table::Driver::Memory

	class	Table::Driver::Memory does Table::Driver {

=head1 Usage

=head3 The Easy Options

	Table.new(name => 'countries', action => 'can-create'),

The default database (if none is specified) is a Memory database, so there's
not much you need to specify when using one of these.

=head3 The Flexible Option

	$memdb = Database.new(
		name => 'MyMemoryDatabase',
	);
	$memdb.useTable(name => 'countries');

The parameters to Database.useTable are basically the same as are passed to Table.new().

=end pod
class	Table::Driver::Memory does Table::Driver {
	# Currently public for access by Field object -- make protected/friend if useful
	has	Tuple	@.rows handles <elems EXISTS-POS DELETE-POS ASSIGN-POS BIND-POS>;

	# TODO:
	# Not implemented yet
	# Could be:
	# -	'pragma' (default): Controlled by the strict pragma, as follows:
	#	-	off: extra fields create new columns
	#	-	on (default): extra fields create an error
	# -	'overflow': extra fields get stuck in a JSON hash/object/assoc field; the name of the field is in $!overflow-field-name
	has	Str	$!field-mode = 'lax';
	has	Str	$!overflow-field-name;

	method	new(:$database, *@_, *%_) {
		my $usedb;
		if $database ~~ Database::Driver {
			$usedb = $database;
		} else {
			$usedb = Database::Driver::Memory.new();
		}
		callwith(database => $usedb, |@_, |%_);
	}

	# Doco: Documented in Table::Driver
	# TODO: a) Populate Table::Driver::Memory.database and b) make this check database.tables
	method	raw-exists() {
		return False;
	}

	# Makes a Tuple object from the key/values specified in %items, and returns it
	multi	method	makeTuple(%items) {

		#		die "fm2: {$!field-mode}";
		my $field-mode = $!field-mode ?? $!field-mode !! 'lax'; # This shouldn't be needed, but it is at the moment -- try removing it and seeing if things work
		for %items.kv -> $key, $value {
			#			say "Processing $key => $value";
			# Check fields here; use $field-mode, above
			#			say "fm: {$field-mode} ## $key";
			#			say self.raku;
			given $field-mode {
				when 'strict' {
					%!field-indices{$key}:exists or die "Error: Field '$key' doesn't exist\n";
				}
				when 'lax' {
					%!field-indices{$key}:exists or do {
						self.{$key} = Field.new(relation => $!frontend-object, name => $key);
					};
				}
				default {
					die "Unknown field mode '{$field-mode}'";
				}
			}
		}

		Tuple.new(%items);
	}
	multi	method	makeTuple(@items) {
		my %items is Hash::Ordered = 'A'..* Z=> @items;
		self.makeTuple(%items);
	}

	# Allows people to assign to this table
	multi	method	STORE(\values, :$INITIALIZE) {
		for values -> $row {
			@!rows.STORE(self.makeTuple($row), :$INITIALIZE);
		}

		return self;
	}

	# If we don't have this, we get the error: Method 'of' must be resolved by class Table::Driver::Memory because it exists in multiple roles (Associative, Positional)
	method	of() { return Mu; }

	# Positional interface, used for rows
	#	Must: elems, AT-POS, EXISTS-POS
	#	May: DELETE-POS, ASSIGN-POS, BIND-POS, STORE
	# Just delegate these to @.rows, if possible
	method AT-POS(\position) {
		position >= self.elems and warn "Warning: Accessing element {position} beyond range of rows\n";
		@!rows.AT-POS(position);
	}

	# Associative interface, used for fields
	# 	Must: AT-KEY, EXISTS-KEY
	#	May: DELETE-KEY, ASSIGN-KEY, BIND-KEY, STORE

	# Field (Associative) key locator
	method AT-KEY(\key) is raw {
		Proxy.new(
			FETCH => {
				with %!field-indices.AT-KEY(key) {
					@!fields.AT-POS($_)
				}
				else { Nil }
			},
			STORE => -> $, \value {
#				say "Storing " ~ join('#', key, value);
				with %!field-indices.AT-KEY(key) {
					@!fields.ASSIGN-POS($_, value)
				}
				else {
					my int $index = @!field-names.elems;
					@!field-names.ASSIGN-POS($index, key);
					%!field-indices.BIND-KEY(key, $index);
					@!fields.ASSIGN-POS($index, value);
				}
			}
		)
	}

	method BIND-KEY(\key, \value) is raw {
		with %!field-indices.AT-KEY(key) -> \index {
			@!fields.BIND-POS(index, value)
		}
		else {
			my int $index = @!field-names.elems;
			@!field-names.ASSIGN-POS($index, key);
			%!field-indices.BIND-KEY(key, $index);
			@!fields.BIND-POS($index, value);
		}
	}


	method CLEAR() {
		%!field-indices = @!field-names = @!fields = @!rows = Empty;
	}

	method DELETE-KEY(\key) {
		with %!field-indices.DELETE-KEY(key) -> \index {
			my \value = @!fields[index];

			@!field-names.splice:   index, 1;
			@!fields.splice: index, 1;

			%!field-indices.AT-KEY(@!field-names.AT-POS($_))-- for index .. @!field-names.end;

			value
		}
	}

	method EXISTS-KEY(\key) {
		%!field-indices.EXISTS-KEY(key)
	}

	##### Other methods
	method	fill_from_aoh(@rows) {
		for @rows -> $row {
			@!rows.push: self.makeTuple($row);
		}
	}

	method	add-row(@fields) {
		@!rows.push: self.makeTuple(@fields);
	}
}

# Implements Database::Driver for the Memory type
class	Database::Driver::Memory does Database::Driver {
	my	Database::Driver::Memory	$primary-instance;	# Help implement Singleton
	has	%tables;

	# Singleton pattern (if unnamed; if it's named, then don't Singleton; could in future use a hash and then Singleton everything
	method	new(:$name) {
		if $name {
			nextsame;
		} else {
			$primary-instance or $primary-instance = callsame;
			return $primary-instance;
		}
	}

	method	useTable(Table :$table, *%params) {
		%tables{$table.name} and return %tables{$table.name};

		my Table::Driver::Memory $backend-table = Table::Driver::Memory.new(
			frontend-object => $table,
			|%params
		);

		%tables{$table.name} = $backend-table;

		return $backend-table;
	}
}

