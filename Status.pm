package App::Dwg::Status;

use strict;
use warnings;

use CAD::Format::DWG::1_40;
use Class::Utils qw(set_params);
use Data::IEEE754 qw(unpack_double_be);
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

	my $dec = 4;

	my @ret = (
		'  '.$self->{'_entities'}.' entities in '.$self->{'_dwg_file'},
		# TODO Use sprintf to space to X/Y.
		'Limits are:          X:'.sprintf('%10.'.$dec.'f', $self->{'_limits_x_min'}).
			sprintf('%10.'.$dec.'f', $self->{'_limits_x_max'}),
		'                     Y:'.sprintf('%10.'.$dec.'f', $self->{'_limits_y_min'}).
			sprintf('%10.'.$dec.'f', $self->{'_limits_y_max'}),
		'Drawing uses:        X:'.sprintf('%10.'.$dec.'f', $self->{'_drawing_x_min'}).
			sprintf('%10.'.$dec.'f', $self->{'_drawing_x_max'}),
		'                     Y:'.sprintf('%10.'.$dec.'f', $self->{'_drawing_y_min'}).
			sprintf('%10.'.$dec.'f', $self->{'_drawing_y_max'}),
		'Display shows:       X:'.sprintf('%10.'.$dec.'f', $self->{'_display_x_min'}).
			sprintf('%10.'.$dec.'f', $self->{'_display_x_max'}),
		'                     Y:'.sprintf('%10.'.$dec.'f', $self->{'_display_y_min'}).
			sprintf('%10.'.$dec.'f', $self->{'_display_y_max'}),
		'Insertion base is:   X:'.sprintf('%10.'.$dec.'f', $self->{'_insertion_base_x'}),
		'                     Y:'.sprintf('%10.'.$dec.'f', $self->{'_insertion_base_y'}),
		'Snap resolution:'.sprintf('%10.'.$dec.'f', $self->{'_snap_resolution'}).
			'  Grid value:'.sprintf('%10.'.$dec.'f', $self->{'_grid_value'}),
		'Axis value:'.sprintf('%10.'.$dec.'f', $self->{'_axis_value'}),
		'Current layer:   '.$self->{'_current_layer'}.
			'  Current color: '.$self->{'_current_color'},
		'',
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

	$self->{'_current_layer'} = $h->actual_layer;
	$self->{'_current_color'} = $h->actual_color;

	my $rev_snap_resolution = reverse $h->snap_value;
	$self->{'_snap_resolution'} = unpack_double_be($rev_snap_resolution);
	# TODO Get
	$self->{'_grid_value'} = 0.25;

	my $rev_axis_value = reverse $h->axis_value;
	$self->{'_axis_value'} = unpack_double_be($rev_axis_value);

	$self->{'_axis'} = $h->axis ? 'On' : 'Off';
	$self->{'_fill'} = $h->fill ? 'On' : 'Off';
	$self->{'_grid'} = $h->grid ? 'On' : 'Off';
	$self->{'_ortho'} = $h->ortho ? 'On' : 'Off';
	$self->{'_snap'} = $h->snap ? 'On' : 'Off';
	# TODO
	$self->{'_tablet'} = 'Off';

	# Limits.
	# XXX Reversed data in CAD::Format::DWG::1_40?
	my $rev_min_x = reverse $h->limits_min_x;
	my $rev_min_y = reverse $h->limits_min_y;
	my $rev_max_x = reverse $h->limits_max_x;
	my $rev_max_y = reverse $h->limits_max_y;
	$self->{'_limits_x_min'} = unpack_double_be($rev_min_x);
	$self->{'_limits_y_min'} = unpack_double_be($rev_min_y);
	$self->{'_limits_x_max'} = unpack_double_be($rev_max_x);
	$self->{'_limits_y_max'} = unpack_double_be($rev_max_y);

	# Drawing.
	# TODO Get.
	$self->{'_drawing_x_min'} = 2;
	$self->{'_drawing_x_max'} = 5;
	$self->{'_drawing_y_min'} = 2;
	$self->{'_drawing_y_max'} = 5;

	# Display.
	# TODO Get.
	$self->{'_display_x_min'} = 3;
	$self->{'_display_x_max'} = 4;
	$self->{'_display_y_min'} = 3;
	$self->{'_display_y_max'} = 4;

	# Insertion base.
	# TODO Get
	$self->{'_insertion_base_x'} = '0.0000';
	$self->{'_insertion_base_y'} = '0.0000';

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
