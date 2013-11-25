# Abstract: User Controller for Inventory App
#===============================================================================
#
#         FILE: User/Controller/User.pm
#
#  DESCRIPTION:
#
#       AUTHOR: Austin Kenny (), aibistin.cionnaith@gmail.com
# ORGANIZATION: Carry On Coding
#      VERSION: 1.0
#      CREATED: 11/09/2013
#===============================================================================
package User::Controller::User;
use Dancer2;
use Dancer2::Plugin::Database;

#------ PREFIX for this route.
my $PREFIX = q{/user};
prefix $PREFIX;

use Template;
use Data::Dump qw/dump/;

#------ Locate my Databse Modules
use FindBin;
my $run_dir      = $FindBin::Bin;
my $BASE_DIR     = path("$run_dir/..");
my $INVENTORY_DB = path("$BASE_DIR/db/user.db");

#------ Inventory Db User Module
#use Inventory::Db::User;
use User::Form::SignIn;

#------ Debug
use Log::Any::Adapter qw/Stdout/;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

#--- My utility files
use MyUtil qw { camelcase_str  full_chomp is_str_alpha  make_str_alpha
  validate_secure_password };

#------ GLOBALS
use MyConstant qw/$FAIL $NO $YES/;
my $EMAIL    = q/email/;
my $PASSWORD = q/password/;

#------ TEMPLATE NAMES
my $SIGN_IN_T = q{sign_in};

#-------------------------------------------------------------------------------
# Some Template Toolkit Housekeeping
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Before Route Handler Housekeeping
#-------------------------------------------------------------------------------
hook before => sub {
    debug( 'Session User is: ' . session('user') );
    if ( !session('user') && request->dispatch_path !~ m{^/login} ) {
        forward '/sign_in', { saved_path => request->dispatch_path };
    }
};

#-------------------------------------------------------------------------------
#  Get Sign In Form
#-------------------------------------------------------------------------------

=head2 / 
    Nothing here, go to sign in.
=cut

get '/' => sub {
    forward '/user/sign_in';
};

=head2 get sign_in
    Get the sign_in form.
=cut

get '/sign_in' => sub {
    debug("\n Inside sign_in");
    my $Form = User::Form::SignIn->new();
    debug( 'Blank form params: ' . dump $Form );
    my $template_vars = $Form->create_form_template;
    $template_vars->{path} = params->{'saved_path'};

    template $SIGN_IN_T, $template_vars;
};

=head2 post add_sign_in
    Validate and Sign In User
=cut

post '/sign_in' => sub {

    debug( "Params inside sign_in POST: " . dump(params) );
    my $saved_path = params->{'saved_path'};

    debug( 'Saved path: ' . $saved_path);

    my $Form = validate_form();

    debug(
        'username,  ' . $Form->username . ' and password, ' . $Form->password );
    debug( 'Form validation status after validate_form : ' . $Form->is_valid );

    #----Form has decent looking data. Now see if the username exists and the
    #    and the password is good.
    my $user_record;
    if ( $Form->is_valid ) {
        $user_record = get_user_using_username( $Form->username );

        if ($user_record) {
            verify_credentials( $user_record, $Form );
        }
        else {
            $Form->invalidate_field( 'username',
                'This username does not exist!' );
            debug( 'Hashed password ' . $user_record->[2] );
        }
    }

    #----- Print success page
    if ( $Form->is_valid ) {

        #---- Create Session. re-direct to original path
        session user => $user_record->[0];
        debug( 'Session Data: ' . dump session );
        redirect $saved_path // '/';
        return "Hello " . $user_record->[1];
    }
    else {
        #---- re-submit the form
        my $template_vars = $Form->create_form_template;
        template $SIGN_IN_T, $template_vars;
    }

};

#-------------------------------------------------------------------------------
#------ SUBROUTINES
#-------------------------------------------------------------------------------
sub validate_form {

    my $Form = User::Form::SignIn->new(
        username    => params->{username},
        password    => params->{password},
        remember_me => params->{remember_me},
    );

    debug( "New POST form is : " . dump($Form) );
    $Form->validate();
    debug( "Validated  POST form is : " . dump($Form) );
    return $Form;
}

sub get_user_using_username {
    my $username = shift;

    #--- check username and password against user database
    my $sth =
      database->prepare('select id, name,  password from user where name = ?');
    $sth->execute($username);

    my $user_data_record = $sth->fetchrow_arrayref;

    debug( 'Username and Password from Database: ' . dump($user_data_record) );
    return $user_data_record;
}

sub verify_credentials {
    my $user_record = shift;
    my $Form        = shift;

    #--- Compare password to input password

    $Form->invalidate_field('password')
      unless validate_secure_password(
        {
            hashed_password => $user_record->[2],
            password        => $Form->password,
        }
      );
    debug( 'Form validation status after verify_credentials : '
          . $Form->is_valid );

}

sub get_user_from_session {
    my $user_id  = session('user');
    return unless $user_id;

    #--- check username and password against user database
    my $sth =
      database->prepare('select id, name,  password from user where id = ?');
    $sth->execute($user_id);

    my $user_data_record = $sth->fetchrow_arrayref;

    debug( 'Username and Password from Session ' . dump($user_data_record) );
    return $user_data_record;
}

#sub insert_user_to_database {
#    my $Form = shift;
#
#    #--- Save(temporarily) the uploaded file with its original name
#    my $photo_obj = $Form->photo();
#
#    my $DbUser = Inventory::Db::User->new(
#        db_name                      => $INVENTORY_DB,
#        origin_filepath_abs          => path( $photo_obj->tempname ),
#        destination_base_dir_abs     => $BASE_DIR,
#        destination_type_subdir_name => $IMAGES_DIR,
#        new_filename                 => $photo_obj->filename,
#        dummy_path                   => path( $BASE_DIR . '/' . 'DUMMIES_DOH' ),
#    );
#
#    #--- Insert the new sign_in, then return the new sign_in entry.
#    #----Get the corresponding photos for this sign_in
#    my $new_sign_in_h =
#      $DbUser->insert_and_return_sign_in_details(
#        $Form->get_form_field_values() );
#
#    #--- Insert already committed
#    $DbUser->safe_disconnect();
#
#    return $new_sign_in_h;
#}

#-------------------------------------------------------------------------------
true;
