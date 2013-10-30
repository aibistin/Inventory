# Abstract: Form to add item to the database
#===============================================================================
#
#         FILE: Inventory/Form/AddItem.pm
#
#  DESCRIPTION:
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Austin Kenny (), aibistin.cionnaith@gmail.com
# ORGANIZATION: Carry On Coding
#      VERSION: 1.0
#      CREATED: 10/24/2013 08:39:41 PM
#     REVISION: ---
#===============================================================================
package Inventory::Form::AddItem;
use Moo;

#--- With description and structure role.
with( 'Item::Desc', 'Item::Structure' );

use Log::Any qw{$log};

#------ Locate my Types Module
#use FindBin;
#my $run_dir = $FindBin::Bin;
#use lib "$FindBin::Bin/../lib";
#use Cwd qw/realpath/;
#use lib  realpath( "$FindBin::Bin/../lib");

use MyConstant qw/$PI/;
use Types::Standard qw{ Bool Enum Int Maybe Num Str };
use MyTypes
  qw{ Furniture MeasuringUnit MeasuringSys NegativeInt PI PositiveInt PositiveOrZeroInt ZeroInt };

use Carp qw{croak};
use Data::Dump qw/dump/;

#--- utility files
use List::Util qw{first};

#--- My utility files
use MyUtil qw { camelcase_str  full_chomp is_str_alpha  make_str_alpha };

#------ GLOBALS
use MyConstant
  qw/$FAIL $NO  $ONE_TO_500 $FIVE_TO_1000 $TEN_TO_10000 $TRUE $PI $YES/;

#------  Globals
my $METRIC                     = q/metric/;
my $IMPERIAL                   = q/imperial/;
my $DEFAULT_MEASURING_SYS      = $IMPERIAL;
my $DEFAULT_UNIT               = 'inch';
my $ID                         = q{id};
my $ID_DEFAULT_VALUE           = undef;
my $ID_LABEL                   = q{Id};
my $TYPE                       = q{type};
my $TYPE_DEFAULT_VALUE         = 0;
my $TYPE_LABEL                 = q{Item Type};
my $LOCATION                   = q{location};
my $LOCATION_DEFAULT_VALUE     = 0;
my $LOCATION_LABEL             = q{Location};
my $LENGTH                     = q{length};
my $LENGTH_DEFAULT_VALUE       = 0;
my $LENGTH_LABEL               = q{Length};
my $WIDTH                      = q{width};
my $WIDTH_DEFAULT_VALUE        = 0;
my $WIDTH_LABEL                = q{Width};
my $HEIGHT                     = q{height};
my $HEIGHT_DEFAULT_VALUE       = 0;
my $HEIGHT_LABEL               = q{Height};
my $DIAMETER                   = q{diameter};
my $DIAMETER_DEFAULT_VALUE     = 0;
my $DIAMETER_LABEL             = q{Diameter};
my $WEIGHT                     = q{weight};
my $WEIGHT_DEFAULT_VALUE       = 0;
my $WEIGHT_LABEL               = q{Weight};
my $EXTERNAL_REF               = q{external_ref};
my $EXTERNAL_REF_DEFAULT_VALUE = undef;
my $EXTERNAL_REF_LABEL         = q{External Ref};
my $COMMENTS                   = q{comments};
my $COMMENTS_DEFAULT_VALUE     = q{};
my $COMMENTS_LABEL             = q{Additional Info};

my @item_table_cols = (
    $ID,     $TYPE,     $LOCATION, $LENGTH,       $WIDTH,
    $HEIGHT, $DIAMETER, $WEIGHT,   $EXTERNAL_REF, $COMMENTS
);

my $INCHES_LABEL = qw{Inches};
my $POUNDS_LABEL = qw{LB's};

#-------------------------------------------------------------------------------
#                      ATTRIBUTES
#-------------------------------------------------------------------------------

#------ Attributes

#has id => (
#    is  => 'ro',
#    isa => Maybe[PositiveOrZeroInt]
#);

#------ Type
#--- Will use this Furniture type for now
#    Maybe in future I will overide this in sub class to use Database Types
has 'type' => (
    is     => 'ro',
    isa    => Maybe [PositiveOrZeroInt],
    coerce => PositiveOrZeroInt->coercion,
);
my ($extract_int_sub);

has location => (
    is     => 'ro',
    isa    => Maybe [PositiveOrZeroInt],
    coerce => PositiveOrZeroInt->coercion,
    coerce => sub { $extract_int_sub->(shift) },
);

#has color => (
#    is  => 'ro',
#    isa => Str
#);

#------
#------ Dimensions
##------
has height => (
    is     => 'ro',
    isa    => Maybe [PositiveOrZeroInt],
    coerce => PositiveOrZeroInt->coercion,
);
#
has width => (
    is     => 'ro',
    isa    => Maybe [PositiveOrZeroInt],
    coerce => PositiveOrZeroInt->coercion,
);
#
has length => (
    is     => 'ro',
    isa    => Maybe [PositiveOrZeroInt],
    coerce => PositiveOrZeroInt->coercion,
);

has diameter => (
    is     => 'ro',
    isa    => Maybe [PositiveOrZeroInt],
    coerce => PositiveOrZeroInt->coercion,
);
#
##------ Weight
has weight => (
    is     => 'ro',
    isa    => Maybe [PositiveOrZeroInt],
    coerce => PositiveOrZeroInt->coercion,
);

#
#
##------ Measuring Units
#has units => (
#    is      => 'ro',
#    isa     => MeasuringUnit,
#    default => sub { $DEFAULT_UNIT }
#);

#-------------------------------------------------------------------------------
#  For Form Class
#-------------------------------------------------------------------------------
##------ Types
has types => (
    is  => 'ro',
    isa => sub {
        croak("$_[0] is not an ArrayRef!")
          unless ( ref( $_[0] ) eq 'ARRAY' );
    },
    required => 1,
);

##------ Locations
has locations => (
    is  => 'ro',
    isa => sub {
        croak("$_[0] is not an ArrayRef!")
          unless ( ref( $_[0] ) eq 'ARRAY' );
    },
    required => 1,
);

##------ Locations
has form_data => (
    is  => 'rw',
    isa => sub {
        croak("$_[0] is not a HashRef!")
          unless ( ref( $_[0] ) eq 'HASH' );
    },
);

##------ Has the form been submitted
has submitted => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

##------ Is the form valid
has is_valid => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
    writer  => '_set_is_valid',
);

#-------------------------------------------------------------------------------
#  Coersion Subs
#-------------------------------------------------------------------------------
$extract_int_sub = sub {
    my ($int) = $_[0] =~ /(\d+)/;
    $int;
};

#-------------------------------------------------------------------------------
#                      BUILD FORM DATA
#-------------------------------------------------------------------------------
#---
#---

=head2 create_form_data
    Build a data sructure to contain all necessary form data for adding an
    Item to the database.
    'bootstrap_validation_state' : "has_success" "has_warning" "has_success"
=cut

sub BUILD {
    my $self = shift;

 #    my $lists     = shift || croak('create_form_data requires data lists!  ');
 #    my $types     = $lists->{types};
 #    my $locations = $lists->{locations};

    my $types     = $self->types();
    my $locations = $self->locations();

    #--- Add a Selector Placeholder to beginning of list
    my $type_default = 'Select ' . $TYPE_LABEL;

    #--- Add a Selector Placeholder to beginning of list
    my $location_default = 'Select ' . $LOCATION_LABEL;

    $self->form_data(
        {

            #--- Will be an integer
            type => {
                label                => $TYPE_LABEL,
                name                 => $TYPE,
                required             => $YES,
                group_req            => [],
                default_select_label => $type_default,
                default_select_label_attr =>
'selected=\"$type_default\" disabled="disabled" required="required" ',
                default_value            => $TYPE_DEFAULT_VALUE,
                selection_list           => $types,
                valid                    => $NO,
                key_value_selection_list => $TRUE,
                message => 'You need to enter a valid item type!',
            },

            #--- Will be an integer
            location => {
                label                => $LOCATION_LABEL,
                name                 => $LOCATION,
                required             => $YES,
                group_req            => [],
                default_select_label => $location_default,
                default_select_label_attr =>
'selected=\"$location_default\" disabled="disabled" required="required" ',
                default_value            => $LOCATION_DEFAULT_VALUE,
                selection_list           => $locations,
                valid                    => $NO,
                key_value_selection_list => $TRUE,
                message => 'You need to enter a valid location!',
            },
            length => {
                label                => $LENGTH_LABEL,
                name                 => $LENGTH,
                required             => $YES,
                group_req            => [q/length width height/],
                selection_list       => [ (@$ONE_TO_500) ],
                default_select_label => $INCHES_LABEL,
                default_value        => $LENGTH_DEFAULT_VALUE,
                valid                => $NO,
                value_range          => [ 0, 1000 ],
                message              => 'You need to enter a valid length!',
            },
            width => {
                label                => $WIDTH_LABEL,
                name                 => $WIDTH,
                required             => $YES,
                group_req            => [qw/length width height/],
                selection_list       => [ (@$ONE_TO_500) ],
                default_select_label => $INCHES_LABEL,
                default_value        => $WIDTH_DEFAULT_VALUE,
                valid                => $NO,
                value_range          => [ 0, 1000 ],
                message              => 'You need to enter a valid width!',
            },
            height => {
                label                => $HEIGHT_LABEL,
                name                 => $HEIGHT,
                required             => $YES,
                group_req            => [qw/length width height/],
                selection_list       => [ (@$ONE_TO_500) ],
                default_select_label => $INCHES_LABEL,
                default_value        => $HEIGHT_DEFAULT_VALUE,
                valid                => $NO,
                value_range          => [ 0, 1000 ],
                message              => 'You need to enter a valid width!',
                message              => 'You need to enter a valid height!',
            },
            diameter => {
                label                => $DIAMETER_LABEL,
                name                 => $DIAMETER,
                required             => $YES,
                group_req            => [qw/diameter height/],
                selection_list       => [ (@$FIVE_TO_1000) ],
                default_select_label => $INCHES_LABEL,
                default_value        => $DIAMETER_DEFAULT_VALUE,
                valid                => $NO,
                value_range          => [qw/0 1000/],
                message              => 'You need to enter a valid diameter!',
            },
            weight => {
                label                => $WEIGHT_LABEL,
                name                 => $WEIGHT,
                required             => $NO,
                group_req            => [],
                selection_list       => [ (@$TEN_TO_10000) ],
                default_select_label => $POUNDS_LABEL,
                default_value        => $WEIGHT_DEFAULT_VALUE,
                valid                => $NO,
                value_range          => [ 0, 10000 ],
                message              => 'You need to enter a valid weight!',
            },
        }
    );

}

#-------------------------------------------------------------------------------
#        Populate Template
#-------------------------------------------------------------------------------
#---
#---
#--- Create A Template Attributes Hash
#---

=head2 create_form_template
    Create a Template data structure with the form data.
=cut

sub create_form_template {
    my $self      = shift;
    my $form_data = $self->form_data();
    my $form_bootstrap_validation_state = q{};

    my @error_messages;

    #--- Create a list of form_field error messages if the form is invalid
    if ( not $self->is_valid() ) {
        $form_bootstrap_validation_state = 'has-error';
        for my $form_field ( keys(%$form_data) ) {
            if ( $form_data->{$form_field}{valid} ) {
                $form_data->{$form_field}{bootstrap_validation_state} =
                  'has-success';
            }
            else {
                push( @error_messages, $form_data->{$form_field}{message} );
                $form_data->{$form_field}{bootstrap_validation_state} =
                  'has-error';
            }
        }
    }
    return {
        bootstrap_validation_state => $form_bootstrap_validation_state,
        #--- Function CallBack
        camelcase_str  => sub { camelcase_str(@_) },
        is_valid      => $self->is_valid(), 
        error_messages => \@error_messages,
        %$form_data
    };

}

#---
#---
#--- Reurn a list of form keys and values
#---

=head2 get_form_field_values
    Reurns a HahRef of form fields with their values.
=cut

sub get_form_field_values {
    my $self = shift;
    my %fields = map { $_ => $self->{$_} }
      (qw {type location height width length diameter weight});
    return \%fields;
}

#-------------------------------------------------------------------------------
#                      V A L I D A T I O N
#-------------------------------------------------------------------------------

sub validate {
    my $self      = shift;
    my $form_data = $self->form_data();
    $self->_set_is_valid($YES);

    #    $self->validate_type();
    #    $self->validate_location();
    #    $self->validate_length();
    #    $self->validate_width();
    #    $self->validate_height();
    #    $self->validate_diameter();
    #    $self->validate_weight();

  VALIDATION_LOOP:
    for my $item_v ( keys(%$form_data) ) {

        #        my $input_value = $form_data->{$item_v}{value};
        my $input_value = $self->$item_v();
        $log->debug( "Testing $item_v with value : "
              . ( $input_value // q{undefined} ) );

        #------ Not defined field,  but the field is NOT required.
        ( ( not $input_value ) && ( $form_data->{$item_v}{required} == $NO ) )
          && do {
            $form_data->{$item_v}{valid} = $YES;
            next VALIDATION_LOOP;
          };

        #------ Not defined field,  and the field IS required.
        ( ( not $input_value ) && ( $form_data->{$item_v}{required} == $YES ) )
          && do {
            $form_data->{$item_v}{valid} = $NO;
            $self->_set_is_valid($NO);
            $log->debug('INVALID: Input value not defined!!!');
            next VALIDATION_LOOP;
          };

       #------ If Input Value is ==  the "Default Selection Value" (placeholder)
       #       and No Input is OK
        (        ( $input_value eq lc $form_data->{$item_v}{default_value} )
              && ( $form_data->{$item_v}{required} == $NO ) )
          && do {
            $log->debug(
                $input_value . ' is the default value, but thats ok!!!' );
            $form_data->{$item_v}{valid} = $YES;
            next VALIDATION_LOOP;
          };

        #---If the value can be validated against a key => value list
        #                                           'id' is the key

        if ( $form_data->{$item_v}{key_value_selection_list} ) {

            #------ If the selection matches the list of valid values.

            $log->debug( 'Validating '
                  . $input_value
                  . ' against a list of '
                  . $item_v
                  . 's' );
            ( first { $input_value == ( $_->{id} ) }
                @{ $form_data->{$item_v}{selection_list} } )
              && do {
                $form_data->{$item_v}{valid} = $YES;
                next VALIDATION_LOOP;
              };
        }

        #---If the value can be verified as being within a range of
        #   values(inclusive)
        if ( $form_data->{$item_v}{value_range} ) {
            $log->debug( 'Testing '
                  . $input_value
                  . ' against value range '
                  . dump $form_data->{$item_v}{value_range} );
            if (   ( $input_value >= $form_data->{$item_v}{value_range}->[0] )
                && ( $input_value <= $form_data->{$item_v}{value_range}->[1] ) )
            {

                $form_data->{$item_v}{valid} = $YES;
                next VALIDATION_LOOP;

            }
        }

        #--- Fall-Through
        $form_data->{$item_v}{valid} = $NO;
        $self->_set_is_valid($NO);
        $log->debug( 'INVALID: Defined but not valid; ' . $item_v . ' value!' );

    }

}

=head2 validate_type

=cut

#sub validate_type{
#return $FAIL unless $self->type();
#
#};

#------------------------------------------------------------------------------
1;
