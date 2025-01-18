###############################################################################
# Tur-Request v2.0.0 - Utilitaires Monitoring
###############################################################################

namespace eval ::turrequest::utils {
    # Cache résultats
    variable cache
    array set cache {}
    
    # Obtenir utilisation CPU
    proc get_cpu_usage {} {
        # Linux
        if {[file exists "/proc/stat"]} {
            set f [open "/proc/stat" r]
            gets $f line
            close $f
            
            if {[regexp {^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)} $line -> user nice system idle]} {
                set total [expr {$user + $nice + $system + $idle}]
                set used [expr {$user + $nice + $system}]
                return [expr {int(double($used) / $total * 100)}]
            }
        }
        
        # Fallback
        if {[catch {exec top -bn1 | grep "Cpu(s)" | awk '{print $2}'} cpu]} {
            return 0
        }
        return [expr {int($cpu)}]
    }
    
    # Obtenir utilisation mémoire
    proc get_memory_usage {} {
        # Linux
        if {[file exists "/proc/meminfo"]} {
            set f [open "/proc/meminfo" r]
            set total 0
            set free 0
            set buffers 0
            set cached 0
            
            while {[gets $f line] >= 0} {
                if {[regexp {^MemTotal:\s+(\d+)} $line -> val]} {
                    set total $val
                } elseif {[regexp {^MemFree:\s+(\d+)} $line -> val]} {
                    set free $val
                } elseif {[regexp {^Buffers:\s+(\d+)} $line -> val]} {
                    set buffers $val
                } elseif {[regexp {^Cached:\s+(\d+)} $line -> val]} {
                    set cached $val
                }
            }
            close $f
            
            if {$total > 0} {
                set used [expr {$total - $free - $buffers - $cached}]
                return [expr {int(double($used) / $total * 100)}]
            }
        }
        
        # Fallback
        if {[catch {exec free | grep Mem | awk '{print $3/$2 * 100.0}'} mem]} {
            return 0
        }
        return [expr {int($mem)}]
    }
    
    # Obtenir utilisation disque
    proc get_disk_usage {{path "/"}} {
        if {[catch {
            set df [exec df -k $path]
            set lines [split $df "\n"]
            set last [lindex $lines end]
            set fields [regexp -all -inline {\S+} $last]
            set usage [lindex $fields 4]
            regsub {%} $usage "" usage
        } err]} {
            return 0
        }
        return $usage
    }
    
    # Obtenir uptime système
    proc get_uptime {} {
        if {[file exists "/proc/uptime"]} {
            set f [open "/proc/uptime" r]
            gets $f line
            close $f
            
            set uptime [lindex [split $line] 0]
            return [format_duration $uptime]
        }
        
        return "N/A"
    }
    
    # Obtenir taille base de données
    proc get_db_size {} {
        variable cache
        
        # Cache 5 minutes
        set now [clock seconds]
        if {[info exists cache(db_size)] && 
            [expr {$now - [dict get $cache(db_size) time]}] < 300} {
            return [dict get $cache(db_size) value]
        }
        
        if {[catch {
            set size [file size $::turrequest::db_file]
            set cache(db_size) [dict create time $now value $size]
            return [format_size $size]
        } err]} {
            return "0B"
        }
    }
    
    # Obtenir nombre requêtes actives
    proc get_active_requests {} {
        return [db eval {
            SELECT COUNT(*) FROM requests
            WHERE status = 'pending'
        }]
    }
    
    # Obtenir nombre requêtes en attente
    proc get_pending_count {} {
        return [db eval {
            SELECT COUNT(*) FROM requests
            WHERE status = 'new'
        }]
    }
    
    # Obtenir nombre requêtes remplies
    proc get_filled_count {} {
        return [db eval {
            SELECT COUNT(*) FROM requests
            WHERE status = 'filled'
        }]
    }
    
    # Obtenir nombre requêtes échouées
    proc get_failed_count {} {
        return [db eval {
            SELECT COUNT(*) FROM requests
            WHERE status = 'failed'
        }]
    }
    
    # Obtenir temps moyen traitement
    proc get_average_time {} {
        return [db eval {
            SELECT AVG(filled - created)
            FROM requests
            WHERE status = 'filled'
            AND filled > 0
        }]
    }
    
    # Obtenir taille cache
    proc get_cache_size {} {
        return [array size ::turrequest::cache::data]
    }
    
    # Obtenir hits cache
    proc get_cache_hits {} {
        return $::turrequest::cache::stats(hits)
    }
    
    # Obtenir misses cache
    proc get_cache_misses {} {
        return $::turrequest::cache::stats(misses)
    }
    
    # Obtenir ratio cache
    proc get_cache_ratio {} {
        set hits [get_cache_hits]
        set total [expr {$hits + [get_cache_misses]}]
        
        if {$total == 0} {
            return 0
        }
        
        return [expr {int(double($hits) / $total * 100)}]
    }
    
    # Obtenir nombre requêtes SQL
    proc get_query_count {} {
        return $::turrequest::db::stats(queries)
    }
    
    # Obtenir nombre requêtes lentes
    proc get_slow_queries {} {
        return $::turrequest::db::stats(slow)
    }
    
    # Obtenir nombre erreurs DB
    proc get_db_errors {} {
        return $::turrequest::db::stats(errors)
    }
    
    # Formater durée
    proc format_duration {seconds} {
        set days [expr {$seconds / 86400}]
        set hours [expr {($seconds % 86400) / 3600}]
        set minutes [expr {($seconds % 3600) / 60}]
        
        set result ""
        if {$days > 0} {
            append result "${days}d "
        }
        if {$hours > 0 || $days > 0} {
            append result "${hours}h "
        }
        append result "${minutes}m"
        
        return $result
    }
    
    # Formater taille
    proc format_size {bytes} {
        set units {B KB MB GB TB}
        set i 0
        set size $bytes
        
        while {$size >= 1024 && $i < [llength $units]-1} {
            set size [expr {$size / 1024.0}]
            incr i
        }
        
        return [format "%.1f%s" $size [lindex $units $i]]
    }
    
    # Races actives
    proc get_active_races {} {
        set count 0
        if {[file exists "$::glroot/ftp-data/pzs-ng/race-"]} {
            set count [llength [glob -nocomplain "$::glroot/ftp-data/pzs-ng/race-*"]]
        }
        return $count
    }
    
    # Races complètes
    proc get_completed_races {} {
        sqlite3 db $::turrequest::db_file
        return [db eval {
            SELECT COUNT(*) FROM races 
            WHERE status = 'COMPLETE' 
            AND timestamp > (strftime('%s', 'now') - 86400)
        }]
    }
    
    # Races incomplètes
    proc get_incomplete_races {} {
        sqlite3 db $::turrequest::db_file
        return [db eval {
            SELECT COUNT(*) FROM races 
            WHERE status = 'INCOMPLETE'
            AND timestamp > (strftime('%s', 'now') - 86400)
        }]
    }
    
    # Utilisateurs en race
    proc get_racing_users {} {
        set users {}
        foreach race [glob -nocomplain "$::glroot/ftp-data/pzs-ng/race-*"] {
            if {[file exists "$race/users"]} {
                set f [open "$race/users" r]
                while {[gets $f line] != -1} {
                    if {[regexp {^([\w-]+)\s} $line -> user]} {
                        lappend users $user
                    }
                }
                close $f
            }
        }
        return [llength [lsort -unique $users]]
    }
    
    # Vitesse moyenne race
    proc get_average_race_speed {} {
        set total_speed 0
        set count 0
        foreach race [glob -nocomplain "$::glroot/ftp-data/pzs-ng/race-*"] {
            if {[file exists "$race/race-stats"]} {
                set f [open "$race/race-stats" r]
                while {[gets $f line] != -1} {
                    if {[regexp {SPEED\s+([\d.]+)} $line -> speed]} {
                        incr count
                        set total_speed [expr {$total_speed + $speed}]
                    }
                }
                close $f
            }
        }
        if {$count > 0} {
            return [expr {$total_speed / $count}]
        }
        return 0
    }
    
    # Total fichiers en race
    proc get_total_race_files {} {
        set total 0
        foreach race [glob -nocomplain "$::glroot/ftp-data/pzs-ng/race-*"] {
            if {[file exists "$race/race-stats"]} {
                set f [open "$race/race-stats" r]
                while {[gets $f line] != -1} {
                    if {[regexp {FILES\s+(\d+)} $line -> files]} {
                        incr total $files
                    }
                }
                close $f
            }
        }
        return $total
    }
    
    # Auto-fill succès
    proc get_autofill_success {} {
        sqlite3 db $::turrequest::db_file
        return [db eval {
            SELECT COUNT(*) FROM requests 
            WHERE status = 'FILLED' 
            AND fill_type = 'AUTO'
            AND timestamp > (strftime('%s', 'now') - 86400)
        }]
    }
    
    # Auto-fill échecs
    proc get_autofill_failed {} {
        sqlite3 db $::turrequest::db_file
        return [db eval {
            SELECT COUNT(*) FROM requests 
            WHERE status = 'FAILED' 
            AND fill_type = 'AUTO'
            AND timestamp > (strftime('%s', 'now') - 86400)
        }]
    }
    
    # Auto-fill en attente
    proc get_autofill_pending {} {
        sqlite3 db $::turrequest::db_file
        return [db eval {
            SELECT COUNT(*) FROM requests 
            WHERE status = 'PENDING' 
            AND fill_type = 'AUTO'
        }]
    }
}

putlog "Tur-Request: Module Utils chargé" 