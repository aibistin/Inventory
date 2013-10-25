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
use Item;
use MyConstant qw/$EMPTY $EMPTY_STR $FAIL $FALSE $PI $TRUE $YES/;


#-------------------------------------------------------------------------------
#  Test Item
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  Constants
#-------------------------------------------------------------------------------
my $ITEM_TYPE = q{type};
my $ITEM_TYPE_LABEL = q{Item Type};
my $ITEM_LOCATION = q{location};
my $ITEM_LOCATION_LABEL = q{Location};
my $ITEM_LENGTH = q{length};
my $ITEM_LENGTH_LABEL = q{Length};
my $ITEM_WIDTH = q{width};
my $ITEM_WIDTH_LABEL= q{Width};
my $ITEM_HEIGHT = q{height};
my $ITEM_HEIGHT_LABEL = q{Height};
my $ITEM_DIAMETER = q{diameter};
my $ITEM_DIAMETER_LABEL = q{Diameter};
my $ITEM_WEIGHT = q{weight};
my $ITEM_WEIGHT_LABEL = q{Weight};

my @item_types = (
    { id => 1,   name => 'chair' },
    { id => 2,   name => 'table' },
    { id => 3,   name => 'stool' },
    { id => 4,   name => 'piano' },
    { id => 5,   name => 'dresser' },
    { id => 6,   name => 'television' },
    { id => 7,   name => 'armoire' },
    { id => 8,   name => 'bed' },
    { id => 9,   name => 'wall unit' },
    { id => 10,  name => 'curio' }
);

my @locations = (
    { id => 1, name => 'MX0001' },
    { id => 2, name => 'MX0002' },
    { id => 3, name => 'MX0003' },
    { id => 4, name => 'MX0004' },
    { id => 5, name => 'MX0005' },
    { id => 6, name => 'MX00006' }
);

my @lengths = qw(100 200 300 400 500 600 700 800);
my @widths = qw(10 20 30 40 50 60 70 80);
my @heights = qw(15 25 35 45 55 65 75 85);
my @diameters = qw(99 88 77 66 55 44 33 22 11 3);
my @weights = qw(4 8 12 16 20 24 28 32);


# use Smart::Comments -ENV;

#------ Lists
my $UNIT_OF_M_REGEX = qr/(?<unit_of_m>metric|imperial)s?/;

my $L_UNIT_REGEX = qr/(?<l_unit>\d{1,6})/;

#-------------------------------------------------------------------------------
#  Subtype names
#-------------------------------------------------------------------------------

my ($test_item);

#   Methods to test
#-------------------------------------------------------------------------------
#  Test Switches
#-------------------------------------------------------------------------------

my $TEST_ITEM = $TRUE;

#-------------------------------------------------------------------------------
#  Test Data
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  Testing
#-------------------------------------------------------------------------------

subtest $test_item => sub {
    
    plan skip_all => 'Not testing Item now.'
      unless ($TEST_ITEM);

    diag 'Test Item';
    diag '';

    my $Item = Item->new(
        type   => 'chair',
        color  => 'blue',
        height => 30,
        width  => 16,
        length => 30,
        weight => 25,
        units  => 'metric'
    );

    isa_ok( $Item, 'Item', $Item . ' is of type ' . 'Item' );

    is( $Item->color,  'blue', 'Item is correct color.' );
    is( $Item->weight, 25,     'Item is correct weight.' );
    is( $Item->volume, 14400,  'Item is correct volume.' );

    my $Disk = Item->new(
        type     => 'table',
        color    => 'red',
        height   => 10,
        diameter => 10,
        weight   => 95,
        units    => 'metric'
    );

    is( $Disk->type,   'table', 'Item is correct type.' );
    is( $Disk->color,  'red',   'Item is correct color.' );
    is( $Disk->weight, 95,      'Item is correct weight.' );

    # pi 3.14159 PI r(2) * h (25 * PI * 10)
    is( $Disk->volume, 785.3975, 'Item is correct volume.' );

};

#-------------------------------------------------------------------------------
#  Temporary end marker
#-------------------------------------------------------------------------------
done_testing();
__END__
