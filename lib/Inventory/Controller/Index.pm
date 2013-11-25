# Abstract: Index module for Inventory App Controller
package Inventory::Controller::Index;
use Dancer2;
prefix undef;


get '/' => sub {
    template 'welcome';
};

#-------------------------------------------------------------------------------
true;
