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
Limits are          X:    0.0000    12.0000  (Off)
                    Y:    0.0000     9.0000
Drawing uses        *Nothing*
Display shows       X:    0.0000    14.7563
                    Y:    0.0000     9.0000
Insertion base is   X:    0.0000   Y:    0.0000   Z:    0.0000
Snap resolution is  X:    1.0000   Y:    1.0000
Grid spacing is     X:    0.0000   Y:    0.0000

Current layer:     0
Current color:     BYLAYER -- 7 (white)
Current linetype:  BYLAYER -- CONTINUOUS
Current elevation:    0.0000  thickness:    0.0000
Axis off  Fill on  Grid off  Ortho off  Qtext off  Snap off  Tablet off
Object snap modes: None
END
stdout_is(
	sub {
		App::Dwg::Status->new->run;
		return;
	},
	$right_ret,
	"Get status of 'BLANK.DWG' file.",
);
