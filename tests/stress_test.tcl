###############################################################################
# Tests de Stress Tur-Request v2.0.0
###############################################################################

package require tcltest
source "test_tur-request.tcl"

namespace eval ::turrequest::stress {
    # Configuration
    variable config
    array set config {
        concurrent_users 100
        requests_per_user 50
        operation_delay 10
        test_duration 300
        monitoring_interval 1000
    }
    
    # Statistiques
    variable stats
    array set stats {
        total_requests 0
        successful_requests 0
        failed_requests 0
        min_response_time 999999
        max_response_time 0
        total_response_time 0
        current_users 0
        peak_users 0
        start_time 0
        end_time 0
    }
    
    # File d'attente des opérations
    variable operation_queue {}
    
    # Initialisation test
    proc init {} {
        variable stats
        variable config
        
        # Reset stats
        array set stats {
            total_requests 0
            successful_requests 0
            failed_requests 0
            min_response_time 999999
            max_response_time 0
            total_response_time 0
            current_users 0
            peak_users 0
        }
        
        set stats(start_time) [clock seconds]
        
        # Démarrer monitoring
        after $config(monitoring_interval) [list ::turrequest::stress::monitor_stats]
    }
    
    # Simulation utilisateur
    proc simulate_user {user_id} {
        variable config
        variable stats
        
        incr stats(current_users)
        if {$stats(current_users) > $stats(peak_users)} {
            set stats(peak_users) $stats(current_users)
        }
        
        for {set i 0} {$i < $config(requests_per_user)} {incr i} {
            # Créer requête
            set start [clock microseconds]
            if {[catch {
                ::turrequest::cmd::request "stress_user$user_id" "host" "handle" "#requests" \
                    "new Stress.Test.[expr {$i + 1}].2024-GROUP"
            } err]} {
                incr stats(failed_requests)
            } else {
                incr stats(successful_requests)
                
                # Temps de réponse
                set response_time [expr {[clock microseconds] - $start}]
                if {$response_time < $stats(min_response_time)} {
                    set stats(min_response_time) $response_time
                }
                if {$response_time > $stats(max_response_time)} {
                    set stats(max_response_time) $response_time
                }
                incr stats(total_response_time) $response_time
            }
            incr stats(total_requests)
            
            # Délai entre opérations
            after $config(operation_delay)
        }
        
        incr stats(current_users) -1
    }
    
    # Monitoring statistiques
    proc monitor_stats {} {
        variable stats
        variable config
        
        # Calculer métriques
        set elapsed [expr {[clock seconds] - $stats(start_time)}]
        if {$elapsed >= $config(test_duration)} return
        
        set rps [expr {$stats(total_requests) / double($elapsed)}]
        set avg_response [expr {$stats(total_requests) ? 
            $stats(total_response_time) / double($stats(total_requests)) / 1000.0 : 0}]
        
        # Afficher stats
        puts [format {
            Temps écoulé: %ds
            Requêtes/sec: %.2f
            Succès: %d
            Échecs: %d
            Temps réponse moyen: %.2fms
            Temps réponse min: %.2fms
            Temps réponse max: %.2fms
            Utilisateurs actifs: %d
            Pic utilisateurs: %d
        } $elapsed $rps $stats(successful_requests) $stats(failed_requests) \
          $avg_response [expr {$stats(min_response_time) / 1000.0}] \
          [expr {$stats(max_response_time) / 1000.0}] \
          $stats(current_users) $stats(peak_users)]
        
        # Planifier prochain monitoring
        after $config(monitoring_interval) [list ::turrequest::stress::monitor_stats]
    }
    
    # Test de charge
    proc run_load_test {} {
        variable config
        variable stats
        
        puts "\nDémarrage test de charge Tur-Request v$::turrequest::VERSION"
        puts [format "Configuration: %d utilisateurs, %d requêtes/utilisateur" \
            $config(concurrent_users) $config(requests_per_user)]
        
        # Initialisation
        init
        
        # Lancer utilisateurs simulés
        for {set i 0} {$i < $config(concurrent_users)} {incr i} {
            after 0 [list ::turrequest::stress::simulate_user $i]
        }
        
        # Attendre fin du test
        vwait ::turrequest::stress::stats(end_time)
        
        # Rapport final
        set duration [expr {$stats(end_time) - $stats(start_time)}]
        set total_rps [expr {$stats(total_requests) / double($duration)}]
        set success_rate [expr {$stats(successful_requests) * 100.0 / $stats(total_requests)}]
        
        puts "\nRésultats test de charge:"
        puts [format {
            Durée totale: %ds
            Requêtes totales: %d
            Taux de succès: %.2f%%
            Débit moyen: %.2f req/s
            Temps réponse moyen: %.2fms
            Temps réponse min: %.2fms
            Temps réponse max: %.2fms
            Pic utilisateurs simultanés: %d
        } $duration $stats(total_requests) $success_rate $total_rps \
          [expr {$stats(total_response_time) / double($stats(total_requests)) / 1000.0}] \
          [expr {$stats(min_response_time) / 1000.0}] \
          [expr {$stats(max_response_time) / 1000.0}] \
          $stats(peak_users)]
    }
    
    # Test de stress mémoire
    proc run_memory_test {} {
        variable config
        
        puts "\nDémarrage test mémoire Tur-Request"
        
        # Mesure initiale
        set initial_memory [get_memory_usage]
        
        # Créer charge
        for {set i 0} {$i < 10000} {incr i} {
            ::turrequest::cache::set "test_key_$i" [string repeat "x" 1000]
            if {$i % 1000 == 0} {
                set current_memory [get_memory_usage]
                puts [format "Itération %d: Utilisation mémoire %.2f MB" \
                    $i [expr {$current_memory / 1024.0 / 1024.0}]]
            }
        }
        
        # Forcer nettoyage
        ::turrequest::cache::cleanup
        
        # Mesure finale
        set final_memory [get_memory_usage]
        
        puts [format {
            Mémoire initiale: %.2f MB
            Pic mémoire: %.2f MB
            Mémoire finale: %.2f MB
            Fuite mémoire: %.2f MB
        } [expr {$initial_memory / 1024.0 / 1024.0}] \
          [expr {$config(peak_memory) / 1024.0 / 1024.0}] \
          [expr {$final_memory / 1024.0 / 1024.0}] \
          [expr {($final_memory - $initial_memory) / 1024.0 / 1024.0}]]
    }
    
    # Test de récupération
    proc run_recovery_test {} {
        puts "\nDémarrage test récupération Tur-Request"
        
        # Simuler erreurs DB
        set success 0
        set total 1000
        
        for {set i 0} {$i < $total} {incr i} {
            if {[catch {
                # Simuler erreur aléatoire
                if {rand() < 0.3} {
                    error "SQLITE_BUSY"
                }
                ::turrequest::cmd::request "test1" "host" "handle" "#requests" \
                    "new Recovery.Test.$i"
                incr success
            } err]} {
                puts "Erreur simulée: $err"
            }
        }
        
        puts [format {
            Opérations totales: %d
            Succès: %d
            Échecs récupérés: %d
            Taux récupération: %.2f%%
        } $total $success [expr {$total - $success}] \
          [expr {$success * 100.0 / $total}]]
    }
}

# Exécution tests stress si lancé directement
if {[info exists argv0] && [file tail $argv0] eq [file tail [info script]]} {
    puts "\n=== Tests de Stress Tur-Request ==="
    
    puts "\n1. Test de charge"
    ::turrequest::stress::run_load_test
    
    puts "\n2. Test mémoire"
    ::turrequest::stress::run_memory_test
    
    puts "\n3. Test récupération"
    ::turrequest::stress::run_recovery_test
} 