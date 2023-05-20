package App::Dwg::Status;

use strict;
use warnings;

use CAD::AutoCAD::Detect qw(detect_dwg_file);
use CAD::Format::DWG::AC1_40;
use CAD::Format::DWG::AC1003;
use Class::Utils qw(set_params);
use Error::Pure qw(err);
use File::Spec::Functions qw(splitpath);
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
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tdwg_file\tAutoCAD DWG file.\n";
		return 1;
	}
	$self->{'_dwg_file'} = shift @ARGV;

	# Process.
	delete $self->{'_dwg_magic'};
	$self->_process;

	# Print out.
	$self->_print;

	return 0;
}

sub _print {
	my $self = shift;

	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		$self->_print_ac1_40;
	} elsif ($self->{'_dwg_magic'} eq 'AC1003') {
		$self->_print_ac1003;
	}

	return;
}

sub _print_ac1_40 {
	my $self = shift;

	my $luf = $self->{'_linear_units_format'};
	my $lup = $self->{'_linear_units_precision'};

	my (undef, undef, $dwg_file) = splitpath($self->{'_dwg_file'});

	my @ret = (
		'  '.$self->{'_entities'}.' entities in '.$dwg_file,
		sprintf('%-21s', 'Limits are:').'X:'.sprintf('%10.'.$lup.'f', $self->{'_limits_x_min'}).
			sprintf('%10.'.$lup.'f', $self->{'_limits_x_max'}),
		sprintf('%-21s', '').'Y:'.sprintf('%10.'.$lup.'f', $self->{'_limits_y_min'}).
			sprintf('%10.'.$lup.'f', $self->{'_limits_y_max'}),
		sprintf('%-21s', 'Drawing uses:').'X:'.sprintf('%10.'.$lup.'f', $self->{'_drawing_x_first'}).
			sprintf('%10.'.$lup.'f', $self->{'_drawing_x_second'}),
		sprintf('%-21s', '').'Y:'.sprintf('%10.'.$lup.'f', $self->{'_drawing_y_first'}).
			sprintf('%10.'.$lup.'f', $self->{'_drawing_y_second'}),
		sprintf('%-21s', 'Display shows:').'X:'.sprintf('%10.'.$lup.'f', $self->{'_display_x_min'}).
			sprintf('%10.'.$lup.'f', $self->{'_display_x_max'}),
		sprintf('%-21s', '').'Y:'.sprintf('%10.'.$lup.'f', $self->{'_display_y_min'}).
			sprintf('%10.'.$lup.'f', $self->{'_display_y_max'}),
		sprintf('%-21s', 'Insertion base is:').'X:'.sprintf('%10.'.$lup.'f', $self->{'_insertion_base_x'}),
		sprintf('%-21s', '').'Y:'.sprintf('%10.'.$lup.'f', $self->{'_insertion_base_y'}),
		'Snap resolution:'.sprintf('%10.'.$lup.'f', $self->{'_snap_resolution'}).
			'  Grid value:'.sprintf('%10.'.$lup.'f', $self->{'_grid_unit'}),
		'Axis value:'.sprintf('%10.'.$lup.'f', $self->{'_axis_value'}),
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

sub _print_ac1003 {
	my $self = shift;

	my $luf = $self->{'_linear_units_format'};
	my $lup = $self->{'_linear_units_precision'};

	my (undef, undef, $dwg_file) = splitpath($self->{'_dwg_file'});

	my @ret = (
		'  '.$self->{'_entities'}.' entities in '.$dwg_file,
		sprintf('%-21s', 'Limits are:').'X:'.sprintf('%10.'.$lup.'f', $self->{'_limits_x_min'}).
			sprintf('%10.'.$lup.'f', $self->{'_limits_x_max'}),
		sprintf('%-21s', '').'Y:'.sprintf('%10.'.$lup.'f', $self->{'_limits_y_min'}).
			sprintf('%10.'.$lup.'f', $self->{'_limits_y_max'}),
		sprintf('%-21s', 'Drawing uses:').'X:'.sprintf('%10.'.$lup.'f', $self->{'_drawing_x_first'}).
			sprintf('%10.'.$lup.'f', $self->{'_drawing_x_second'}),
		sprintf('%-21s', '').'Y:'.sprintf('%10.'.$lup.'f', $self->{'_drawing_y_first'}).
			sprintf('%10.'.$lup.'f', $self->{'_drawing_y_second'}),
		sprintf('%-21s', 'Display shows:').'X:'.sprintf('%10.'.$lup.'f', $self->{'_display_x_min'}).
			sprintf('%10.'.$lup.'f', $self->{'_display_x_max'}),
		sprintf('%-21s', '').'Y:'.sprintf('%10.'.$lup.'f', $self->{'_display_y_min'}).
			sprintf('%10.'.$lup.'f', $self->{'_display_y_max'}),
		sprintf('%-21s', 'Insertion base is:').'X:'.sprintf('%10.'.$lup.'f', $self->{'_insertion_base_x'}),
		sprintf('%-21s', '').'Y:'.sprintf('%10.'.$lup.'f', $self->{'_insertion_base_y'}),
		sprintf('%-21s', 'Snap resolution is:').'X:'.sprintf('%10.'.$lup.'f', $self->{'_snap_resolution_x'}).
			' Y:'.sprintf('%10.'.$lup.'f', $self->{'_snap_resolution_y'}),
		sprintf('%-21s', 'Grid spacing is:').'X:'.sprintf('%10.'.$lup.'f', $self->{'_grid_unit_x'}).
			' Y:'.sprintf('%10.'.$lup.'f', $self->{'_grid_unit_y'}),
		'Current layer:   '.$self->{'_current_layer'},
		'Current color: '.$self->{'_current_color'},
		'Current linetype: '.$self->{'_current_linetype'},
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

	$self->{'_dwg_magic'} = detect_dwg_file($self->{'_dwg_file'});
	if ($self->{'_dwg_magic'}) {
		if ($self->{'_dwg_magic'} eq 'AC1.40'
			|| $self->{'_dwg_magic'} eq 'AC1003') {

			return $self->_process_values;
		} else {
			err 'DWG file with magic string \''.$self->{'_dwg_magic'}.'\' doesn\'t supported.';
		}
	} else {
		err 'File \''.$self->{'_dwg_file'}.'\' isn\'t AutoCAD DWG file.';
	}
}

sub _process_values {
	my $self = shift;

	my $dwg;
	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		$dwg = CAD::Format::DWG::AC1_40->from_file($self->{'_dwg_file'});
	} else {
		$dwg = CAD::Format::DWG::AC1003->from_file($self->{'_dwg_file'});
	}
	my $h = $dwg->header;

	$self->{'_entities'} = $h->number_of_entities;

	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		$self->{'_current_layer'} = $h->actual_layer;
		$self->{'_current_color'} = $h->actual_color;
	} elsif ($self->{'_dwg_magic'} eq 'AC1003') {
		$self->{'_current_layer'} = 'TODO';
		$self->{'_current_color'} = 'TODO';
		$self->{'_current_linetype'} = 'TODO';
	}

	$self->{'_snap'} = $h->snap ? 'On' : 'Off';
	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		$self->{'_snap_resolution'} = $h->snap_resolution;
	} elsif ($self->{'_dwg_magic'} eq 'AC1003') {
		$self->{'_snap_resolution_x'} = $h->snap_resolution_x;
		$self->{'_snap_resolution_y'} = $h->snap_resolution_y;
	}

	$self->{'_axis'} = $h->axis ? 'On' : 'Off';
	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		$self->{'_axis_value'} = $h->axis_value;
	} elsif ($self->{'_dwg_magic'} eq 'AC1003') {
		$self->{'_axis_value_x'} = $h->axis_value_x;
		$self->{'_axis_value_y'} = $h->axis_value_y;
	}

	$self->{'_fill'} = $h->fill ? 'On' : 'Off';

	$self->{'_grid'} = $h->grid ? 'On' : 'Off';
	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		$self->{'_grid_unit'} = $h->grid_unit;
	} elsif ($self->{'_dwg_magic'} eq 'AC1003') {
		$self->{'_grid_unit_x'} = $h->grid_unit_x;
		$self->{'_grid_unit_y'} = $h->grid_unit_y;
	}

	$self->{'_ortho'} = $h->ortho ? 'On' : 'Off';

	$self->{'_tablet'} = '?';

	# TODO Used?
	$self->{'_linear_units_format'} = $h->linear_units_format;
	$self->{'_linear_units_precision'} = $h->linear_units_precision;

	# Limits.
	$self->{'_limits_x_min'} = $h->limits_min_x;
	$self->{'_limits_y_min'} = $h->limits_min_y;
	$self->{'_limits_x_max'} = $h->limits_max_x;
	$self->{'_limits_y_max'} = $h->limits_max_y;

	# Drawing.
	$self->{'_drawing_x_first'} = $h->drawing_first_x;
	$self->{'_drawing_y_first'} = $h->drawing_first_y;
	$self->{'_drawing_x_second'} = $h->drawing_second_x;
	$self->{'_drawing_y_second'} = $h->drawing_second_y;

	# Display.
	# TODO Bad
	$self->{'_display_x_min'} = 0; # $h->display_min_x
	$self->{'_display_x_max'} = 0; # $h->display_min_y
	$self->{'_display_y_min'} = 0; # $h->display_max_x
	$self->{'_display_y_max'} = 0; # $h->display_max_y

	# Insertion base.
	$self->{'_insertion_base_x'} = $h->insertion_base_x;
	$self->{'_insertion_base_y'} = $h->insertion_base_y;

	return;
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

App::Dwg::Status - Base class for dwg-status script.

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

 run():
         DWG file with magic string '%s' doesn't supported.
         File '%s' isn't AutoCAD DWG file.

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

L<CAD::AutoCAD::Detect>,
L<CAD::Format::DWG::AC1_40>,
L<CAD::Format::DWG::AC1003>,
L<Class::Utils>,
L<Error::Pure>,
L<File::Spec::Functions>,
L<Getopt::Std>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Dwg-Status>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
