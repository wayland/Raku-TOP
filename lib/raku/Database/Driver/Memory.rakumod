use     Database::Driver;
use     TOP;

class	Table::Driver::Memory does Table::Driver is export {
	# Currently public for access by Database object -- make protected/friend if useful
	has		$.backend is rw;

	# Currently public for access by Field object -- make protected/friend if useful
	has	Tuple	@.rows handles <elems EXISTS-POS DELETE-POS ASSIGN-POS BIND-POS>;

	# Not implemented yet
	# Could be:
	# -	'pragma' (default): Controlled by the strict pragma, as follows:
	#	-	off: extra fields create new columns
	#	-	on (default): extra fields create an error
	# -	'overflow': extra fields get stuck in a JSON hash/object/assoc field; the name of the field is in $!overflow-field-name
	has	Str	$!field-mode = 'lax';
	has	Str	$!overflow-field-name;

	method	exists(Str :$true-error, Str :$false-error) {
		$false-error.defined and die $false-error ~ " in Memory";
		return False;
	}

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

	multi	method	STORE(\values, :$INITIALIZE) {
		for values -> $row {
			@!rows.STORE(self.makeTuple($row), :$INITIALIZE);
		}

		return self;
	}

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

	method gist() {
#		'gist-needs-fixing' ~ '{' ~ self.pairs.map( *.gist).join(", ") ~ '}' ~ ' gnf';
		self.values.map( *.Str ).join(" ") ~ ' .gist-needs-fixing'
	}

	method Str() {
		'Str-needs-fixing' ~ self.pairs.join(" ")
	}

	##### Other methods
	method	fill_from_aoh(@rows) {
		for @rows -> $row {
			@!rows.push: self.makeTuple($row);
		}
	}
}

class	Database::Driver::Memory does Database::Driver {
	my	Database::Driver::Memory	$primary-instance;	# Implement Singleton
	my	%tables;

	# Singleton pattern
	method	new(:$name) {
		say "new DDM";
		if $name {
			say "new DDM 3";
			nextsame;
		} else {
			say "new DDM 4";
			$primary-instance or $primary-instance = callsame;
			say "new DDM 5";
			return $primary-instance;
		}
	}

	method	useTable(Table :$table, *%params) {
		%tables{$table.name} and return %tables{$table.name};

		my Table::Driver::Memory $backend-table = Table::Driver::Memory.new(
			frontend-object => $table,
			|%params
		);
		say "uTM1" ~ $backend-table.raku;

		%tables{$table.name} = $backend-table;

		return $backend-table;
	}
}

