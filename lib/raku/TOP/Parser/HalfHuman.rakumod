=begin pod

=NAME TOP::Parser::HalfHuman

=AUTHOR Tim Nelson - https://github.com/wayland

=TITLE TOP::Parser::HalfHuman

=SUBTITLE Parsing tables in HalfHuman format

=head1 TOP::Parser::HalfHuman

=begin code

class   TOP::Parser::HalfHuman {}

=end code

The class for parsing HalfHuman text (such as many Unix commands).  See 
TOP::Formatter::HalfHuman for details.  

=end pod

use	TOP;

class	TOP::Parser::HalfHuman {
	has	Table	$!table is built is required;

	method	TWEAK(Str :$filename, Str :$command, IO::Handle :$handle is copy) {
		$filename and do {
			$handle = $filename.IO;
		};
		$command and do {
			my @params = split(/\s+/, $command);
			my $proc = run @params, :out;
			$handle = $proc.out;
		};
		for $handle.lines -> $line {
			my @fields = split(/\s+/, $line).map: { << $_ >> };
			$!table.add-row(@fields);
		}
	}
}
