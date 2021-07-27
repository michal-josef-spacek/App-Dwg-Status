use strict;
use warnings;

use App::Dwg::Status;
use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Output;

# Test.
@ARGV = (
	'-h',
);
my $right_ret = <<'END';
Usage: t/App-Dwg-Status/04-run.t [-h] [--version] dwg_file
	-h		Print help.
	--version	Print version.
	dwg_file	AutoCAD DWG file.
END
stderr_is(
	sub {
		App::Dwg::Status->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);
