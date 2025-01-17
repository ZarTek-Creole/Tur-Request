###############################################################################
# Tur-Request v2.0.0 - Module Monitoring Avancé
###############################################################################

namespace eval ::turrequest::monitor {
    # Configuration
    variable config
    array set config {
        enabled 1
        interval 60
        retention 604800
        max_samples 10000
        alert_cpu_threshold 80
        alert_mem_threshold 90
        alert_disk_threshold 95
    }
    
    # Métriques
    variable metrics
    array set metrics {}
    
    # Historique
    variable history
    array set history {}
    
    # Alertes
    variable alerts
    array set alerts {}
    
    # Initialisation
    proc init {} {
        variable config
        
        putlog "Tur-Request: Initialisation du système de monitoring..."
        
        # Création des tables
        sqlite3 db $::turrequest::db_file
        db eval {
            CREATE TABLE IF NOT EXISTS metrics (
                timestamp INTEGER,
                name TEXT,
                value REAL,
                PRIMARY KEY (timestamp, name)
            );
            
            CREATE TABLE IF NOT EXISTS alerts (
                timestamp INTEGER,
                type TEXT,
                message TEXT,
                severity TEXT,
                PRIMARY KEY (timestamp)
            );
        }
        
        # Démarrage de la collecte périodique
        after [expr {$config(interval) * 1000}] [namespace current]::collect_metrics
    }
    
    # Collecte des métriques
    proc collect_metrics {} {
        variable config
        variable metrics
        
        # Métriques système
        set metrics(cpu) [::turrequest::utils::get_cpu_usage]
        set metrics(memory) [::turrequest::utils::get_memory_usage]
        set metrics(disk) [::turrequest::utils::get_disk_usage]
        
        # Métriques requests
        set metrics(requests_active) [::turrequest::utils::get_active_requests]
        set metrics(requests_pending) [::turrequest::utils::get_pending_requests]
        set metrics(requests_filled) [::turrequest::utils::get_filled_requests]
        set metrics(requests_failed) [::turrequest::utils::get_failed_requests]
        
        # Métriques cache
        set metrics(cache_size) [::turrequest::utils::get_cache_size]
        set metrics(cache_hits) [::turrequest::utils::get_cache_hits]
        set metrics(cache_misses) [::turrequest::utils::get_cache_misses]
        
        # Métriques DB
        set metrics(db_size) [::turrequest::utils::get_db_size]
        set metrics(db_queries) [::turrequest::utils::get_query_count]
        set metrics(db_slow_queries) [::turrequest::utils::get_slow_queries]
        
        # Sauvegarde historique
        save_metrics
        
        # Vérification des alertes
        check_alerts
        
        # Nettoyage ancien historique
        cleanup_old_data
        
        # Planification prochaine collecte
        after [expr {$config(interval) * 1000}] [namespace current]::collect_metrics
    }
    
    # Sauvegarde des métriques
    proc save_metrics {} {
        variable metrics
        set timestamp [clock seconds]
        
        sqlite3 db $::turrequest::db_file
        db transaction {
            foreach name [array names metrics] {
                db eval {
                    INSERT INTO metrics (timestamp, name, value)
                    VALUES ($timestamp, $name, $metrics($name))
                }
            }
        }
    }
    
    # Vérification des alertes
    proc check_alerts {} {
        variable config
        variable metrics
        variable alerts
        
        set timestamp [clock seconds]
        
        # CPU élevé
        if {$metrics(cpu) > $config(alert_cpu_threshold)} {
            set msg "Alerte CPU: Utilisation à $metrics(cpu)%"
            db eval {
                INSERT INTO alerts (timestamp, type, message, severity)
                VALUES ($timestamp, 'cpu', $msg, 'warning')
            }
            putlog "Tur-Request: $msg"
        }
        
        # Mémoire élevée
        if {$metrics(memory) > $config(alert_mem_threshold)} {
            set msg "Alerte Mémoire: Utilisation à $metrics(memory)%"
            db eval {
                INSERT INTO alerts (timestamp, type, message, severity)
                VALUES ($timestamp, 'memory', $msg, 'warning')
            }
            putlog "Tur-Request: $msg"
        }
        
        # Espace disque faible
        if {$metrics(disk) > $config(alert_disk_threshold)} {
            set msg "Alerte Disque: Utilisation à $metrics(disk)%"
            db eval {
                INSERT INTO alerts (timestamp, type, message, severity)
                VALUES ($timestamp, 'disk', $msg, 'critical')
            }
            putlog "Tur-Request: $msg"
        }
    }
    
    # Nettoyage des anciennes données
    proc cleanup_old_data {} {
        variable config
        set cutoff [expr {[clock seconds] - $config(retention)}]
        
        sqlite3 db $::turrequest::db_file
        db eval {
            DELETE FROM metrics WHERE timestamp < $cutoff;
            DELETE FROM alerts WHERE timestamp < $cutoff;
        }
    }
    
    # Export des métriques pour Prometheus
    proc export_metrics {} {
        variable metrics
        set output ""
        
        foreach name [array names metrics] {
            append output "turrequest_$name $metrics($name)\n"
        }
        
        return $output
    }
}

# Initialisation du module
::turrequest::monitor::init

putlog "Tur-Request: Module Monitoring chargé."
``` 