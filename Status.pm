package App::Dwg::Status;

use strict;
use warnings;

use CAD::AutoCAD::Detect qw(detect_dwg_file);
use CAD::Format::DWG::AC1_40;
use CAD::Format::DWG::AC1003;
use CAD::Format::DWG::AC1009;
use Class::Utils qw(set_params);
use Error::Pure qw(err);
use File::Spec::Functions qw(splitpath);
use Getopt::Std;
use List::Util qw(any);
use Readonly;

Readonly::Scalar our $S => q{ };
Readonly::Scalar our $S2 => q{  };
Readonly::Scalar our $S3 => q{   };
Readonly::Scalar our $S4 => q{    };
Readonly::Hash our %COLORS => (
	1 => 'red',
	2 => 'yellow',
	3 => 'green',
	4 => 'cyan',
	5 => 'blue',
	6 => 'magenta',
	7 => 'white',
);

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
	} elsif ($self->{'_dwg_magic'} eq 'AC1009') {
		$self->_print_ac1009;
	}

	return;
}

sub _print_ac1_40 {
	my $self = shift;

	my $luf = $self->{'_linear_units_format'};
	my $lup = $self->{'_linear_units_precision'};

	my (undef, undef, $dwg_file) = splitpath($self->{'_dwg_file'});

	my @dim_arrow_size;
	if ($self->{'_dim_arrow_size'}) {
		push @dim_arrow_size, 'Dimension arrow size: '.
			sprintf('%10.'.$lup.'f', $self->{'_dim_arrow_size'});
	}

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
		@dim_arrow_size,
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

	# TODO
	my $limits_off = '(Off)';

	my @drawing;
	# XXX Title is common.
	if ($self->{'_drawing_x_first'} != 1e+20 && $self->{'_drawing_x_second'} != 1e+20
		&& $self->{'_drawing_y_first'} != -1e+20 && $self->{'_drawing_y_second'} != -1e+20) {
		push @drawing,
			sprintf('%-20s', 'Drawing uses').
				'X:'.
				sprintf('%10.'.$lup.'f', $self->{'_drawing_x_first'}).
				$S.
				sprintf('%10.'.$lup.'f', $self->{'_drawing_x_second'}),
			sprintf('%-20s', '').
				'Y:'.
				sprintf('%10.'.$lup.'f', $self->{'_drawing_y_first'}).
				$S.
				sprintf('%10.'.$lup.'f', $self->{'_drawing_y_second'});
	} else {
		push @drawing, sprintf('%-20s', 'Drawing uses').'*Nothing*';
	}

	my $current_layer = $self->{'_dwg'}->table_layers->[$self->{'_current_layer'}];
	my $current_linetype = $self->{'_dwg'}->table_linetypes->[$self->{'_current_layer'}];

	my $current_color_print;
	if ($self->{'_current_color'} == 256) {
		$current_color_print = 'BYLAYER';
	} else {
		$current_color_print = $self->{'_current_color'};
	}
	$current_color_print .= ' -- ';
	$current_color_print .= $current_layer->color;
	if (exists $COLORS{$current_layer->color}) {
		$current_color_print .= ' ('.$COLORS{$current_layer->color}.')';
	}

	my $current_linetype_print;
	if ($self->{'_current_linetype'} == 256) {
		$current_linetype_print = 'BYLAYER';
	} else {
		$current_linetype_print = $self->{'_current_linetype'};
	}
	$current_linetype_print .= ' -- ';
	$current_linetype_print .= $current_linetype->linetype_name;

	# TODO
	my $object_snap_modes = 'None';

	my @ret = (
		$S4.$self->{'_entities'}.' entities in '.$dwg_file,
		sprintf('%-20s', 'Limits are').
			'X:'.
			sprintf('%10.'.$lup.'f', $self->{'_limits_x_min'}).
			$S.
			sprintf('%10.'.$lup.'f', $self->{'_limits_x_max'}).
			$S2.$limits_off,
		sprintf('%-20s', '').
			'Y:'.
			sprintf('%10.'.$lup.'f', $self->{'_limits_y_min'}).
			$S.
			sprintf('%10.'.$lup.'f', $self->{'_limits_y_max'}),
		@drawing,
		sprintf('%-20s', 'Display shows').
			'X:'.
			sprintf('%10.'.$lup.'f', $self->{'_display_x_min'}).
			$S.
			sprintf('%10.'.$lup.'f', $self->{'_display_x_max'}),
		sprintf('%-20s', '').
			'Y:'.
			sprintf('%10.'.$lup.'f', $self->{'_display_y_min'}).
			$S.
			sprintf('%10.'.$lup.'f', $self->{'_display_y_max'}),
		sprintf('%-20s', 'Insertion base is').
			'X:'.sprintf('%10.'.$lup.'f', $self->{'_insertion_base_x'}).
			$S3.'Y:'.sprintf('%10.'.$lup.'f', $self->{'_insertion_base_y'}).
			$S3.'Z:'.sprintf('%10.'.$lup.'f', $self->{'_insertion_base_z'}),
		sprintf('%-20s', 'Snap resolution is').
			'X:'.sprintf('%10.'.$lup.'f', $self->{'_snap_resolution_x'}).
			$S3.'Y:'.sprintf('%10.'.$lup.'f', $self->{'_snap_resolution_y'}),
		sprintf('%-20s', 'Grid spacing is').
			'X:'.sprintf('%10.'.$lup.'f', $self->{'_grid_unit_x'}).
			$S3.'Y:'.sprintf('%10.'.$lup.'f', $self->{'_grid_unit_y'}),
		'',
		'Current layer:    '.$self->{'_current_layer'},
		'Current color:    '.$current_color_print,
		'Current linetype: '.$current_linetype_print,
		'Current elevation:'.
			sprintf('%10.'.$lup.'f', $self->{'_elevation'}).
			$S2.'thickness:'.
			sprintf('%10.'.$lup.'f', $self->{'_thickness'}),
		'Axis '.lc($self->{'_axis'}).
			$S2.'Fill '.lc($self->{'_fill'}).
			$S2.'Grid '.lc($self->{'_grid'}).
			$S2.'Ortho '.lc($self->{'_ortho'}).
			$S2.'Qtext '.lc($self->{'_qtext'}).
			$S2.'Snap '.lc($self->{'_snap'}).
			$S2.'Tablet '.lc($self->{'_tablet'}),
		'Object snap modes: '.$object_snap_modes,
	);

	print join "\n", @ret;
	print "\n";

	return;
}

sub _print_ac1009 {
	my $self = shift;

	my $luf = $self->{'_linear_units_format'};
	my $lup = $self->{'_linear_units_precision'};

	my (undef, undef, $dwg_file) = splitpath($self->{'_dwg_file'});

	# TODO
	my $limits_off = '(Off)';

	my @drawing;
	# XXX Title is common.
	if ($self->{'_drawing_x_first'} != 1e+20 && $self->{'_drawing_x_second'} != 1e+20
		&& $self->{'_drawing_y_first'} != -1e+20 && $self->{'_drawing_y_second'} != -1e+20) {
		push @drawing,
			sprintf('%-23s', 'Model space uses').
				'X:'.
				sprintf('%10.'.$lup.'f', $self->{'_drawing_x_first'}).
				$S.
				sprintf('%10.'.$lup.'f', $self->{'_drawing_x_second'}),
			sprintf('%-23s', '').
				'Y:'.
				sprintf('%10.'.$lup.'f', $self->{'_drawing_y_first'}).
				$S.
				sprintf('%10.'.$lup.'f', $self->{'_drawing_y_second'});
	} else {
		push @drawing, sprintf('%-23s', 'Model space uses').'*Nothing*';
	}

	my $current_layer = $self->{'_dwg'}->table_layers->layers->[$self->{'_current_layer'}];
	my $current_linetype = $self->{'_dwg'}->table_linetypes->linetypes->[$self->{'_current_layer'}];

	my $current_color_print;
	if ($self->{'_current_color'} == 256) {
		$current_color_print = 'BYLAYER';
	} else {
		$current_color_print = $self->{'_current_color'};
	}
	$current_color_print .= ' -- ';
	$current_color_print .= $current_layer->color;
	if (exists $COLORS{$current_layer->color}) {
		$current_color_print .= ' ('.$COLORS{$current_layer->color}.')';
	}

	my $current_linetype_print;
	if ($self->{'_current_linetype'} == 32767) {
		$current_linetype_print = 'BYLAYER';
	} else {
		$current_linetype_print = $self->{'_current_linetype'};
	}
	$current_linetype_print .= ' -- ';
	$current_linetype_print .= $current_linetype->linetype_name;

	# TODO
	my $object_snap_modes = 'None';

	my $model = sprintf('%-22s', 'Current space:');
	if ($self->{'_tilemode'}) {
		$model .= 'Model space';
	} else {
		$model .= 'Paper space';
	}

	my @ret = (
		$self->{'_entities'}.' entities in '.$dwg_file,
		sprintf('%-23s', 'Model space limits are').
			'X:'.
			sprintf('%10.'.$lup.'f', $self->{'_limits_x_min'}).
			$S3.'Y:'.
			sprintf('%10.'.$lup.'f', $self->{'_limits_y_min'}).
			$S2.$limits_off,
		sprintf('%-23s', '').
			'X:'.
			sprintf('%10.'.$lup.'f', $self->{'_limits_x_max'}).
			$S3.'Y:'.
			sprintf('%10.'.$lup.'f', $self->{'_limits_y_max'}),
		@drawing,
		sprintf('%-23s', 'Display shows').
			'X:'.
			sprintf('%10.'.$lup.'f', $self->{'_display_x_min'}).
			$S3.'Y:'.
			sprintf('%10.'.$lup.'f', $self->{'_display_y_min'}),
		sprintf('%-23s', '').
			'X:'.
			sprintf('%10.'.$lup.'f', $self->{'_display_x_max'}).
			$S3.'Y:'.
			sprintf('%10.'.$lup.'f', $self->{'_display_y_max'}),
		sprintf('%-23s', 'Insertion base is').
			'X:'.sprintf('%10.'.$lup.'f', $self->{'_insertion_base_x'}).
			$S3.'Y:'.sprintf('%10.'.$lup.'f', $self->{'_insertion_base_y'}).
			$S3.'Z:'.sprintf('%10.'.$lup.'f', $self->{'_insertion_base_z'}),
		sprintf('%-23s', 'Snap resolution is').
			'X:'.sprintf('%10.'.$lup.'f', $self->{'_snap_resolution_x'}).
			$S3.'Y:'.sprintf('%10.'.$lup.'f', $self->{'_snap_resolution_y'}),
		sprintf('%-23s', 'Grid spacing is').
			'X:'.sprintf('%10.'.$lup.'f', $self->{'_grid_unit_x'}).
			$S3.'Y:'.sprintf('%10.'.$lup.'f', $self->{'_grid_unit_y'}),
		'',
		$model,
		sprintf('%-22s', 'Current layer:').$self->{'_current_layer'},
		sprintf('%-22s', 'Current color:').$current_color_print,
		sprintf('%-22s', 'Current linetype:').$current_linetype_print,
		sprintf('%-22s', 'Current elevation:').
			sprintf('%0.'.$lup.'f', $self->{'_elevation'}).
			$S2.'thickness:'.
			sprintf('%10.'.$lup.'f', $self->{'_thickness'}),
		'Axis '.lc($self->{'_axis'}).
			$S2.'Fill '.lc($self->{'_fill'}).
			$S2.'Grid '.lc($self->{'_grid'}).
			$S2.'Ortho '.lc($self->{'_ortho'}).
			$S2.'Qtext '.lc($self->{'_qtext'}).
			$S2.'Snap '.lc($self->{'_snap'}).
			$S2.'Tablet '.lc($self->{'_tablet'}),
		'Object snap modes:   '.$object_snap_modes,
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
			|| $self->{'_dwg_magic'} eq 'AC1003'
			|| $self->{'_dwg_magic'} eq 'AC1009') {

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

	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		$self->{'_dwg'} = CAD::Format::DWG::AC1_40->from_file($self->{'_dwg_file'});
	} elsif ($self->{'_dwg_magic'} eq 'AC1003') {
		$self->{'_dwg'} = CAD::Format::DWG::AC1003->from_file($self->{'_dwg_file'});
	} else {
		$self->{'_dwg'} = CAD::Format::DWG::AC1009->from_file($self->{'_dwg_file'});
	}
	my $h = $self->{'_dwg'}->header;

	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		$self->{'_entities'} = $h->number_of_entities;
	} elsif ($self->{'_dwg_magic'} eq 'AC1003') {
		$self->{'_entities'} = $h->variables->num_entities;
	} elsif ($self->{'_dwg_magic'} eq 'AC1009') {
		if (defined $self->{'_dwg'}->entities->entities->entities) {
			# TODO Extra entities, block entities.
			$self->{'_entities'} = @{$self->{'_dwg'}->entities->entities->entities};
		} else {
			$self->{'_entities'} = 0;
		}
	}

	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		$self->{'_current_layer'} = $h->current_layer;
		$self->{'_current_color'} = $h->current_color;
	} elsif (any { $self->{'_dwg_magic'} eq $_ } qw(AC1003 AC1009)) {
		$self->{'_current_layer'} = $h->variables->current_layer_index;
		$self->{'_current_color'} = $h->variables->current_color;
		$self->{'_current_linetype'} = $h->variables->current_linetype;
	}

	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		$self->{'_dim_arrow_size'} = $h->dim_arrowsize;
	}

	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		$self->{'_snap'} = $h->snap ? 'On' : 'Off';
		$self->{'_snap_resolution'} = $h->snap_resolution;
	} elsif (any { $self->{'_dwg_magic'} eq $_ } qw(AC1003 AC1009)) {
		$self->{'_snap'} = $h->variables->snap ? 'On' : 'Off';
		$self->{'_snap_resolution_x'} = $h->variables->snap_resolution->x;
		$self->{'_snap_resolution_y'} = $h->variables->snap_resolution->y;
	}

	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		$self->{'_axis'} = $h->axis ? 'On' : 'Off';
		$self->{'_axis_value'} = $h->axis_value->x;
	} elsif (any { $self->{'_dwg_magic'} eq $_ } qw(AC1003 AC1009)) {
		$self->{'_axis'} = $h->variables->axis ? 'On' : 'Off';
		$self->{'_axis_value_x'} = $h->variables->axis_value->x;
		$self->{'_axis_value_y'} = $h->variables->axis_value->y;
	}

	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		$self->{'_fill'} = $h->fill ? 'On' : 'Off';
	} elsif (any { $self->{'_dwg_magic'} eq $_ } qw(AC1003 AC1009)) {
		$self->{'_fill'} = $h->variables->fill ? 'On' : 'Off';
	}

	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		$self->{'_grid'} = $h->grid ? 'On' : 'Off';
		$self->{'_grid_unit'} = $h->grid_unit;
	} elsif (any { $self->{'_dwg_magic'} eq $_ } qw(AC1003 AC1009)) {
		$self->{'_grid'} = $h->variables->grid ? 'On' : 'Off';
		$self->{'_grid_unit_x'} = $h->variables->grid_unit->x;
		$self->{'_grid_unit_y'} = $h->variables->grid_unit->y;
	}

	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		$self->{'_ortho'} = $h->ortho ? 'On' : 'Off';
	} elsif (any { $self->{'_dwg_magic'} eq $_ } qw(AC1003 AC1009)) {
		$self->{'_ortho'} = $h->variables->ortho ? 'On' : 'Off';
	}

	if (any { $self->{'_dwg_magic'} eq $_ } qw(AC1003 AC1009)) {
		$self->{'_qtext'} = $h->variables->qtext ? 'On' : 'Off';
	}

	$self->{'_tablet'} = 'Off';

	# TODO Used?
	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		$self->{'_linear_units_format'} = $h->linear_units_format;
		$self->{'_linear_units_precision'} = $h->linear_units_precision;
	} elsif (any { $self->{'_dwg_magic'} eq $_ } qw(AC1003 AC1009)) {
		$self->{'_linear_units_format'} = $h->variables->linear_units_format;
		$self->{'_linear_units_precision'} = $h->variables->linear_units_precision;
	}

	# Limits.
	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		$self->{'_limits_x_min'} = $h->limits_min->x;
		$self->{'_limits_y_min'} = $h->limits_min->y;
		$self->{'_limits_x_max'} = $h->limits_max->x;
		$self->{'_limits_y_max'} = $h->limits_max->y;
	} elsif (any { $self->{'_dwg_magic'} eq $_ } qw(AC1003 AC1009)) {
		$self->{'_limits_x_min'} = $h->variables->limits_min->x;
		$self->{'_limits_y_min'} = $h->variables->limits_min->y;
		$self->{'_limits_x_max'} = $h->variables->limits_max->x;
		$self->{'_limits_y_max'} = $h->variables->limits_max->y;
	}

	# Drawing.
	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		$self->{'_drawing_x_first'} = $h->drawing_first->x;
		$self->{'_drawing_y_first'} = $h->drawing_first->y;
		$self->{'_drawing_x_second'} = $h->drawing_second->x;
		$self->{'_drawing_y_second'} = $h->drawing_second->y;
	} elsif (any { $self->{'_dwg_magic'} eq $_ } qw(AC1003 AC1009)) {
		$self->{'_drawing_x_first'} = $h->variables->drawing_first->x;
		$self->{'_drawing_y_first'} = $h->variables->drawing_first->y;
		$self->{'_drawing_x_second'} = $h->variables->drawing_second->x;
		$self->{'_drawing_y_second'} = $h->variables->drawing_second->y;
	}

	# Display.
	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		my $aspect_ratio = $h->aspect_ratio;
		$self->{'_display_x_min'} = 0;
		$self->{'_display_x_max'} = $h->limits_max->x;
		$self->{'_display_y_min'} = 0;
		$self->{'_display_y_max'} = $h->view_size;
	} elsif (any { $self->{'_dwg_magic'} eq $_ } qw(AC1003 AC1009)) {
		my $aspect_ratio = $h->variables->aspect_ratio;
		$self->{'_display_x_min'} = 0;
		$self->{'_display_x_max'} = ($h->variables->view_size * $aspect_ratio);
		$self->{'_display_y_min'} = 0;
		$self->{'_display_y_max'} = $h->variables->limits_max->y;
	}

	# Insertion base.
	if ($self->{'_dwg_magic'} eq 'AC1.40') {
		$self->{'_insertion_base_x'} = $h->insertion_base->x;
		$self->{'_insertion_base_y'} = $h->insertion_base->y;
	} elsif (any { $self->{'_dwg_magic'} eq $_ } qw(AC1003 AC1009)) {
		$self->{'_insertion_base_x'} = $h->variables->insertion_base->x;
		$self->{'_insertion_base_y'} = $h->variables->insertion_base->y;
		$self->{'_insertion_base_z'} = $h->variables->insertion_base->z;
	}

	if (any { $self->{'_dwg_magic'} eq $_ } qw(AC1003 AC1009)) {
		$self->{'_elevation'} = $h->variables->elevation;
		$self->{'_thickness'} = $h->variables->thickness;
	}

	if ($self->{'_dwg_magic'} eq 'AC1009') {
		$self->{'_tilemode'} = $h->variables->tile_mode;
	}

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
L<List::Util>,
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
