#-------Main Module
package Inventory;
use Dancer2;
our $VERSION = '0.1';
#-------Controller
use Inventory::Controller::Index;
use Inventory::Controller::Item;
use User::Controller::User;
 

#-------End Main Module
#-------------------------------------------------------------------------------
true;
