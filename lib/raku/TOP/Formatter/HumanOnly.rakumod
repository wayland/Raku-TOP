use    TOP;

#our	$border-characters-table = Table.new(
#);

our %border-characters = %(
	double => %(
		top		=> '═',
		bottom	=> '═',
		left	=> '║',
		right	=> '║',

		top-left		=> '╔',
		top-right		=> '╗',
		bottom-left		=> '╚',
		bottom-right	=> '╝',

		top-T		=> '╦',
		bottom-T	=> '╩',
		left-T		=> '╠',
		right-T		=> '╣',

		mid	=> '╬',
	),
	light => %(
		top		=> '─',
		bottom	=> '─',
		left	=> '│',
		right	=> '│',

		top-left		=> '┌',
		top-right		=> '┐',
		bottom-left		=> '└',
		bottom-right	=> '┘',

		top-T		=> '┬',
		bottom-T	=> '┴',
		left-T		=> '├',
		right-T		=> '┤',

		mid	=> '┼',

	),
	heavy => %(
		top		=> '━',
		bottom	=> '━',
		left	=> '┃',
		right	=> '┃',

		top-left		=> '┏',
		top-right		=> '┓',
		bottom-left		=> '┗',
		bottom-right	=> '┛',

		top-T		=> '┳',
		bottom-T	=> '┻',
		left-T		=> '┣',
		right-T		=> '┫',

		mid	=> '╋',

	),
	join-outer-double-inner-light => %(
		top-T		=> '╤',
		bottom-T	=> '╧',
		left-T		=> '╟',
		right-T		=> '╢',
	),
	join-outer-heavy-inner-light => %(
		top-T		=> '┯',
		bottom-T	=> '┷',
		left-T		=> '┠',
		right-T		=> '┨',
	),
	join-outer-light-inner-heavy => %(
		top-T		=> '┯',
		bottom-T	=> '┷',
		left-T		=> '┠',
		right-T		=> '┨',
	),
);

class    TOP::Formatter::HumanOnly {
	has	Table	$!table is built is required;
	has	Bool	$!show-headers is built = True;
	has	Str		$!outer-line-type is built = 'double';
	has	Str		$!inner-line-type is built = 'light';
	has			%!use-outer;
	has			%!use-inner;
	has			%!use-joins;
	has	Str		$.output;
	has	Str		$!sformat;
	has			%!maxes;
	has			%!types is default(Nil);

	submethod	TWEAK() {
		%!use-outer = %border-characters{$!outer-line-type};
		%!use-inner = %border-characters{$!inner-line-type};
		%!use-joins = %border-characters{"join-outer-{$!outer-line-type}-inner-{$!inner-line-type}"};
	}

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
				%!maxes{$key} = max(%!maxes{$key}, (defined($cell) ?? $cell.chars !! 0));
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
		$!sformat = "%!use-outer<left> " ~ join(" %!use-inner<left> ", $!table.fields.map({ $.sformat-field(.name) })) ~ " %!use-outer<right>\n";
	}

	method	sformat-field($name) {
		return '%' ~ (%!types{$name} ~~ Int ?? '' !! '-') ~ %!maxes{$name} ~ 's';
	}

	method    output-header() {
		# output header(s)
		$!output ~= $.make-line(
			"%!use-outer<top-left>%!use-outer<top>", "%!use-outer<top>%!use-joins<top-T>%!use-outer<top>", "%!use-outer<top>%!use-outer<top-right>",
			$!table.fields.map({ %!use-outer<top> x %!maxes{.name} })
		);
		if $!show-headers {
			$.add-row($!table.fields.map({ .name }));
			$!output ~= $.make-line(
				"%!use-joins<left-T>%!use-inner<top>", "%!use-inner<top>%!use-inner<mid>%!use-inner<top>", "%!use-inner<top>%!use-joins<right-T>",
				$!table.fields.map({ %!use-inner<top> x %!maxes{.name} })
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
		$!output ~= $.make-line(
			"%!use-outer<bottom-left>%!use-outer<bottom>", "%!use-outer<bottom>%!use-joins<bottom-T>%!use-outer<bottom>", "%!use-outer<bottom>%!use-outer<bottom-right>",
			$!table.fields.map({ %!use-outer<bottom> x %!maxes{.name} })
		);
	}

	method	add-row(@items) {
		$!output ~= (@items ==> map({ .defined ?? $_ !! '' }) ==> sprintf($!sformat));
	}
}
