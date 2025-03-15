=begin pod

=NAME TOP::Formatter::HalfHuman - Format table contents to be useful to humans and machines

=AUTHOR Tim Nelson - https://github.com/wayland

=TITLE TOP::Formatter::HalfHuman

=SUBTITLE Formatting tables in a human readable but also machine readable format

=head1 TOP::Formatter::HalfHuman

=begin code

class    TOP::Formatter::HalfHuman {

=end code

The class for formatting the tables in a half-human format.  Half-Human is a 
format Tim Nelson designed.  It's basically the same as the output of many 
Unix/Linux commands, but a little more standardised, so that computers can
process them as easily as humans..  In particular, the rules are:

=item1 All columns are whitespace-separated (standard)

=item1 No columns may have spaces (suggestion: replace with underlines)

=item1 No column be completely blank (suggestion: If there's no value, put a 
dash)

Many of the functions in this class are called by Database::Storage::format()

=end pod

use    TOP;

class    TOP::Formatter::HalfHuman {
	has	Table	$!table is built is required;
	has	Bool	$!show-headers is built = True;
	has	Str		$.output;
	has	Str		$!sformat;
	has			%!maxes;
	has			%!types is default(Nil);

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
		$!show-headers and $.add-row($!table.fields.map({ .name }));
	}

	method    output-row($row) {
		# Output row
		$.add-row($!table.fields.map({ $row{.name} }));
	}

	method    output-footer {
		# Output footer
	}

	method	add-row(@items) {
		$!output ~= (@items ==> map({ .defined ?? $_ !! '' }) ==> sprintf($!sformat));
	}
}

