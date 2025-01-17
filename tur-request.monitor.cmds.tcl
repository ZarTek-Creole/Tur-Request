# Tur-Request v2.0.0 - Commandes Monitoring

namespace eval ::turrequest::cmd::monitor {

    # Commande principale monitoring
    proc reqmon {nick uhost hand chan text} {
        if {![is_admin $nick]} {
            putserv "PRIVMSG $chan :\00304Erreur:\003 Commande réservée aux administrateurs"
            return
        }
        
        set args [split [string trim $text]]
        set cmd [lindex $args 0]
        
        switch -nocase $cmd {
            "system" { show_system_metrics $chan }
            "requests" { show_request_metrics $chan }
            "cache" { show_cache_metrics $chan }
            "db" { show_db_metrics $chan }
            "alerts" { show_alerts $chan }
            "history" { show_history $chan [lindex $args 1] }
            default {
                putserv "PRIVMSG $chan :\00314Usage:\003 !reqmon <system|requests|cache|db|alerts|history>"
            }
        }
    }
    
    # Affichage métriques système
    proc show_system_metrics {chan} {
        variable ::turrequest::monitor::metrics
        
        putserv "PRIVMSG $chan :\00314Métriques Système:\003"
        putserv "PRIVMSG $chan :CPU: $metrics(cpu)% | Mémoire: $metrics(memory)% | Disque: $metrics(disk)%"
    }
    
    # Affichage métriques requêtes
    proc show_request_metrics {chan} {
        variable ::turrequest::monitor::metrics
        
        putserv "PRIVMSG $chan :\00314Métriques Requêtes:\003"
        putserv "PRIVMSG $chan :Actives: $metrics(requests_active) | En attente: $metrics(requests_pending) | Remplies: $metrics(requests_filled) | Échouées: $metrics(requests_failed)"
    }
    
    # Affichage métriques cache
    proc show_cache_metrics {chan} {
        variable ::turrequest::monitor::metrics
        
        set ratio [expr {$metrics(cache_hits) / ($metrics(cache_hits) + $metrics(cache_misses) + 0.0001) * 100}]
        
        putserv "PRIVMSG $chan :\00314Métriques Cache:\003"
        putserv "PRIVMSG $chan :Taille: $metrics(cache_size) | Hits: $metrics(cache_hits) | Misses: $metrics(cache_misses) | Ratio: [format "%.1f" $ratio]%"
    }
    
    # Affichage métriques base de données
    proc show_db_metrics {chan} {
        variable ::turrequest::monitor::metrics
        
        putserv "PRIVMSG $chan :\00314Métriques Base de données:\003"
        putserv "PRIVMSG $chan :Taille: [format_size $metrics(db_size)] | Requêtes: $metrics(db_queries) | Requêtes lentes: $metrics(db_slow_queries)"
    }
    
    # Affichage alertes
    proc show_alerts {chan} {
        sqlite3 db $::turrequest::db_file
        set alerts [db eval {
            SELECT * FROM alerts 
            WHERE timestamp > (strftime('%s', 'now') - 3600)
            ORDER BY timestamp DESC
            LIMIT 5
        }]
        
        if {[llength $alerts] == 0} {
            putserv "PRIVMSG $chan :\00314Alertes:\003 Aucune alerte récente"
            return
        }
        
        putserv "PRIVMSG $chan :\00314Dernières Alertes:\003"
        foreach {timestamp type message severity} $alerts {
            set time [clock format $timestamp -format "%H:%M:%S"]
            putserv "PRIVMSG $chan :$time - \[[string toupper $severity]\] $message"
        }
    }
    
    # Affichage historique
    proc show_history {chan metric} {
        if {$metric eq ""} {
            putserv "PRIVMSG $chan :\00314Usage:\003 !reqmon history <metric>"
            return
        }
        
        sqlite3 db $::turrequest::db_file
        set values [db eval {
            SELECT timestamp, value 
            FROM metrics 
            WHERE name = $metric
            AND timestamp > (strftime('%s', 'now') - 3600)
            ORDER BY timestamp DESC
            LIMIT 5
        }]
        
        if {[llength $values] == 0} {
            putserv "PRIVMSG $chan :\00314Historique $metric:\003 Aucune donnée disponible"
            return
        }
        
        putserv "PRIVMSG $chan :\00314Historique $metric:\003"
        foreach {timestamp value} $values {
            set time [clock format $timestamp -format "%H:%M:%S"]
            putserv "PRIVMSG $chan :$time - $value"
        }
    }
    
    # Formatage taille
    proc format_size {bytes} {
        if {$bytes < 1024} {
            return "${bytes}B"
        } elseif {$bytes < 1048576} {
            return "[format "%.1f" [expr {$bytes/1024.0}]]KB"
        } elseif {$bytes < 1073741824} {
            return "[format "%.1f" [expr {$bytes/1048576.0}]]MB"
        } else {
            return "[format "%.1f" [expr {$bytes/1073741824.0}]]GB"
        }
    }
}

# Binding commande monitoring
bind pub - !reqmon ::turrequest::cmd::monitor::reqmon

putlog "Tur-Request: Commandes Monitoring chargées." 