#!/usr/bin/perl
use Modern::Perl;
use List::Util qw/sum/;
use List::MoreUtils qw/ all any/;
use Scalar::Util qw/reftype blessed/;
use Carp qw /confess/;
use POSIX;
use Test::More;
use Test::Exception;

#--- To Test
use lib '/home/austin/perl/Apps/Estimate/lib';
use Chair;
use TestUtil qw/is_attr/;

#------ Defaults
my $DEFAULT_NAME     = 'chair';
my $DEFAULT_UNITS    = 'metric';
my $DEFAULT_WIDTH    = 18;
my $DEFAULT_LENGTH   = 18;
my $DEFAULT_HEIGHT   = 36;
my $DEFAULT_DIAMETER = 28;
my $DEFAULT_WEIGHT   = 40;
my $DEFAULT_TYPE     = 'standard';

#------ Maps an attribute to its defalut value
my %ATTR_DEFAULTS = (
    name     => $DEFAULT_NAME,
    diameter => $DEFAULT_DIAMETER,
    width    => $DEFAULT_WIDTH,
    length   => $DEFAULT_LENGTH,
    height   => $DEFAULT_HEIGHT,
    weight   => $DEFAULT_WEIGHT,
    type     => $DEFAULT_TYPE,
    units    => $DEFAULT_UNITS,
);

#-------------------------------------------------------------------------------
#  Test Chair
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  Constants
#-------------------------------------------------------------------------------

# use Smart::Comments -ENV;

my $TRUE      = 1;
my $FALSE     = 0;
my $FAIL      = undef;
my $EMPTY_STR = q//;
my $EMPTY     = q/<empty>/;

my $PI = 3.14159;

#------ Lists
my $UNIT_OF_M_REGEX = qr/(?<unit_of_m>metric|imperial)s?/;

my $L_UNIT_REGEX = qr/(?<l_unit>\d{1,6})/;

#-------------------------------------------------------------------------------
#  Subtype names
#-------------------------------------------------------------------------------

my ($test_chair);

#   Methods to test
#-------------------------------------------------------------------------------
#  Test Switches
#-------------------------------------------------------------------------------

my $TEST_CHAIR = $TRUE;

#-------------------------------------------------------------------------------
#  Test Data
#-------------------------------------------------------------------------------
my $test_chairs = [
    {
        color            => 'red',
        height           => 10,
        weight           => 95,
        units            => 'metric',
        chair_type       => 'armchair',
        fragile          => '1',
        dis_assembly     => '0',
        special_handling => '1',
        description      => 'Big and ugly.',
    },
    {
        color            => 'green',
        height           => 10,
        weight           => 95,
        units            => 'imperial',
        chair_type       => 'armchair',
        fragile          => '0',
        dis_assembly     => '1',
        special_handling => '0',
        description      => 'Louis the XIIIIIIII.',
    },
    {
        name       => 'chair',
        color      => 'red',
        width      => '39',
        length     => '30',
        height     => 80,
        weight     => 85,
        units      => 'imperial',
        chair_type => 'club',
        surface    => 'upholstered',
    },
    {
        color      => 'red',
        width      => '39',
        length     => '30',
        height     => 80,
        weight     => 85,
        units      => 'imperial',
        chair_type => 'overstuffed',
        antique    => 1,
    },
];

#-------------------------------------------------------------------------------
#  Testing
#-------------------------------------------------------------------------------

subtest $test_chair => sub {

    plan skip_all => 'Not testing Chair now.'
      unless ($TEST_CHAIR);

    diag 'Test Circular Chair With Diameter Chair';
    diag '';

    my $Disk = Chair->new(
        name     => 'chair',
        color    => 'red',
        height   => 10,
        diameter => 10,
        weight   => 95,
        units    => 'metric'
    );

    is( $Disk->name,   'chair', 'Chair is correct name.' );
    is( $Disk->color,  'red',   'Chair is correct color.' );
    is( $Disk->weight, 95,      'Chair is correct weight.' );

    # pi 3.14159 PI r(2) * h (25 * PI * 10)
    is( $Disk->volume, 785.3975, 'Chair is correct volume.' );

    #------ Chairs
    for my $ch (@$test_chairs) {

        my $Cha = Chair->new($ch);
        isa_ok( $Cha, "Chair", 'Chair: ' );
        isa_ok( $Cha, "Chair", 'Chair: ' );

        #------ Test all test Href attribute values
        #       with the created Object values
        for my $attr_name ( keys %$ch ) {

            #--- Test Object Attr value v Expected Attr Value
            is_attr( $attr_name, $Cha->$attr_name, $ch->{$attr_name},
                \%ATTR_DEFAULTS, $EMPTY_STR );
        }

      #        if ( $ch->{width} and $ch->{length} and $ch->{height} ) {
      #            my $vol = $ch->{width} * $ch->{length} * $ch->{height};
      #            is( $Cha->volume, $vol, 'Chair is correct volume: ' . $vol );
      #        }
      #        else {
      #            my $default_vol =
      #              ( $ch->{width}  // $DEFAULT_WIDTH ) *
      #              ( $ch->{length} // $DEFAULT_LENGTH ) *
      #              ( $ch->{height} // $DEFAULT_HEIGHT );
      #            is( $Cha->volume, $default_vol,
      #                'Chair is DEFAULT volume: ' . $default_vol );
      #        }

=head2
        if ( $ch->{name} ) {
            is( $Cha->name, $ch->{name},
                'Chair is correct name ' . $ch->{name} );
        }
        else {
            is( $Cha->name, $DEFAULT_NAME,
                'Chair has DEFAULT name ' . $DEFAULT_NAME );
        }

        isa_ok( $Cha, 'Chair', $Cha . ' is of type ' . 'Chair' );

        if ( $ch->{color} ) {
            is( $Cha->color, $ch->{color},
                'Chair is correct color: ' . $ch->{color} );
        }
        else {
            is( $Cha->color, undef, 'Chair has no color: ' );
        }

        if ( $ch->{length} ) {
            is( $Cha->length, $ch->{length},
                'Chair is correct length: ' . $ch->{length} );
        }
        else {
            is( $Cha->length, $DEFAULT_LENGTH,
                'Chair is DEFAULT length: ' . $DEFAULT_LENGTH );
        }

        if ( $ch->{height} ) {
            is( $Cha->height, $ch->{height},
                'Chair is correct height: ' . $ch->{height} );
        }
        else {
            is( $Cha->height, $DEFAULT_HEIGHT,
                'Chair is DEFAULT HEIGHT: ' . $DEFAULT_HEIGHT );
        }

        if ( $ch->{width} ) {
            is( $Cha->width, $ch->{width},
                'Chair is correct width: ' . $ch->{width} );
        }
        else {
            is( $Cha->width, $DEFAULT_WIDTH,
                'Chair is DEFAULT  width: ' . $DEFAULT_WIDTH );
        }

        if ( $ch->{weight} ) {
            is( $Cha->weight, $ch->{weight},
                'Chair is correct weight: ' . $ch->{weight} );
        }
        else {
            is( $Cha->weight, $DEFAULT_WEIGHT,
                'Chair is DEFAULT weight: ' . $DEFAULT_WEIGHT );
        }

        if ( $ch->{width} and $ch->{length} and $ch->{height} ) {
            my $vol = $ch->{width} * $ch->{length} * $ch->{height};
            is( $Cha->volume, $vol, 'Chair is correct volume: ' . $vol );
        }
        else {
            my $default_vol =
              ( $ch->{width}  // $DEFAULT_WIDTH ) *
              ( $ch->{length} // $DEFAULT_LENGTH ) *
              ( $ch->{height} // $DEFAULT_HEIGHT );
            is( $Cha->volume, $default_vol,
                'Chair is DEFAULT volume: ' . $default_vol );
        }

        if ( $ch->{units} ) {
            is( $Cha->units, $ch->{units},
                'Chair is correct units: ' . $ch->{units} );
        }
        else {
            is( $Cha->units, $DEFAULT_UNITS,
                'Chair has default ' . $DEFAULT_UNITS . '  units ' );
        }

        if ( $ch->{chair_type} ) {
            is( $Cha->chair_type, $ch->{chair_type},
                'Chair is correct chair_type ' . $ch->{chair_type} );
        }
        else {
            is( $Cha->chair_type, $DEFAULT_TYPE,
                'Chair has DEFAULT type ' . $DEFAULT_TYPE . '  type ' );
        }

        #------ DESCRIPTIONS FROM DESC Role
        diag 'Chair Descriptions';

        if ( $ch->{fragile} ) {
            is( $Cha->fragile, $ch->{fragile},
                'Chair is fragile: ' . $ch->{fragile} );
        }
        else {
            is( $Cha->fragile, 0, 'Chair has default fragile of: ' . 0 );
        }

        if ( $ch->{antique} ) {
            is( $Cha->antique, $ch->{antique},
                'Chair is antique: ' . $ch->{antique} );
        }
        else {
            is( $Cha->antique, 0, 'Chair has default antique of: ' . 0 );
        }

        if ( $ch->{designer} ) {
            is( $Cha->designer, $ch->{designer},
                'Chair is designer' . $ch->{designer} );
        }
        else {
            is( $Cha->designer, 0, 'Chair has default designer of: ' . 0 );
        }

        if ( $ch->{upholsterd} ) {
            is( $Cha->upholsterd, $ch->{upholsterd},
                'Chair is upholsterd: ' . $ch->{upholsterd} );
        }
        else {
            is( $Cha->upholsterd, 0, 'Chair has default upholsterd of: ' . 0 );
        }

        if ( $ch->{special_handling} ) {
            is(
                $Cha->special_handling,
                $ch->{special_handling},
                'Chair has special_handling: ' . $ch->{special_handling}
            );
        }
        else {
            is( $Cha->special_handling, 0,
                'Chair has default special_handling of: ' . 0 );
        }

        if ( $ch->{description} ) {
            is( $Cha->description, $ch->{description},
                'Chair has description: ' . $ch->{description} );
        }
        else {
            is( $Cha->description, undef,
                'Chair has default description of: ' . q// );
        }

        #------ STRUCTURE OF TABLE FROM DESC Role
        diag 'Chair Structure';

        if ( $ch->{frame} ) {
            is( $Cha->frame, $ch->{frame},
                'Chair has frame ' . $ch->{frame} );
        }
        else {
            is( $Cha->frame, undef,
                'Chair has default frame of: ' . q// );
        }

        if ( $ch->{top} ) {
            is( $Cha->top, $ch->{top},
                'Chair has top ' . $ch->{top} );
        }
        else {
            is( $Cha->top, undef,
                'Chair has default top of: ' . q// );
        }


        if ( $ch->{surface} ) {
            is( $Cha->surface, $ch->{surface},
                'Chair has surface ' . $ch->{surface} );
        }
        else {
            is( $Cha->surface, undef,
                'Chair has default surface of: ' . q// );
        }
=cut

    }
};

#-------------------------------------------------------------------------------
#  Temporary end marker
#-------------------------------------------------------------------------------
done_testing();
__END__
