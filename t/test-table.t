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
use Table;
#------- My Test Utilities
use TestUtil qw/is_any is_attr/;

#------ Defaults
my $DEFAULT_NAME  = 'table';
my $DEFAULT_UNITS = 'metric';

my $DEFAULT_DIAMETER = 36;
my $DEFAULT_WIDTH    = 36;
my $DEFAULT_LENGTH   = 36;
my $DEFAULT_HEIGHT   = 24;
my $DEFAULT_WEIGHT   = 80;
my $DEFAULT_TYPE     = 'dining';

#------ Maps an attribute to its defalut value
my %ATTR_DEFAULTS = (
    name => $DEFAULT_NAME,
    diameter => $DEFAULT_DIAMETER,
    width    => $DEFAULT_WIDTH,
    length   => $DEFAULT_LENGTH,
    height   => $DEFAULT_HEIGHT,
    weight   => $DEFAULT_WEIGHT,
    type     => $DEFAULT_TYPE,
    units => $DEFAULT_UNITS,
);

#-------------------------------------------------------------------------------
#  Test Table
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

my ($test_table);

#   Methods to test
#-------------------------------------------------------------------------------
#  Test Switches
#-------------------------------------------------------------------------------

my $TEST_TABLE = $TRUE;

#-------------------------------------------------------------------------------
#  Test Data
#-------------------------------------------------------------------------------
my $test_tables = [
    {
        color  => 'red',
        height => 10,

        #--- Volume should be height * default l * default w
        #--- 10 * 36 * 36 = 3600
        weight           => 95,
        units            => 'metric',
        table_type       => 'kitchen',
        fragile          => '1',
        dis_assembly     => '1',
        special_handling => '0',
        description      => 'Big and ugly.',
        frame            => 'wood',
        top              => 'wood',
    },
    {
        color  => 'green',
        height => 10,

        #--- Volume should be height * default l * default w
        #--- 10 * 36 * 36 = 3600
        weight           => 95,
        units            => 'imperial',
        table_type       => 'side',
        fragile          => '0',
        dis_assembly     => '1',
        special_handling => '0',
        description      => 'Louis the XIIIIIIII.',
        dis_assembly     => 1,
        frame            => 'brass',
        top              => 'wood',
    },
    {
        name   => 'table',
        color  => 'red',
        width  => '39',
        length => '30',
        height => 80,

        #--- Volume should be height * l * w
        #--- 80 * 30 * 39 = 93600
        weight     => 85,
        units      => 'imperial',
        table_type => 'dining',
        frame      => 'wood',
        top        => 'glass',
    },
    {
        color        => 'red',
        width        => '39',
        length       => '30',
        height       => 80,
        weight       => 85,
        units        => 'imperial',
        table_type   => 'gaming',
        antique      => 1,
        dis_assembly => 1,
        frame        => 'wood',
        top          => 'marble',
    },
];
my $dead_tables = [
    {
        #---- bad name
        name             => 'tbl',
        color            => 'green',
        height           => 10,
        weight           => 95,
        units            => 'metric',
        table_type       => 'kitchen',
        fragile          => '1',
        dis_assembly     => '1',
        special_handling => '0',
        description      => 'Big and ugly.',
        frame            => 'wood',
        top              => 'wood',
    },
    {
        name   => 'table',
        color  => 'green',
        height => 10,
        weight => 95,

        #--- bad units
        units            => 'feets',
        table_type       => 'kitchen',
        fragile          => '1',
        dis_assembly     => '1',
        special_handling => '0',
        description      => 'Big and ugly.',
        frame            => 'wood',
        top              => 'wood',
    },
    {
        name   => 'table',
        color  => 'green',
        height => 10,
        weight => 95,

        #--- Bad type
        table_type       => 'manky',
        fragile          => '1',
        dis_assembly     => '1',
        special_handling => '0',
        description      => 'Big and ugly.',
        frame            => 'wood',
        top              => 'wood',
    },
    {
        name             => 'table',
        color            => 'green',
        height           => 10,
        weight           => 95,
        table_type       => 'end',
        fragile          => '1',
        dis_assembly     => '1',
        special_handling => '0',
        description      => 'Big and ugly.',

        #--- bad frame
        frame => 'wobbly',
        top   => 'wood',
    },
];

#-------------------------------------------------------------------------------
#  Testing
#-------------------------------------------------------------------------------

subtest $test_table => sub {

    plan skip_all => 'Not testing Table now.'
      unless ($TEST_TABLE);

    diag 'Test Circular Table With Diameter Table';
    diag '';

    my $Disk = Table->new(
        name     => 'table',
        color    => 'red',
        height   => 10,
        diameter => 10,
        weight   => 95,
        units    => 'metric'
    );

    is( $Disk->name,   'table', 'Table is correct name.' );
    is( $Disk->color,  'red',   'Table is correct color.' );
    is( $Disk->weight, 95,      'Table is correct weight.' );

    # pi 3.14159 PI r(2) * h (25 * PI * 10)
    is( $Disk->volume, 785.3975, 'Table is correct volume.' );

    #------ Good Tables?
    for my $test_href (@$test_tables) {

        my $Tab = Table->new($test_href);
        isa_ok( $Tab, "Table", 'Table: ' );
        isa_ok( $Tab, "Item",  'Table: ' );

        #------ Test all test Href attribute values
        #       with the created Object values
        for my $attr_name ( keys %$test_href ) {
            #--- Test Object Attr value v Expected Attr Value
            is_attr( $attr_name, $Tab->$attr_name, $test_href->{$attr_name}, \%ATTR_DEFAULTS  );

        }

        if ( $test_href->{width} and $test_href->{length} and $test_href->{height} ) {
            my $vol = $test_href->{width} * $test_href->{length} * $test_href->{height};
            is( $Tab->volume, $vol, 'Table is correct volume: ' . $vol );
        }
        else {
            my $default_vol =
            ( $test_href->{width}  // $DEFAULT_WIDTH ) *
            ( $test_href->{length} // $DEFAULT_LENGTH ) *
            ( $test_href->{height} // $DEFAULT_HEIGHT );
            is( $Tab->volume, $default_vol,
                'Table is DEFAULT volume: ' . $default_vol );
        }

    }

    #--- Bad Tables.
    for my $tab (@$dead_tables) {

        dies_ok( sub { my $Lemon = Table->new($tab) },
            'Cannot fix a bad table :)' );
    }
};

#-------------------------------------------------------------------------------
#  Functions
#-------------------------------------------------------------------------------

#--- tests that the object attr matches either the expected test or
#    the default.
sub is_replaced_in_utilities_module_so_delete_this() {
    my $attr_name       = shift;
    my $got_attr_val    = shift;
    my $expect_attr_val = shift;
    my $message         = shift;

    #--- If the Objects attr matches the Expected  result
    #    or if The Object attr will not match the Default ( bad attr)
    if (   ( $got_attr_val eq $expect_attr_val )
        or ( $got_attr_val ne $ATTR_DEFAULTS{$attr_name} ) )
    {
        $message ||=
            'Attribute '
          . $attr_name
          . ', has correct value : '
          . ( $expect_attr_val // q// );

        is( $got_attr_val, $expect_attr_val, $message );
        return;
    }

    #--- If the Objects attr is not eq the the expected attr, then try the
    #    Default value
    $message ||=
        'Attribute '
      . $attr_name
      . ' matches Default value: '
      . ( $ATTR_DEFAULTS{$attr_name} // q// );

    is( $got_attr_val, $ATTR_DEFAULTS{$attr_name}, $message )

}

#-------------------------------------------------------------------------------
#  Pass actual result,  ArayRef of expected results and test name.
#-------------------------------------------------------------------------------
sub is_any {

    my ( $actual, $expected, $name ) = @_;

    $name ||= '';

    ok( ( any { $_ eq $actual } @$expected ), $name )

      or diag "Received: $actual\nExpected:\n" .

      join "", map { "         $_\n" } @$expected;

}

#-------------------------------------------------------------------------------
#  Temporary end marker
#-------------------------------------------------------------------------------
done_testing();
__END__
