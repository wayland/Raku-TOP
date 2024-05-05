use	TOP;
use	Database::Driver;

class	Database::Driver::CSV does Database::Driver {
	has	Str	$!directoryname is built;
	has	Table	$!frontend-object;

	method	useTable(Table :$table, Str :$filename) {
		$!frontend-object = $table;
		use CSV::Parser;

		my $full_filename = ($!directoryname ?? "$!directoryname/" !! '') ~ $filename;
		my $file_handle = open $full_filename, :r;
		my $parser = CSV::Parser.new(
			:$file_handle,
			:contains_header_row,
		);
		my @rows;
		until $file_handle.eof {
			my %data= %( $parser.get_line() );
			@rows.push(%data);
		}
		say "rows";

		$table.ingest(@rows);
	}
}
