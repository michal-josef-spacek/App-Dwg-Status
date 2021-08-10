use strict;
use warnings;

use App::Dwg::Status;
use File::Object;
use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Output;

# Data directory.
my $data_dir = File::Object->new->up->dir('data/AC1003')->set;

# Test.
@ARGV = (
	$data_dir->file('BLANK.DWG')->s,
);
my $right_ret = <<'END';
  0 entities in BLANK.DWG
Limits are:          X:    0.0000   12.0000
                     Y:    0.0000    9.0000
Drawing uses:        X:    0.0000    0.0000
                     Y:    0.0000    0.0000
Display shows:       X:    0.0000    0.0000
                     Y:    0.0000    0.0000
Insertion base is:   X:    0.0000
                     Y:    0.0000
Snap resolution:    1.0000  Grid value:    0.0000
Axis value:    0.0000
Current layer:   1  Current color: 15

Axis: Off   Fill: On   Grid: Off   Ortho: Off   Snap: Off   Tablet: ?
END
stdout_is(
	sub {
		App::Dwg::Status->new->run;
		return;
	},
	$right_ret,
	"Get status of 'BLANK.DWG' file.",
);
