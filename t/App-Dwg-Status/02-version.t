use strict;
use warnings;

use App::Dwg::Status;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Dwg::Status::VERSION, 0.01, 'Version.');
