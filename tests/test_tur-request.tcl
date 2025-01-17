###############################################################################
# Tests Tur-Request v2.0.0
###############################################################################

package require tcltest
namespace import ::tcltest::*

# Configuration test
set ::turrequest::glroot "tests/glftpd"
set ::turrequest::db_file "tests/tur-request.db"
set ::turrequest::log_file "tests/tur-request.log"

# Chargement fichiers
source "../tur-request.tcl"
source "../tur-request.auth.tcl"
source "../tur-request.pzs.tcl"

###############################################################################
# Tests Base
###############################################################################

test base-1 "Test version" {
    string equal $::turrequest::VERSION "2.0.0"
} 1

test base-2 "Test configuration" {
    expr {
        [info exists ::turrequest::glroot] &&
        [info exists ::turrequest::request_chan] &&
        [info exists ::turrequest::announce_chan]
    }
} 1

test base-3 "Test base de données" {
    file exists $::turrequest::db_file
} 1

###############################################################################
# Tests Requêtes
###############################################################################

test request-1 "Création requête" {
    set id [db eval {
        INSERT INTO requests (title, details, user, created)
        VALUES ('Test Release', 'Test details', 'testuser', [clock seconds])
        RETURNING id
    }]
    expr {$id > 0}
} 1

test request-2 "Lecture requête" {
    set req [db eval {
        SELECT * FROM requests WHERE title = 'Test Release'
    }]
    llength $req
} 9

test request-3 "Mise à jour requête" {
    set count [db eval {
        UPDATE requests 
        SET status = 'filled',
            filler = 'testfiller',
            fill_path = '/test/path'
        WHERE title = 'Test Release'
        RETURNING changes()
    }]
    expr {$count == 1}
} 1

test request-4 "Suppression requête" {
    set count [db eval {
        DELETE FROM requests WHERE title = 'Test Release'
        RETURNING changes()
    }]
    expr {$count == 1}
} 1

###############################################################################
# Tests Points
###############################################################################

test points-1 "Ajout points" {
    ::turrequest::points::add "testuser" 10
} 10

test points-2 "Lecture points" {
    ::turrequest::points::get "testuser"
} 10

test points-3 "Mise à jour points" {
    ::turrequest::points::add "testuser" -5
} 5

###############################################################################
# Tests Auth
###############################################################################

test auth-1 "Chargement configuration glFTPd" {
    ::turrequest::auth::load_glftpd_conf
} 1

test auth-2 "Vérification admin" {
    ::turrequest::admin::is_admin "testadmin"
} 0

test auth-3 "Bannissement" {
    ::turrequest::admin::ban "testban" "testadmin" "Test ban"
} 1

###############################################################################
# Tests pzs-ng
###############################################################################

test pzs-1 "Score match exact" {
    ::turrequest::pzs::match_score "Test.Release-GROUP" "Test Release" ""
} 1.0

test pzs-2 "Score match partiel" {
    ::turrequest::pzs::match_score "Test.Other.Release-GROUP" "Test Release" ""
} 0.6

test pzs-3 "Score no match" {
    ::turrequest::pzs::match_score "Other.Release-GROUP" "Test Release" ""
} 0.0

###############################################################################
# Nettoyage
###############################################################################

# Suppression fichiers test
file delete $::turrequest::db_file
file delete $::turrequest::log_file

# Résumé tests
cleanupTests 