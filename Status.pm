package App::Dwg::Status;

use strict;
use warnings;

use CAD::Format::DWG::1_40;
use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Getopt::Std;
use Readonly;

Readonly::Scalar our $S3 => q{   };

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process parameters.
	set_params($self, @params);

	# Object.
	return $self;
}

# Run.
sub run {
	my $self = shift;

	# Process arguments.
	$self->{'_opts'} = {
		'h' => 0,
	};
	if (! getopts('h', $self->{'_opts'}) || @ARGV < 1
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-h] [--version] dwg_file\n";
		print STDERR "\t-h\t\tHelp.\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tdwg_file\tAutoCAD DWG file\n";
		return 1;
	}
	$self->{'_dwg_file'} = shift @ARGV;

	# Process.
	$self->_process;

	# Print out.
	$self->_print;

	return 0;
}

sub _print {
	my $self = shift;

	my @ret = (
		'  '.$self->{'_entities'}.' entities in '.$self->{'_dwg_file'},
		'Axis: '.$self->{'_axis'}.$S3.'Fill: '.$self->{'_fill'}.
		$S3.'Grid: '.$self->{'_grid'}.$S3.'Ortho: '.$self->{'_ortho'}.
		$S3.'Snap: '.$self->{'_snap'}.$S3.'Tablet: '.$self->{'_tablet'},
	);

	print join "\n", @ret;
	print "\n";

	return;
}

sub _process {
	my $self = shift;

	my $dwg = CAD::Format::DWG::1_40->from_file($self->{'_dwg_file'});
	my $h = $dwg->header;
	$self->{'_entities'} = $h->number_of_entities;
	$self->{'_axis'} = $h->axis ? 'On' : 'Off';
	$self->{'_fill'} = $h->fill ? 'On' : 'Off';
	$self->{'_grid'} = $h->grid ? 'On' : 'Off';
	$self->{'_ortho'} = $h->ortho ? 'On' : 'Off';
	$self->{'_snap'} = $h->snap ? 'On' : 'off';
	# TODO
	$self->{'_tablet'} = 'Off';

	return;
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

App::Dwg::Status - Base class for cpan-get script.

=head1 SYNOPSIS

 use App::Dwg::Status;

 my $app = App::Dwg::Status->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::Dwg::Status->new;

Constructor.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         Parameter 'lwp_user_agent' must be a LWP::UserAgent instance.

 run():
         Cannot download '%s'.
         Module '%s' doesn't exist.
         Value 'download_uri' doesn't exist.
         Value 'uri' doesn't exist.

=head1 EXAMPLE

 use strict;
 use warnings;

 use App::Dwg::Status;

 # Arguments.
 @ARGV = (
         '-h',
 );

 # Run.
 exit App::Dwg::Status->new->run;

 # Output like:
 # TODO

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Getopt::Std>,
L<IO::Barf>,
L<LWP::UserAgent>
L<Menlo::Index::MetaCPAN>
L<URI::cpan>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Dwg-Status>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
