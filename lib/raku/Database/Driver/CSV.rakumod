use	TOP;
use	Database::Driver;

class	Table::Driver::CSV does Table::Driver is export {
	has 		@!rows;

	submethod	TWEAK(Str :$filename) {
		use CSV::Parser;

		my $full_filename = ($!directoryname ?? "$!directoryname/" !! '') ~ $filename;
		$!frontend-object.name or $!frontend-object.name = $filename.IO.basename;
		my $file_handle = open $full_filename, :r;
		my $parser = CSV::Parser.new(
				:$file_handle,
				:contains_header_row,
				);
		until $file_handle.eof {
			my %data= %( $parser.get_line() );
			@!rows.push(%data);
		}
		say "rows";
	}
	method	exists(Str :$true-error, Str :$false-error) {
		$false-error.defined and die $false-error ~ " in CSV";
		return False;
	}
}

class	Database::Driver::CSV does Database::Driver {
	has	Str		$!directoryname is built;
	has	Database	$!frontend-object;

	method	useTable(Table :$table, Str :$filename) {
		$!frontend-object = $table;
		my $backend-table = Table::Driver::Memory.new(frontend-object => $table, action => 'use', :$filename);

		return $backend-table;
	}
}