use	TOP;
use	Text::CSV;

class	TOP::Parser::CSV {
	has	Table	$!table is built is required;

	method	TWEAK(Str :$filename, Str :$command, IO::Handle :$handle is copy) {
		$filename and do {
			$handle = $filename.IO.open :r;
		};
		$command and do {
			my @params = split(/\s+/, $command);
			my $proc = run @params, :out;
			$handle = $proc.out;
		};
		my $parser = Text::CSV.new();
		my @headers = $parser.header($handle, munge-column-names => 'none').column-names;
dd @headers;
		for @headers -> $heading {
			$!table.add-field(
				relation => $!table, 
				name => $heading
			);
		}
		my %fields;
		while %fields = %($parser.getline_hr($handle)) {
			$!table.add-row(%fields);
		}
		$handle.close;
	}
}
