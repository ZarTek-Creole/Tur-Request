###############################################################################
# Tests Tur-Request v2.0.0
###############################################################################

package require tcltest

# Simulation environnement Eggdrop
namespace eval eggdrop {
    # Variables simulées
    variable botnick "TurBot"
    variable channels
    array set channels {
        "#requests" 1
    }
    
    # Commandes simulées
    proc putserv {text} {
        # Log message pour vérification
        lappend ::test_output $text
    }
    
    proc putlog {text} {
        # Log message pour vérification
        lappend ::test_output $text
    }
    
    proc channel {cmd chan args} {
        return 1
    }
    
    proc getuser {user flag} {
        switch -- $flag {
            "XTRA" {
                # Simuler groupes admin
                if {$user eq "admin"} {
                    return "siteop"
                }
                return ""
            }
            default {
                return ""
            }
        }
    }
}

# Simulation environnement glFTPd
namespace eval glftpd {
    # Variables simulées
    variable users
    array set users {
        "test1" {
            "group" "users"
            "flags" "3"
            "credits" 1000
            "ratio" "2.5"
        }
        "admin" {
            "group" "siteop"
            "flags" "1234"
            "credits" 10000
            "ratio" "5.0" 
        }
    }
    
    # Commandes simulées
    proc user_exists {user} {
        return [info exists ::glftpd::users($user)]
    }
    
    proc get_user_info {user} {
        if {![user_exists $user]} {
            return {}
        }
        return $::glftpd::users($user)
    }
}

# Configuration test
namespace eval ::turrequest {
    variable VERSION "2.0.0"
    variable request_chan "#requests"
    variable db_file ":memory:"
    variable admin_groups "siteop"
}

# Variables test
variable test_output {}

# Tests unitaires
namespace eval ::tcltest::test {

    # Test 1: Initialisation base de données
    test init-db {Test création tables} {
        source "../tur-request.db.tcl"
        set tables [db eval {
            SELECT name FROM sqlite_master 
            WHERE type='table'
        }]
        expr {[lsearch $tables "requests"] >= 0}
    } 1

    # Test 2: Création requête
    test create-request {Test création requête valide} {
        ::turrequest::cmd::request "test1" "host" "handle" "#requests" "new Test.Release.2024"
        set count [db eval {
            SELECT COUNT(*) FROM requests 
            WHERE user = 'test1'
            AND request = 'Test.Release.2024'
        }]
        set count
    } 1

    # Test 3: Vérification admin
    test check-admin {Test vérification statut admin} {
        ::turrequest::admin::is_admin "admin"
    } 1

    # Test 4: Points système
    test points-system {Test système de points} {
        ::turrequest::points::add "test1" 10
        set points [::turrequest::points::get "test1"]
        expr {$points == 10}
    } 1

    # Test 5: Métriques monitoring
    test monitoring {Test collecte métriques} {
        source "../tur-request.monitor.tcl"
        ::turrequest::monitor::collect_metrics
        set metrics [::turrequest::monitor::get_metrics "requests"]
        expr {[dict exists $metrics "active"]}
    } 1

    # Test 6: Cache système
    test cache-system {Test système cache} {
        source "../tur-request.utils.tcl"
        set size [::turrequest::utils::get_cache_size]
        expr {[string is integer $size]}
    } 1

    # Test 7: Formatage
    test formatting {Test fonctions formatage} {
        set size [::turrequest::utils::format_size 1048576]
        set duration [::turrequest::utils::format_duration 3665]
        expr {$size eq "1.0MB" && $duration eq "1h 1m"}
    } 1

    # Test 8: Commandes IRC
    test irc-commands {Test commandes IRC} {
        set ::test_output {}
        ::turrequest::cmd::reqstats "admin" "host" "handle" "#requests" ""
        expr {[llength $::test_output] > 0}
    } 1

    # Test 9: Nettoyage
    test cleanup {Test nettoyage requêtes} {
        set count [::turrequest::admin::clean]
        expr {[string is integer $count]}
    } 1

    # Test 10: Bannissement
    test ban-system {Test système bannissement} {
        ::turrequest::admin::ban "test1" "admin" "Test ban"
        set banned [db eval {
            SELECT COUNT(*) FROM bans 
            WHERE user = 'test1'
        }]
        expr {$banned == 1}
    } 1

    # Test 11: Validation requête invalide
    test invalid-request {Test requête avec caractères invalides} {
        set ::test_output {}
        ::turrequest::cmd::request "test1" "host" "handle" "#requests" "new Test/Invalid*Chars"
        expr {[lsearch $::test_output "*Erreur*"] >= 0}
    } 1

    # Test 12: Limite requêtes
    test request-limit {Test limite nombre requêtes} {
        set ::turrequest::max_requests 2
        
        # Créer 3 requêtes
        ::turrequest::cmd::request "test1" "host" "handle" "#requests" "new Test1"
        ::turrequest::cmd::request "test1" "host" "handle" "#requests" "new Test2"
        set ::test_output {}
        ::turrequest::cmd::request "test1" "host" "handle" "#requests" "new Test3"
        
        expr {[lsearch $::test_output "*limite*"] >= 0}
    } 1

    # Test 13: Points insuffisants
    test insufficient-points {Test points insuffisants} {
        set ::turrequest::min_points 100
        ::turrequest::points::add "test1" -1000
        
        set ::test_output {}
        ::turrequest::cmd::request "test1" "host" "handle" "#requests" "new Test"
        expr {[lsearch $::test_output "*points insuffisants*"] >= 0}
    } 1

    # Test 14: Remplissage requête
    test fill-request {Test remplissage requête} {
        # Créer une requête
        ::turrequest::cmd::request "test1" "host" "handle" "#requests" "new TestFill"
        set id [db eval {SELECT id FROM requests WHERE request = 'TestFill'}]
        
        # Remplir la requête
        ::turrequest::cmd::fill "admin" "host" "handle" "#requests" "fill $id /path/to/release"
        
        set status [db eval {SELECT status FROM requests WHERE id = $id}]
        expr {$status eq "filled"}
    } 1

    # Test 15: Recherche requêtes
    test search-requests {Test recherche requêtes} {
        # Créer quelques requêtes
        ::turrequest::cmd::request "test1" "host" "handle" "#requests" "new SearchTest1"
        ::turrequest::cmd::request "test1" "host" "handle" "#requests" "new SearchTest2"
        
        set ::test_output {}
        ::turrequest::cmd::search "test1" "host" "handle" "#requests" "search Test"
        expr {[llength $::test_output] >= 2}
    } 1

    # Test 16: Annulation requête
    test cancel-request {Test annulation requête} {
        # Créer une requête
        ::turrequest::cmd::request "test1" "host" "handle" "#requests" "new CancelTest"
        set id [db eval {SELECT id FROM requests WHERE request = 'CancelTest'}]
        
        # Annuler la requête
        ::turrequest::cmd::request "test1" "host" "handle" "#requests" "cancel $id"
        
        set status [db eval {SELECT status FROM requests WHERE id = $id}]
        expr {$status eq "canceled"}
    } 1

    # Test 17: Formatage durées spéciales
    test special-durations {Test formatage durées spéciales} {
        set cases {
            0 "0m"
            59 "0m"
            60 "1m"
            3600 "1h 0m"
            86400 "1d 0h 0m"
            90000 "1d 1h 0m"
        }
        
        set success 1
        foreach {seconds expected} $cases {
            set result [::turrequest::utils::format_duration $seconds]
            if {$result ne $expected} {
                set success 0
                break
            }
        }
        set success
    } 1

    # Test 18: Formatage tailles spéciales
    test special-sizes {Test formatage tailles spéciales} {
        set cases {
            0 "0.0B"
            1023 "1023.0B"
            1024 "1.0KB"
            1048576 "1.0MB"
            1073741824 "1.0GB"
        }
        
        set success 1
        foreach {bytes expected} $cases {
            set result [::turrequest::utils::format_size $bytes]
            if {$result ne $expected} {
                set success 0
                break
            }
        }
        set success
    } 1

    # Test 19: Métriques système
    test system-metrics {Test métriques système} {
        set metrics [::turrequest::monitor::get_metrics "system"]
        expr {
            [dict exists $metrics "cpu"] &&
            [dict exists $metrics "memory"] &&
            [dict exists $metrics "disk"] &&
            [dict exists $metrics "uptime"]
        }
    } 1

    # Test 20: Alertes système
    test system-alerts {Test système alertes} {
        # Simuler une utilisation CPU élevée
        proc ::turrequest::utils::get_cpu_usage {} {
            return 95
        }
        
        ::turrequest::monitor::check_alerts
        set alerts [::turrequest::monitor::get_alerts]
        
        expr {[dict exists $alerts "cpu"]}
    } 1

    # Test 21: Concurrence requêtes
    test concurrent-requests {Test requêtes simultanées} {
        set success 1
        
        # Simuler requêtes simultanées
        set results [list]
        for {set i 0} {$i < 10} {incr i} {
            lappend results [list]
            after 0 [list ::turrequest::cmd::request "test1" "host" "handle" "#requests" "new Concurrent$i"]
        }
        
        # Vérifier résultats
        after 1000 {
            set count [db eval {
                SELECT COUNT(DISTINCT id) FROM requests 
                WHERE request LIKE 'Concurrent%'
            }]
            set success [expr {$count == 10}]
        }
        
        set success
    } 1

    # Test 22: Récupération après erreur DB
    test db-recovery {Test récupération après erreur DB} {
        # Simuler erreur DB
        rename sqlite3_exec sqlite3_exec_orig
        proc sqlite3_exec {args} {
            rename sqlite3_exec {}
            rename sqlite3_exec_orig sqlite3_exec
            error "SQLITE_BUSY"
        }
        
        set ::test_output {}
        ::turrequest::cmd::request "test1" "host" "handle" "#requests" "new RecoveryTest"
        
        expr {[lsearch $::test_output "*réessayer*"] >= 0}
    } 1

    # Test 23: Performance cache
    test cache-performance {Test performance cache} {
        # Remplir cache
        for {set i 0} {$i < 1000} {incr i} {
            ::turrequest::cache::set "key$i" "value$i"
        }
        
        # Mesurer temps accès
        set start [clock microseconds]
        set value [::turrequest::cache::get "key500"]
        set end [clock microseconds]
        
        expr {$end - $start < 1000} ;# moins de 1ms
    } 1

    # Test 24: Nettoyage mémoire
    test memory-cleanup {Test nettoyage mémoire} {
        # Remplir cache avec données temporaires
        for {set i 0} {$i < 1000} {incr i} {
            ::turrequest::cache::set "temp$i" "data$i"
        }
        
        # Forcer nettoyage
        ::turrequest::cache::cleanup
        
        # Vérifier taille
        set size [array size ::turrequest::cache::data]
        expr {$size < 1000}
    } 1

    # Test 25: Validation entrées complexes
    test complex-input {Test validation entrées complexes} {
        set cases {
            "Test.Release.2024-GROUP" 1
            "Test Release" 0
            "Test/Release" 0
            "Test\\Release" 0
            "Test..Release" 0
            "Test.Release." 0
            ".Test.Release" 0
            "Test.Release.2024.PROPER-GROUP" 1
            "Test.Release.2024.REPACK-GROUP" 1
        }
        
        set success 1
        foreach {input expected} $cases {
            set result [::turrequest::validate::release_name $input]
            if {$result != $expected} {
                set success 0
                break
            }
        }
        set success
    } 1

    # Test 26: Gestion timeout
    test timeout-handling {Test gestion timeout} {
        # Simuler opération longue
        proc ::turrequest::slow_operation {} {
            after 2000
            return "done"
        }
        
        set ::test_output {}
        set result [::turrequest::utils::with_timeout 1000 {
            ::turrequest::slow_operation
        }]
        
        expr {$result eq "timeout"}
    } 1

    # Test 27: Historique métriques
    test metrics-history {Test historique métriques} {
        # Générer données historiques
        for {set i 0} {$i < 10} {incr i} {
            ::turrequest::monitor::collect_metrics
            after 100
        }
        
        set history [::turrequest::monitor::get_history "system" 60 0]
        expr {[llength $history] >= 5}
    } 1

    # Test 28: Export Prometheus
    test prometheus-export {Test export Prometheus} {
        set metrics [::turrequest::monitor::export_prometheus]
        
        expr {
            [regexp {turrequest_system_cpu \d+} $metrics] &&
            [regexp {turrequest_requests_total \d+} $metrics]
        }
    } 1

    # Test 29: Rate limiting
    test rate-limiting {Test limitation requêtes} {
        # Configuration rate limit
        set ::turrequest::rate_limit(request) 5
        set ::turrequest::rate_window 60
        
        set success 1
        
        # Tester limite
        for {set i 0} {$i < 6} {incr i} {
            set allowed [::turrequest::ratelimit::check "test1" "request"]
            if {$i >= 5 && $allowed} {
                set success 0
                break
            }
        }
        
        set success
    } 1

    # Test 30: Hooks système
    test system-hooks {Test hooks système} {
        set triggered 0
        
        # Enregistrer hook
        ::turrequest::hooks::register "request_created" {
            set triggered 1
        }
        
        # Déclencher événement
        ::turrequest::cmd::request "test1" "host" "handle" "#requests" "new HookTest"
        
        # Vérifier déclenchement
        expr {$triggered == 1}
    } 1

    cleanupTests
}

# Exécution tests
package require sqlite3
sqlite3 db :memory:

if {[info exists argv0] && [file tail $argv0] eq [file tail [info script]]} {
    puts "\nDémarrage tests Tur-Request v$::turrequest::VERSION\n"
    
    set failed [llength [dict get [tcltest::runAllTests] "Failed"]]
    
    if {$failed == 0} {
        puts "\nTous les tests ont réussi!"
    } else {
        puts "\n$failed test(s) ont échoué."
    }
} 