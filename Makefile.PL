use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Base class and script for command like AutoCAD status command.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/dwg-status';
license 'bsd';
name 'App-Dwg-Status';
perl_version 5.006;
readme_from 'bin/dwg-status';
recursive_author_tests('xt');
requires 'CAD::AutoCAD::Detect' => 0.02;
requires 'CAD::Format::DWG::AC1_40' => 0;
requires 'CAD::Format::DWG::AC1003' => 0;
requires 'Class::Utils' => 0;
requires 'Error::Pure' => 0;
requires 'File::Spec::Functions' => 0;
requires 'Getopt::Std' => 0;
requires 'Readonly' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-Dwg-Status/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-Dwg-Status';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-Dwg-Status';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'File::Object' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
