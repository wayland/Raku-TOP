use	TOP;

role	Table::Driver does Associative does Positional {
	has				%.field-indices;	# For looking up fields by name
	has	Str			@!field-names;		# For keeping the fields in order
	has	Field		@.fields;			# Store the actual fields

	# Abstracts
	method fill_from_aoh(@rows) {...}

	# Concretes
	method raku {
		self.^name ~ " \{...\}" ~ ' .raku-needs-fixing';
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
}
role	Database::Driver {}
