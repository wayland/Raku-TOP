=begin pod

=NAME TOP::Formatter::WithBorders - Format table on CLI to have borders

=AUTHOR Tim Nelson - https://github.com/wayland

=TITLE TOP::Formatter::WithBorders

=SUBTITLE Formatting tables on the CLI to have Unicode borders

=head1 TOP::Formatter::WithBorders

=begin code

class    TOP::Formatter::WithBorders {}

=end code

The class for formatting tables so that they have borders made out of 
characters.  Currently these are the Unicode box-drawing characters, but 
someday ASCII may be added as an option.  

Many of the functions in this class are called by Database::Storage::format()

Parameters that can be passed to Database::Storage (with defaults)

=item1 C<$format => 'WithBorders'>

=item1 C<$show-headers => True>

=item1 C<$outer-line-type => 'Double'> (other options are Light and Heavy)

=item1 C<$inner-line-type => 'Light'> (other options are Double and Heavy)

=end pod


use    TOP;

our $border-db = Database.new(name => 'borderdb');

our	$border-characters-table = $border-db.useTable(
	name => 'boxchars',
	action => 'ensure',
);
$border-characters-table.parse(
        format => 'CSV',
        filename => 'data/BoxDrawingCharacters.csv',
);

class    TOP::Formatter::WithBorders {
	has	Table	$!table is built is required;
	has	Bool	$!show-headers is built = True;
	has	Str		$!outer-line-type is built = 'Double';
	has	Str		$!inner-line-type is built = 'Light';
	has	Str		$.output;
	has	Str		$!sformat;
	has			%!maxes;
	has			%!types is default(Nil);

	method    set-table(Table $table) {
		$!table = $table;
	}

	method    prepare-table() {
		# Calculate field maxes and types
		$!show-headers and do {
			for $!table.fields.map({ .name }) -> $name {
				%!maxes{$name} = $name.chars;
			}
		};
		for $!table[0 ..*] -> $row {
			for $row.kv -> $key, $cell {
				my Str $cellstring = self.get-cell-string($cell);
				%!maxes{$key} = max(%!maxes{$key}, $cellstring.chars);
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
		my $outer-straight = $.get-character();
		my $inner-straight = $.get-character(containment => 'inner');
		$!sformat = "$outer-straight " ~ join(" $inner-straight ", $!table.fields.map({ $.sformat-field(.name) })) ~ " $outer-straight\n";
	}

	# TODO: Replace with JSON or something
	method get-cell-string($cell) {
		my Str $cellstring;
		if $cell ~~ Hash::Ordered {
			$cellstring = $cell.raku;
		} else {
			$cellstring = defined($cell) ?? "$cell" !! '';
		}
		return $cellstring;
	}

	method	sformat-field($name) {
		return '%' ~ (%!types{$name} ~~ Int ?? '' !! '-') ~ %!maxes{$name} ~ 's';
	}

	method    output-header() {
		# output header(s)
		my $straight = $.get-character(shape => 'Straight', position => 'Horizontal');
		my $left     =             $.get-character(shape => 'Corner', position => 'Top-Left' ) ~ $straight;
		my $mid      = $straight ~ $.get-character(shape => 'T'     , position => 'Top'      ) ~ $straight;
		my $right    = $straight ~ $.get-character(shape => 'Corner', position => 'Top-Right');
		$!output ~= $.make-line(
			$left, $mid, $right,
			$!table.fields.map({ $straight x %!maxes{.name} })
		);
		if $!show-headers {
			$.add-row($!table.fields.map({ .name }));
			my $straight = $.get-character(containment => 'inner', shape => 'Straight', position => 'Horizontal');
			my $left     =             $.get-character(                        shape => 'T',     position => 'Left' ) ~ $straight;
			my $mid      = $straight ~ $.get-character(containment => 'inner', shape => 'Cross', position => 'Orthogonal'  ) ~ $straight;
			my $right    = $straight ~ $.get-character(                        shape => 'T',     position => 'Right');
			$!output ~= $.make-line(
				$left, $mid, $right,
				$!table.fields.map({ $straight x %!maxes{.name} })
			);
		}
	}

	method	make-line($left, $mid, $right, @items) {
		return $left ~ join($mid, @items) ~ "$right\n";
	}

	method    output-row($row) {
		# Output row
		$.add-row($!table.fields.map({ $row{.name} }));
	}

	method    output-footer {
		# Output footer
		my $straight = $.get-character(shape => 'Straight', position => 'Horizontal');
		my $left     =             $.get-character(shape => 'Corner', position => 'Bottom-Left' ) ~ $straight;
		my $mid      = $straight ~ $.get-character(shape => 'T'     , position => 'Bottom'      ) ~ $straight;
		my $right    = $straight ~ $.get-character(shape => 'Corner', position => 'Bottom-Right');
		$!output ~= $.make-line(
			$left, $mid, $right,
			$!table.fields.map({ $straight x %!maxes{.name} })
		);
	}

	method	add-row(@items) {
		$!output ~= (@items ==> map({ self.get-cell-string($_) }) ==> sprintf($!sformat));
	}

	# TODO: Figure out how to make this support ASCII box drawing as well
	method	get-character(
		:$containment = 'outer',
		:$shape = 'Straight',
		:$position = 'Vertical',
	) {
		my $primary-weight;
		given $containment {
			when 'outer' {
				$primary-weight = $!outer-line-type;
			}
			when 'inner' {
				$primary-weight = $!inner-line-type;
			}
			default {
				die "Unrecognised line weight";
			}
		}
		my $secondary-weight;
		my $primary-shape;
		given $shape {
			when 'T' {
				$secondary-weight = $!inner-line-type;
				$primary-shape = 'Straight';
			}
			default {
				$secondary-weight = '';
				$primary-shape = '';
			}
		}
		my $characters = $border-characters-table.grep({
			.{'Block Name'} eq 'Box'
			and .{'Primary Weight'} eq $primary-weight
			and .{'Overall Shape'} eq $shape
			and .{'Overall Position'} eq $position
			and .{'Secondary Weight'} eq $secondary-weight
			and .{'Style'} eq 'Solid'
			and .{'Primary Shape'} eq $primary-shape
		});
		my @chars;
		for 0..^$characters.elems -> $rowid { push @chars, $characters[$rowid].<Char> }
		@chars.elems > 1 and warn "Warning: too many characters found: " ~ join(' ',  @chars);
		return @chars;
	}
}
