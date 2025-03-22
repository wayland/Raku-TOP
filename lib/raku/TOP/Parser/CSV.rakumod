=begin pod

=NAME TOP::Parser::CSV - Parse a table in CSV format

=AUTHOR Tim Nelson - https://github.com/wayland

=TITLE TOP::Parser::CSV

=SUBTITLE Parsing tables in CSV

=head1 TOP::Parser::CSV

=begin code

class   TOP::Parser::CSV {}

=end code

The class for parsing CSVs into a table.  Uses Text::CSV.  

Called by Database::Storage.parse() -- see there for documentation

=end pod


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
