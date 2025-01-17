# Tests pour le système de monitoring de Tur-Request

package require tcltest
namespace import ::tcltest::*

# Configuration test
set ::turrequest::db_file ":memory:"
set ::turrequest::monitor::config(interval) 1
set ::turrequest::monitor::config(retention) 60

# Mock pour putserv/putlog
proc putserv {text} {}
proc putlog {text} {}

# Tests initialisation
test monitor-1.1 "Initialisation monitoring" -body {
    ::turrequest::monitor::init
    expr {[info exists ::turrequest::monitor::metrics] && [array exists ::turrequest::monitor::metrics]}
} -result 1

# Tests collecte métriques
test monitor-2.1 "Collecte métriques système" -body {
    ::turrequest::monitor::collect_metrics
    expr {$::turrequest::monitor::metrics(cpu) >= 0 && $::turrequest::monitor::metrics(cpu) <= 100}
} -result 1

test monitor-2.2 "Collecte métriques requêtes" -body {
    ::turrequest::monitor::collect_metrics
    expr {[info exists ::turrequest::monitor::metrics(requests_active)] && [string is integer $::turrequest::monitor::metrics(requests_active)]}
} -result 1

test monitor-2.3 "Collecte métriques cache" -body {
    ::turrequest::monitor::collect_metrics
    expr {[info exists ::turrequest::monitor::metrics(cache_hits)] && [string is integer $::turrequest::monitor::metrics(cache_hits)]}
} -result 1

# Tests sauvegarde métriques
test monitor-3.1 "Sauvegarde métriques" -body {
    ::turrequest::monitor::save_metrics
    set count [db eval {SELECT COUNT(*) FROM metrics}]
    expr {$count > 0}
} -result 1

# Tests alertes
test monitor-4.1 "Déclenchement alerte CPU" -body {
    set ::turrequest::monitor::metrics(cpu) 95
    ::turrequest::monitor::check_alerts
    set count [db eval {SELECT COUNT(*) FROM alerts WHERE type = 'cpu'}]
    expr {$count > 0}
} -result 1

test monitor-4.2 "Déclenchement alerte mémoire" -body {
    set ::turrequest::monitor::metrics(memory) 95
    ::turrequest::monitor::check_alerts
    set count [db eval {SELECT COUNT(*) FROM alerts WHERE type = 'memory'}]
    expr {$count > 0}
} -result 1

# Tests nettoyage
test monitor-5.1 "Nettoyage ancien historique" -body {
    after 2000
    ::turrequest::monitor::cleanup_old_data
    set count [db eval {SELECT COUNT(*) FROM metrics WHERE timestamp < (strftime('%s', 'now') - 60)}]
    expr {$count == 0}
} -result 1

# Tests commandes IRC
test monitor-6.1 "Commande system" -body {
    ::turrequest::cmd::monitor::show_system_metrics "#test"
    expr 1
} -result 1

test monitor-6.2 "Commande requests" -body {
    ::turrequest::cmd::monitor::show_request_metrics "#test"
    expr 1
} -result 1

test monitor-6.3 "Commande cache" -body {
    ::turrequest::cmd::monitor::show_cache_metrics "#test"
    expr 1
} -result 1

test monitor-6.4 "Commande db" -body {
    ::turrequest::cmd::monitor::show_db_metrics "#test"
    expr 1
} -result 1

test monitor-6.5 "Commande alerts" -body {
    ::turrequest::cmd::monitor::show_alerts "#test"
    expr 1
} -result 1

test monitor-6.6 "Commande history" -body {
    ::turrequest::cmd::monitor::show_history "#test" "cpu"
    expr 1
} -result 1

# Tests formatage
test monitor-7.1 "Formatage taille bytes" -body {
    ::turrequest::cmd::monitor::format_size 512
} -result "512B"

test monitor-7.2 "Formatage taille KB" -body {
    ::turrequest::cmd::monitor::format_size 1536
} -result "1.5KB"

test monitor-7.3 "Formatage taille MB" -body {
    ::turrequest::cmd::monitor::format_size 1572864
} -result "1.5MB"

test monitor-7.4 "Formatage taille GB" -body {
    ::turrequest::cmd::monitor::format_size 1610612736
} -result "1.5GB"

# Tests export Prometheus
test monitor-8.1 "Export métriques Prometheus" -body {
    set metrics [::turrequest::monitor::export_metrics]
    expr {[string length $metrics] > 0}
} -result 1

# Nettoyage
cleanupTests

putlog "Tests monitoring terminés." 