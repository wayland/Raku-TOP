use     Database::Storage;
use     TOP;

class	Database::Storage::Memory {...}

=begin pod

=NAME Raku *::Storage::Memory - Raku classes to implement the in-memory table store

=TITLE Raku *::Storage::Memory

=SUBTITLE Raku classes to implement the in-memory table store

=AUTHOR Tim Nelson - https://github.com/wayland

=head1 Table::Storage::Memory

	class	Table::Storage::Memory does Table::Storage {

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
class	Table::Storage::Memory does Table::Storage {
	# Currently public for access by Field object -- make protected/friend if useful
	has	Tuple	@.rows handles <elems EXISTS-POS DELETE-POS ASSIGN-POS BIND-POS>;

	method	new(:$database, *@_, *%_) {
		my $usedb;
		if $database ~~ Database::Storage {
			$usedb = $database;
		} else {
			$usedb = Database::Storage::Memory.new();
		}
		callwith(database => $usedb, |@_, |%_);
	}

	# Doco: Documented in Table::Storage
	# TODO: a) Populate Table::Storage::Memory.database and b) make this check database.tables
	method	raw-exists() {
		return False;
	}

	# Allows people to assign to this table
	multi	method	STORE(\values, :$INITIALIZE) {
		for values -> $row {
			@!rows.STORE(self.makeTuple($row), :$INITIALIZE);
		}

		return self;
	}

	# If we don't have this, we get the error: Method 'of' must be resolved by class Table::Storage::Memory because it exists in multiple roles (Associative, Positional)
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
				# say "Storing " ~ join('#', key, value);
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

	multi method	add-row(@fields) {
		@!rows.push: self.makeTuple(@fields);
	}
	multi method	add-row(%fields) {
		@!rows.push: self.makeTuple(%fields);
	}
}

# Implements Database::Storage for the Memory type
class	Database::Storage::Memory does Database::Storage {
	my	Database::Storage::Memory	$primary-instance;	# Help implement Singleton
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

		my Table::Storage::Memory $storage-table = Table::Storage::Memory.new(
			frontend-object => $table,
			|%params
		);

		%tables{$table.name} = $storage-table;

		return $storage-table;
	}
}

