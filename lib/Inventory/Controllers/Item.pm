# Abstract: Item Controller for Inventory App
#===============================================================================
#
#         FILE: Inventory/Controllers/Item.pm
#
#  DESCRIPTION:
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Austin Kenny (), aibistin.cionnaith@gmail.com
# ORGANIZATION: Carry On Coding
#      VERSION: 1.0
#      CREATED: 10/21/2013 03:51:18 PM
#     REVISION: ---
#===============================================================================
package Inventory::Controllers::Item;
use Dancer2;

#------ PREFIX for this route.
prefix '/item';

use Template;
use Data::Dump qw/dump/;
use List::Util qw{first};

#---- Caching

use Dancer2::Plugin::Cache::CHI;

#check_page_cache; #-- For caching a page response

#------ Locate my Databse Modules
use FindBin;
my $run_dir       = $FindBin::Bin;
my $INVENTORY_DB  = "$run_dir/../sql/inventory.db";
my $ITEM_CATEGORY = qw{Furniture};

#------ Inventory Db Item Module
use Inventory::Db::Item;

#--- Plain Item Module
use Item::Item;

#------ Debug
use Log::Any::Adapter qw/Stdout/;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

#--- My utility files
use MyUtil qw { camelcase_str  full_chomp is_str_alpha  make_str_alpha };
use MyDateUtil qw { format_yyyy_mm_dd_T_hhmmss  };

#------ GLOBALS
use MyConstant qw/$FAIL $NO  $ONE_TO_500 $FIVE_TO_1000 $TEN_TO_10000  $PI $YES/;

my $DEFAULT_MEASURING_SYS      = 'imperial';
my $DEFAULT_UNITS              = 'in';
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
my $WIDTH_DEFAULT_VALUE        = q{width};
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

#--- templates
my $ADD_ITEM_T   = q/add_item/;
my $VIEW_ITEMS_T = q/view_items/;

#-------------------------------------------------------------------------------
#  Before Hook
#-------------------------------------------------------------------------------
hook before => sub {

    # use vars->{'time'} to access
    #    or var 'time';
    var time => scalar(localtime);
};

#-------------------------------------------------------------------------------
get '/' => sub {
    template 'welcome';
};

#-------------------------------------------------------------------------------
#  Welcome Page
#-------------------------------------------------------------------------------
#get '/welcome' => sub {
#    template 'welcome';
#};

#-------------------------------------------------------------------------------
#  View Items
#-------------------------------------------------------------------------------

=head2  view_items
    Look at all the items in the inventory.
=cut

get '/view_items' => sub {
    debug("\n Inside view_items");

    #------ Connect to Inventory Database
    my $DbItem = Inventory::Db::Item->new( db_name => $INVENTORY_DB );

    my $items = $DbItem->select_all_items();

    #    debug("Got All Items : " . dump $items);

    my %template_vars = (
        item_list                  => $items,
        camelcase_str              => sub { camelcase_str(@_) },
        format_yyyy_mm_dd_T_hhmmss => sub { format_yyyy_mm_dd_T_hhmmss(@_) },
        print_time                 => vars->{'time'}
    );

    $DbItem->safe_disconnect();
    template $VIEW_ITEMS_T, \%template_vars;
};

#-------------------------------------------------------------------------------
#  Add Item To Inventory
#-------------------------------------------------------------------------------

=head2 get add_item
    Submit the form to
    add an item to the inventory.
=cut

get '/add_item' => sub {
    debug("\n Inside add_item");

    #------ Get 'Select' ranges for the input values
    my $item_data_h = get_valid_item_data_h();

    #    debug( 'Got initial data (type))to pop the template: '
    #          . dump( $item_data_h->{type} ) );
    debug( 'Got initial data (length)to pop the template: '
          . dump( $item_data_h->{length} ) );
    my $template_vars_h =
      populate_add_item_template( $item_data_h, { has_errors => $NO } );
    template $ADD_ITEM_T, $template_vars_h;
};

=head2 post add_item
    Add Item to the inventory DB
=cut

post '/add_item' => sub {

    debug("Inside add_item POST:");

    my $validation_h = get_valid_item_data_h();

    #            type     => params->{$TYPE},
    #            location => params->{$LOCATION},
    #            length   => params->{$LENGTH},
    #            width    => params->{$WIDTH},
    #            height   => params->{$HEIGHT},
    #            diameter => params->{$DIAMETER},
    #            weight   => params->{$WEIGHT},
    #------ Add original value as 'value' to the validation hash
    #    @number_for{keys %your_numbers} = values %your_numbers;}
    for my $item_attr ( keys %$validation_h ) {
        $validation_h->{$item_attr}{value} = params->{$item_attr}
          if ( exists params->{$item_attr} );
    }

    #----------Replace this with the above loop
    #------ Validate the User Input
    my $is_valid = validate_item($validation_h);

    if ( !$is_valid ) {
        debug('Input not valid,  resubmit the add_item form!');
        my $template_vars_h = populate_add_item_template($validation_h);
        template $ADD_ITEM_T, $template_vars_h;
    }

    my $DbItem = Inventory::Db::Item->new( db_name => $INVENTORY_DB );

    #---- Create Hash Of Item Table Column Names and Values
    my %item_table_params =
      map { $_ => ( $validation_h->{$_}{value} // undef ) } @item_table_cols;

    my $insert_ok = $DbItem->insert_item_transaction( \%item_table_params );
    debug( 'Returned from Insert item with return code : ' . $insert_ok );
    $DbItem->commit_and_disconnect();

    debug('Item is added to database') if $is_valid;

    #    my $Item = Item::Item->new(
    #        id       => undef,
    #        type     => params->{$TYPE},
    #        location => params->{$LOCATION},
    #        length   => params->{$LENGTH},
    #        width    => params->{$WIDTH},
    #        height   => params->{$HEIGHT},
    #        diameter => params->{$DIAMETER},
    #        weight   => params->{$WEIGHT},
    #
    #        #      color         =>  params->{$COLOR},
    #        measuring_sys => $DEFAULT_MEASURING_SYS,
    #        units         => $DEFAULT_UNITS,
    #
    #        #------ Structure
    #    'frame' =>  => params->{ 'frame' },
    #    'top' =>  => params->{ 'top' },
    #    'surface' =>  => params->{ 'surface' },
    #    'fabric' =>  => params->{ 'fabric' },
    #    'fabric' =>  => params->{ 'fabric' },

    #------ Desc
    #    'antique' =>  => params->{ 'antique' },
    #    'designer' =>  => params->{ 'designer' },
    #    'dis_assembly' =>  => params->{ 'dis_assembly' },
    #    'fragile' =>  => params->{ 'fragile' },
    #    're_assembly' =>  => params->{ 're_assembly' },
    #    'special_handling' =>  => params->{ 'special_handling' },
    #    'description' =>  => params->{ 'description' },
    #    );

    #    debug( "Item is :" . dump $Item );
    #    return dump $Item;
};

#-------------------------------------------------------------------------------
#                    U S E R      S T U F F
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#                   C U S T O M E R    S T U F F
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  Insert To Items
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  Remove From Items
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#                      V A L I D A T I O N
#-------------------------------------------------------------------------------
#---
#------ Get a HashRef of valid value ranges for each item component.
#------ Useful for select Lists and for validation hash.
#---
sub get_valid_item_data_h {

    my $DbItem = Inventory::Db::Item->new( db_name => $INVENTORY_DB );
    my $types = $DbItem->selectall_item_types( { id => 1, name => 1 } );

    #--- Add a Selector Placeholder to beginning of list
    my $type_default = 'Select ' . $TYPE_LABEL;

    my $locations = $DbItem->selectall_locations( { id => 1, name => 1 } );

    #    debug( 'Got Locations from DB: ' . dump $locations );

    $DbItem->safe_disconnect();

    #--- Add a Selector Placeholder to beginning of list
    my $location_default = 'Select ' . $LOCATION_LABEL;

    return (
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
                default_value => $TYPE_DEFAULT_VALUE,
                selection     => $types,
                valid         => $NO,
                value_list    => q/selection_id/,
                message       => 'You need to enter a valid '
                  . $ITEM_CATEGORY
                  . ' type!',
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
                default_value => $LOCATION_DEFAULT_VALUE,
                selection     => $locations,
                valid         => $NO,
                value_list    => q/selection_id/,
                message       => 'You need to enter a valid location!',
            },
            length => {
                label                => $LENGTH_LABEL,
                name                 => $LENGTH,
                required             => $YES,
                group_req            => [q/length width height/],
                selection            => [ (@$ONE_TO_500) ],
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
                selection            => [ (@$ONE_TO_500) ],
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
                selection            => [ (@$ONE_TO_500) ],
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
                selection            => [ (@$FIVE_TO_1000) ],
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
                selection            => [ (@$TEN_TO_10000) ],
                default_select_label => $POUNDS_LABEL,
                default_value        => $WEIGHT_DEFAULT_VALUE,
                valid                => $NO,
                value_range          => [ 0, 1000 ],
                message              => 'You need to enter a valid weight!',
            },
        }
    );
}

#---
#--- Populate add_item template
#---
sub populate_add_item_template {
    my $item_data_h = shift;
    my $status      = shift;

    #    debug( 'Data (type))to populate the template: '
    #          . dump( $item_data_h->{type} ) );
    #    debug( 'Data (length)to populate the template: '
    #          . dump( $item_data_h->{length} ) );

    my @error_messages;
    for my $msg ( keys(%$item_data_h) ) {
        push( @error_messages, $msg ) if ( $msg =~ m/message$/ );
    }

    my %template_vars = (
        error_messages => \@error_messages,

        #--- Function CallBack
        camelcase_str => sub { camelcase_str(@_) },

        #--- Type
        type_label                => $item_data_h->{type}{label},
        type_name                 => $item_data_h->{type}{name},
        type_default_select_label => $item_data_h->{type}{default_select_label},
        type_default_value        => $item_data_h->{type}{default_value},
        type_list                 => $item_data_h->{type}{selection},
        type_default_select_label_attr =>
          $item_data_h->{type}{default_select_label_attr},
        type_bootstrap_field_state =>
          $item_data_h->{type}{type_bootstrap_field_state},

        #--- Location
        location_label => $item_data_h->{location}{label},
        location_name  => $item_data_h->{location}{name},
        location_default_select_label =>
          $item_data_h->{location}{default_select_label},
        location_default_value => $item_data_h->{location}{default_value},
        location_list          => $item_data_h->{location}{selection},
        location_default_select_label_attr =>
          $item_data_h->{location}{default_select_label_attr},
        location_bootstrap_field_state =>
          $item_data_h->{location}{location_bootstrap_field_state},

        #--- Length
        length_label => $item_data_h->{length}{label},
        length_name  => $item_data_h->{length}{name},
        length_default_select_label =>
          $item_data_h->{length}{default_select_label},
        length_default_value => $item_data_h->{length}{default_value},
        length_list          => $item_data_h->{length}{selection},
        lwh_bootstrap_field_state =>
          $item_data_h->{length}{length_bootstrap_field_state},

        #--- Width
        width_label => $item_data_h->{width}{label},
        width_name  => $item_data_h->{width}{name},
        width_default_select_label =>
          $item_data_h->{width}{default_select_label},
        width_default_value => $item_data_h->{width}{default_value},
        width_list          => $item_data_h->{width}{selection},
        lwh_bootstrap_field_state =>
          $item_data_h->{width}{width_bootstrap_field_state},

        #--- Height
        height_label => $item_data_h->{height}{label},
        height_name  => $item_data_h->{height}{name},
        height_default_select_label =>
          $item_data_h->{height}{default_select_label},
        height_default_value => $item_data_h->{height}{default_value},
        height_list          => $item_data_h->{height}{selection},
        lwh_bootstrap_field_state =>
          $item_data_h->{height}{height_bootstrap_field_state},

        #--- Diameter
        diameter_label => $item_data_h->{diameter}{label},
        diameter_name  => $item_data_h->{diameter}{name},
        diameter_default_select_label =>
          $item_data_h->{diameter}{default_select_label},
        diameter_default_value => $item_data_h->{diameter}{default_value},
        diameter_list          => $item_data_h->{diameter}{selection},
        diameter_bootstrap_field_state =>
          $item_data_h->{diameter}{diameter_bootstrap_field_state},

        #--- Weight
        weight_label => $item_data_h->{weight}{label},
        weight_name  => $item_data_h->{weight}{name},
        weight_default_select_label =>
          $item_data_h->{weight}{default_select_label},
        weight_default_value => $item_data_h->{weight}{default_value},
        weight_list          => $item_data_h->{weight}{selection},
        weight_bootstrap_field_state =>
          $item_data_h->{weight}{weight_bootstrap_field_state},
    );

    return \%template_vars;
}

#---
#------ Validate the add_item Input
#------ Pass the HashRef of Input Data
#------ Pass a validation HashRef
#------ Return the Validation Hash with the 'valid' key set to $YES or $NO
#---

sub validate_item {
    my $validation_h = shift;
    my $is_valid     = $YES;

    debug(
        'Partial validation hash inside validation sub for TYPE : ' . dump(
            map {
                $_ . " => "
                  . ( dump( $validation_h->{type}{$_} ) // q{} ) . "\n"
              } (
                qw/label name required group_req
                  default_select_label default_value valid message /
              )
        )
    );
    debug(
        'Partial validation hash inside validation sub for LOCATION : ' . dump(
            map {
                $_ . " => "
                  . ( dump( $validation_h->{location}{$_} ) // q{} ) . "\n"
              } (
                qw/label name required group_req
                  default_select_label default_value valid message value
                  /
              )
        )
    );
    debug(
        'Partial validation hash inside validation sub for DIAMETER : ' . dump(
            map {
                $_ . " => "
                  . ( $validation_h->{diameter}{$_} // q{} ) . "\n"
              } (
                qw/label name required group_req
                  default_select_label default_value valid message value_range/
              )
        )
    );

  VALIDATION_LOOP:
    for my $item_v ( keys(%$validation_h) ) {
        debug( 'Input before chomp : ' . $validation_h->{$item_v}{value} );
        my $input_value =
          lc( full_chomp( $validation_h->{$item_v}{value} ) );

        debug( 'Input after chomp : ' . $input_value );

        #------ Not defined field,  but the field is NOT required.
        (        ( not defined $input_value )
              && ( $validation_h->{$item_v}{required} == $NO ) )
          && do {
            $validation_h->{$item_v}{valid} = $YES;
            next VALIDATION_LOOP;
          };

        #------ Not defined field,  and the field IS required.
        (        ( not defined $input_value )
              && ( $validation_h->{$item_v}{required} == $YES ) )
          && do {
            $validation_h->{$item_v}{valid} = $NO;
            debug('INVALID: Input value not defined!!!');
            $is_valid = $FAIL;
            next VALIDATION_LOOP;
          };

       #------ If Input Value is ==  the "Default Selection Value" (placeholder)
       #       and No Input is OK
        (        ( $input_value eq lc $validation_h->{$item_v}{default_value} )
              && ( $validation_h->{$item_v}{required} == $NO ) )
          && do {
            debug( $input_value . ' is the default value, but thats ok!!!' );
            $validation_h->{$item_v}{valid} = $YES;
            next VALIDATION_LOOP;
          };

        #---If the value can be validated against a list,  and the list name
        #   the criteria is the selection_list 'id'
        if (   ( $validation_h->{$item_v}{value_list} )
            && ( $validation_h->{$item_v}{value_list} eq q/selection_id/) )
        {
            #------ If the selection matches the list of valid values.

            debug(  'Validating '
                  . $input_value
                  . ' against a list of '
                  . $item_v
                  . 's' );
            ( first { $input_value == ( $_->{id} ) }
                @{ $validation_h->{$item_v}{selection} } )
              && do {
                $validation_h->{$item_v}{valid} = $YES;
                next VALIDATION_LOOP;
              };
        }

        #---If the value can be verified as being within a range of
        #   values(inclusive)
        #   the criteria is the selection_list 'id'
        if ( $validation_h->{$item_v}{value_range} ) {
            debug(  'Testing '
                  . $input_value
                  . ' against value range '
                  . dump $validation_h->{$item_v}{value_range} );
            if ( ( $input_value >= $validation_h->{$item_v}{value_range}->[0] )
                && (
                    $input_value <= $validation_h->{$item_v}{value_range}->[1] )
              )
            {

                $validation_h->{$item_v}{valid} = $YES;
                next VALIDATION_LOOP;

            }
        }

        #--- Fall-Through
        $is_valid = $FAIL;
        debug( 'INVALID: Defined but not valid; ' . $item_v . ' value!' );

    }

    return $is_valid;
}

#-------------------------------------------------------------------------------
true;
