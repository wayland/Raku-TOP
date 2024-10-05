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
