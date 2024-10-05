use    TOP;

class    TOP::Formatter::HalfHuman {
	has	Table	$!table is built is required;
	has	Str		$.output;
	has	Str		$!sformat;
	has			%!maxes;
	has			%!types is default(Nil);
	has	Str		%!sformatchars = %(
		Str => 's',
		Num => 's',
		Int => 'd',
	);

	method    set-table(Table $table) {
		$!table = $table;
	}

	method    prepare-table() {
		# Calculate field maxes and types
		for $!table[0 ..*] -> $row {
			for $row.kv -> $key, $cell {
				%!maxes{$key} = max(%!maxes{$key}, $cell.chars);
				my $lastone = False; my $thisone = False;
				for Nil, Int, Num, Str -> $type {
					%!types{$key}.WHAT ~~ $type and $lastone = True;
					$cell.WHAT ~~ $type and $thisone = True;
					($lastone and $thisone) or next;
					%!types{$key} = $cell.WHAT;
					last;
				}
			}
		}
		$!sformat = join(' ', $!table.fields.map({ $.sformat-field(.name) })) ~ "\n";
	}

	method	sformat-field($name) {
		return '%' ~ (%!types{$name} ~~ Int ?? '' !! '-') ~ %!maxes{$name} ~ 's';
	}

	method    output-header() {
		# output header(s)
		$.add-row($!table.fields.map({ .name }));
	}

	method    output-row($row) {
		# Output row
		$.add-row($!table.fields.map({ $row{.name} }));
	}

	method    output-footer {
		# Output footer
	}

	method	add-row(@items) {
		$!output ~= sprintf $!sformat, @items;
	}
}