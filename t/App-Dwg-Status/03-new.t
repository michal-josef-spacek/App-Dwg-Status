use strict;
use warnings;

use App::Dwg::Status;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::Dwg::Status->new;
isa_ok($obj, 'App::Dwg::Status');
