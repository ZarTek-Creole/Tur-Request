###############################################################################
# Tur-Request v2.0.0
# Un système de requêtes avancé pour glFTPd avec intégration Eggdrop et pzs-ng
###############################################################################

package require sqlite3
package require json

namespace eval ::turrequest {
    # Version
    variable VERSION "2.0.0"
    
    # Variables globales initialisées depuis la config
    variable glroot
    variable request_chan
    variable announce_chan
    variable db_file
    variable log_file
    variable min_points
    variable max_requests
    variable request_time
    variable fill_time
    
    # Chargement configuration
    if {[file exists "scripts/tur-request/tur-request.conf"]} {
        source "scripts/tur-request/tur-request.conf"
    } else {
        putlog "Erreur: Fichier de configuration non trouvé!"
        return
    }
    
    # Initialisation base de données
    if {![file exists $db_file]} {
        sqlite3 db $db_file
        db eval {
            CREATE TABLE requests (
                id INTEGER PRIMARY KEY,
                title TEXT NOT NULL,
                details TEXT,
                user TEXT NOT NULL,
                created INTEGER NOT NULL,
                status TEXT DEFAULT 'pending',
                filler TEXT,
                fill_path TEXT,
                filled INTEGER
            );
            CREATE TABLE points (
                user TEXT PRIMARY KEY,
                points INTEGER DEFAULT 0
            );
            CREATE TABLE bans (
                user TEXT PRIMARY KEY,
                reason TEXT,
                admin TEXT,
                created INTEGER
            );
        }
        putlog "Base de données initialisée"
    }
    
    # Connexion base de données
    sqlite3 db $db_file
}

###############################################################################
# Commandes Publiques
###############################################################################

# Création requête
proc ::turrequest::cmd::request {nick host hand chan text} {
    if {![channel get $chan requests]} { return }
    
    set args [split $text]
    set cmd [lindex $args 0]
    set params [lrange $args 1 end]
    
    switch -nocase $cmd {
        "new" {
            if {[llength $params] < 1} {
                putserv "PRIVMSG $chan :\00304Erreur:\003 Usage: !request new <titre> \[détails\]"
                return
            }
            set title [lindex $params 0]
            set details [join [lrange $params 1 end]]
            
            # Vérification points
            if {[::turrequest::points::get $nick] < $::turrequest::min_points} {
                putserv "PRIVMSG $chan :\00304Erreur:\003 Points insuffisants"
                return
            }
            
            # Vérification nombre requêtes actives
            set active [db eval {
                SELECT COUNT(*) FROM requests 
                WHERE user = $nick AND status = 'pending'
            }]
            if {$active >= $::turrequest::max_requests} {
                putserv "PRIVMSG $chan :\00304Erreur:\003 Nombre maximum de requêtes atteint"
                return
            }
            
            # Création requête
            set now [clock seconds]
            db eval {
                INSERT INTO requests (title, details, user, created)
                VALUES ($title, $details, $nick, $now)
            }
            set id [db last_insert_rowid]
            
            # Points
            ::turrequest::points::add $nick $::turrequest::points(request)
            
            # Notification
            putserv "PRIVMSG $chan :[format $::turrequest::format(request) \
                id $id title $title details $details user $nick]"
        }
        
        "info" {
            if {[llength $params] != 1} {
                putserv "PRIVMSG $chan :\00304Erreur:\003 Usage: !request info <id>"
                return
            }
            set id [lindex $params 0]
            
            set req [db eval {
                SELECT * FROM requests WHERE id = $id
            }]
            if {[llength $req] == 0} {
                putserv "PRIVMSG $chan :\00304Erreur:\003 Requête #$id non trouvée"
                return
            }
            
            array set r $req
            putserv "PRIVMSG $chan :\002Requête #$id:\002 $r(title)"
            putserv "PRIVMSG $chan :\002Détails:\002 $r(details)"
            putserv "PRIVMSG $chan :\002Par:\002 $r(user) \002Status:\002 $r(status)"
            if {$r(status) eq "filled"} {
                putserv "PRIVMSG $chan :\002Rempli par:\002 $r(filler) dans $r(fill_path)"
            }
        }
        
        "list" {
            set status "pending"
            if {[llength $params] > 0} {
                set status [lindex $params 0]
            }
            
            set reqs [db eval {
                SELECT id,title,user FROM requests 
                WHERE status = $status
                ORDER BY created DESC LIMIT 5
            }]
            
            if {[llength $reqs] == 0} {
                putserv "PRIVMSG $chan :\00312Info:\003 Aucune requête $status"
                return
            }
            
            putserv "PRIVMSG $chan :\002Requêtes $status:\002"
            foreach {id title user} $reqs {
                putserv "PRIVMSG $chan :#$id $title (par $user)"
            }
        }
        
        "search" {
            if {[llength $params] < 1} {
                putserv "PRIVMSG $chan :\00304Erreur:\003 Usage: !request search <terme>"
                return
            }
            set term [join $params]
            
            set reqs [db eval {
                SELECT id,title,user FROM requests 
                WHERE title LIKE '%' || $term || '%'
                OR details LIKE '%' || $term || '%'
                ORDER BY created DESC LIMIT 5
            }]
            
            if {[llength $reqs] == 0} {
                putserv "PRIVMSG $chan :\00312Info:\003 Aucun résultat pour: $term"
                return
            }
            
            putserv "PRIVMSG $chan :\002Résultats pour: $term\002"
            foreach {id title user} $reqs {
                putserv "PRIVMSG $chan :#$id $title (par $user)"
            }
        }
        
        "cancel" {
            if {[llength $params] != 1} {
                putserv "PRIVMSG $chan :\00304Erreur:\003 Usage: !request cancel <id>"
                return
            }
            set id [lindex $params 0]
            
            set req [db eval {
                SELECT user,status FROM requests WHERE id = $id
            }]
            if {[llength $req] == 0} {
                putserv "PRIVMSG $chan :\00304Erreur:\003 Requête #$id non trouvée"
                return
            }
            
            lassign $req user status
            if {$status ne "pending"} {
                putserv "PRIVMSG $chan :\00304Erreur:\003 Requête #$id déjà $status"
                return
            }
            if {$user ne $nick && ![::turrequest::admin::is_admin $nick]} {
                putserv "PRIVMSG $chan :\00304Erreur:\003 Permission refusée"
                return
            }
            
            db eval {
                UPDATE requests SET status = 'canceled'
                WHERE id = $id
            }
            
            putserv "PRIVMSG $chan :\00304Requête #$id annulée par $nick\003"
        }
        
        default {
            putserv "PRIVMSG $chan :\00304Erreur:\003 Commande inconnue. Usage: !request <new|info|list|search|cancel>"
        }
    }
}

# Remplissage requête
proc ::turrequest::cmd::fill {nick host hand chan text} {
    if {![channel get $chan requests]} { return }
    
    set args [split $text]
    if {[llength $args] != 2} {
        putserv "PRIVMSG $chan :\00304Erreur:\003 Usage: !fill <id> <path>"
        return
    }
    
    set id [lindex $args 0]
    set path [lindex $args 1]
    
    # Vérification requête
    set req [db eval {
        SELECT user,status FROM requests WHERE id = $id
    }]
    if {[llength $req] == 0} {
        putserv "PRIVMSG $chan :\00304Erreur:\003 Requête #$id non trouvée"
        return
    }
    
    lassign $req user status
    if {$status ne "pending"} {
        putserv "PRIVMSG $chan :\00304Erreur:\003 Requête #$id déjà $status"
        return
    }
    
    # Vérification chemin
    if {![file exists $::turrequest::glroot/$path]} {
        putserv "PRIVMSG $chan :\00304Erreur:\003 Chemin invalide: $path"
        return
    }
    
    # Remplissage
    set now [clock seconds]
    db eval {
        UPDATE requests SET 
            status = 'filled',
            filler = $nick,
            fill_path = $path,
            filled = $now
        WHERE id = $id
    }
    
    # Points
    ::turrequest::points::add $nick $::turrequest::points(fill)
    
    # Notification
    set title [db eval {SELECT title FROM requests WHERE id = $id}]
    putserv "PRIVMSG $chan :[format $::turrequest::format(filled) \
        id $id title $title filler $nick path $path]"
}

###############################################################################
# Commandes Admin
###############################################################################

# Commande admin
proc ::turrequest::cmd::reqadmin {nick host hand chan text} {
    if {![::turrequest::admin::is_admin $nick]} {
        putserv "PRIVMSG $chan :\00304Erreur:\003 Permission refusée"
        return
    }
    
    set args [split $text]
    set cmd [lindex $args 0]
    set params [lrange $args 1 end]
    
    switch -nocase $cmd {
        "clean" {
            set count [::turrequest::admin::clean]
            putserv "PRIVMSG $chan :\00303$count requêtes nettoyées\003"
        }
        
        "del" {
            if {[llength $params] != 1} {
                putserv "PRIVMSG $chan :\00304Erreur:\003 Usage: !reqadmin del <id>"
                return
            }
            set id [lindex $params 0]
            
            if {[::turrequest::admin::delete $id]} {
                putserv "PRIVMSG $chan :\00303Requête #$id supprimée\003"
            } else {
                putserv "PRIVMSG $chan :\00304Erreur:\003 Requête #$id non trouvée"
            }
        }
        
        "ban" {
            if {[llength $params] < 1} {
                putserv "PRIVMSG $chan :\00304Erreur:\003 Usage: !reqadmin ban <user> \[raison\]"
                return
            }
            set user [lindex $params 0]
            set reason [join [lrange $params 1 end]]
            
            if {[::turrequest::admin::ban $user $nick $reason]} {
                putserv "PRIVMSG $chan :\00303$user banni par $nick\003"
                if {$reason ne ""} {
                    putserv "PRIVMSG $chan :\002Raison:\002 $reason"
                }
            } else {
                putserv "PRIVMSG $chan :\00304Erreur:\003 Impossible de bannir $user"
            }
        }
        
        default {
            putserv "PRIVMSG $chan :\00304Erreur:\003 Commande inconnue. Usage: !reqadmin <clean|del|ban>"
        }
    }
}

# Statistiques
proc ::turrequest::cmd::reqstats {nick host hand chan text} {
    if {![channel get $chan requests]} { return }
    
    # Stats globales
    set stats [db eval {
        SELECT 
            COUNT(*) as total,
            SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
            SUM(CASE WHEN status = 'filled' THEN 1 ELSE 0 END) as filled,
            SUM(CASE WHEN status = 'canceled' THEN 1 ELSE 0 END) as canceled
        FROM requests
    }]
    array set s $stats
    
    putserv "PRIVMSG $chan :\002Statistiques Tur-Request:\002"
    putserv "PRIVMSG $chan :Total: $s(total) | En attente: $s(pending) | Remplies: $s(filled) | Annulées: $s(canceled)"
    
    # Top requesters
    set top [db eval {
        SELECT user, COUNT(*) as count
        FROM requests
        GROUP BY user
        ORDER BY count DESC
        LIMIT 3
    }]
    
    if {[llength $top] > 0} {
        putserv "PRIVMSG $chan :\002Top Requesters:\002"
        foreach {user count} $top {
            putserv "PRIVMSG $chan :$user: $count requêtes"
        }
    }
}

###############################################################################
# Points & Crédits
###############################################################################

namespace eval ::turrequest::points {
    # Obtenir points
    proc get {user} {
        set points [db eval {
            SELECT points FROM points WHERE user = $user
        }]
        if {[llength $points] == 0} {
            return 0
        }
        return [lindex $points 0]
    }
    
    # Ajouter points
    proc add {user amount} {
        set current [get $user]
        set new [expr {$current + $amount}]
        
        db eval {
            INSERT OR REPLACE INTO points (user, points)
            VALUES ($user, $new)
        }
        return $new
    }
}

###############################################################################
# Administration
###############################################################################

namespace eval ::turrequest::admin {
    # Vérifier admin
    proc is_admin {user} {
        set groups [split [getuser $user XTRA groups] " "]
        foreach group $::turrequest::admin_groups {
            if {[lsearch -nocase $groups $group] != -1} {
                return 1
            }
        }
        return 0
    }
    
    # Nettoyage ancien
    proc clean {} {
        set cutoff [expr {[clock seconds] - ($::turrequest::fill_time * 86400)}]
        set count [db eval {
            DELETE FROM requests 
            WHERE status != 'pending'
            AND created < $cutoff
        }]
        return $count
    }
    
    # Supprimer requête
    proc delete {id} {
        set count [db eval {
            DELETE FROM requests WHERE id = $id
        }]
        return [expr {$count > 0}]
    }
    
    # Bannir utilisateur
    proc ban {user admin reason} {
        set now [clock seconds]
        db eval {
            INSERT OR REPLACE INTO bans (user, reason, admin, created)
            VALUES ($user, $reason, $admin, $now)
        }
        return 1
    }
}

###############################################################################
# Bindings
###############################################################################

# Commandes publiques
bind pub - !request ::turrequest::cmd::request
bind pub - !fill ::turrequest::cmd::fill

# Commandes admin
bind pub - !reqadmin ::turrequest::cmd::reqadmin
bind pub - !reqstats ::turrequest::cmd::reqstats

###############################################################################
# Initialisation
###############################################################################

putlog "Tur-Request v$::turrequest::VERSION chargé" 