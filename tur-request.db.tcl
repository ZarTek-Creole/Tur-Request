# Module Base de Données Tur-Request

namespace eval ::turrequest::db {
    # Configuration DB
    variable db_file [file join [pwd] $::turrequest::config(db_file)]
    variable db_version "2.0"
    
    # Structure tables
    variable tables
    array set tables {
        requests {
            id          INTEGER
            user        TEXT
            title       TEXT
            details     TEXT
            status      TEXT
            created     INTEGER
            updated     INTEGER
            filled_by   TEXT
            fill_path   TEXT
            fill_date   INTEGER
        }
        users {
            user        TEXT
            points      INTEGER
            requests    INTEGER
            fills       INTEGER
            banned      INTEGER
            ban_reason  TEXT
            last_req    INTEGER
        }
    }

    # Initialisation DB
    proc init {} {
        variable db_file
        
        if {![file exists $db_file]} {
            create_database
        }
        
        # Vérification version
        check_version
    }

    # Création base
    proc create_database {} {
        variable db_file
        variable tables
        
        package require sqlite3
        sqlite3 db $db_file
        
        db transaction {
            # Table requêtes
            db eval {
                CREATE TABLE requests (
                    id INTEGER PRIMARY KEY,
                    user TEXT NOT NULL,
                    title TEXT NOT NULL,
                    details TEXT,
                    status TEXT DEFAULT 'new',
                    created INTEGER,
                    updated INTEGER,
                    filled_by TEXT,
                    fill_path TEXT,
                    fill_date INTEGER
                )
            }
            
            # Table utilisateurs
            db eval {
                CREATE TABLE users (
                    user TEXT PRIMARY KEY,
                    points INTEGER DEFAULT 0,
                    requests INTEGER DEFAULT 0,
                    fills INTEGER DEFAULT 0,
                    banned INTEGER DEFAULT 0,
                    ban_reason TEXT,
                    last_req INTEGER
                )
            }
            
            # Table version
            db eval {
                CREATE TABLE version (
                    version TEXT,
                    updated INTEGER
                )
            }
            
            # Version initiale
            db eval {
                INSERT INTO version (version, updated)
                VALUES ($::turrequest::db::db_version, [clock seconds])
            }
        }
        
        db close
    }

    # Création requête
    proc create_request {user title details} {
        package require sqlite3
        sqlite3 db $::turrequest::db::db_file
        
        set now [clock seconds]
        
        db transaction {
            # Insertion requête
            db eval {
                INSERT INTO requests (user, title, details, created, updated)
                VALUES ($user, $title, $details, $now, $now)
            }
            
            set id [db last_insert_rowid]
            
            # Mise à jour stats utilisateur
            db eval {
                INSERT OR REPLACE INTO users (user, requests, last_req)
                VALUES ($user, 
                        COALESCE((SELECT requests FROM users WHERE user = $user), 0) + 1,
                        $now)
            }
        }
        
        db close
        return $id
    }

    # Remplissage requête
    proc fill_request {id filler path} {
        package require sqlite3
        sqlite3 db $::turrequest::db::db_file
        
        set now [clock seconds]
        
        db transaction {
            # Vérification requête
            set exists [db onecolumn {
                SELECT COUNT(*) FROM requests 
                WHERE id = $id AND status = 'new'
            }]
            
            if {!$exists} {
                error "Requête invalide ou déjà remplie"
            }
            
            # Mise à jour requête
            db eval {
                UPDATE requests 
                SET status = 'filled',
                    filled_by = $filler,
                    fill_path = $path,
                    fill_date = $now,
                    updated = $now
                WHERE id = $id
            }
            
            # Mise à jour stats remplisseur
            db eval {
                INSERT OR REPLACE INTO users (user, fills, points)
                VALUES ($filler, 
                        COALESCE((SELECT fills FROM users WHERE user = $filler), 0) + 1,
                        COALESCE((SELECT points FROM users WHERE user = $filler), 0) + 5)
            }
        }
        
        db close
    }

    # Recherche requêtes
    proc search_requests {pattern {status "new"}} {
        package require sqlite3
        sqlite3 db $::turrequest::db::db_file
        
        set results [list]
        db eval {
            SELECT id, user, title, created, status
            FROM requests
            WHERE (title LIKE '%' || $pattern || '%' OR
                  details LIKE '%' || $pattern || '%')
            AND ($status = '*' OR status = $status)
            ORDER BY created DESC
            LIMIT 10
        } row {
            lappend results [array get row]
        }
        
        db close
        return $results
    }

    # Stats utilisateur
    proc get_user_stats {user} {
        package require sqlite3
        sqlite3 db $::turrequest::db::db_file
        
        set stats [db eval {
            SELECT points, requests, fills, banned, ban_reason
            FROM users
            WHERE user = $user
        }]
        
        db close
        return $stats
    }

    # Nettoyage ancien
    proc cleanup_old_requests {days} {
        package require sqlite3
        sqlite3 db $::turrequest::db::db_file
        
        set cutoff [expr {[clock seconds] - ($days * 86400)}]
        
        db eval {
            DELETE FROM requests
            WHERE status = 'filled'
            AND fill_date < $cutoff
        }
        
        db close
    }
}

# Initialisation au chargement
::turrequest::db::init 