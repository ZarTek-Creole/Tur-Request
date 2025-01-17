# 🔧 Scripts TCL Tur-Request

## 📋 1. Architecture Core

### 1.1 Structure Projet
```tcl
/scripts/
├── core/
│   ├── config.tcl       # Configuration globale
│   ├── database.tcl     # Gestion base de données
│   ├── cache.tcl        # Système de cache
│   └── api.tcl          # API interfaces
├── modules/
│   ├── request.tcl      # Gestion requêtes
│   ├── notify.tcl       # Système notifications
│   ├── stats.tcl        # Statistiques & métriques
│   └── admin.tcl        # Interface admin
├── hooks/
│   ├── glftpd.tcl       # Hooks glFTPd
│   ├── pzs-ng.tcl       # Intégration pzs-ng
│   └── events.tcl       # Event handlers
└── utils/
    ├── format.tcl       # Formatage output
    ├── validate.tcl     # Validation input
    ├── security.tcl     # Sécurité
    └── helpers.tcl      # Fonctions utilitaires
```

### 1.2 Core System
```tcl
namespace eval ::turrequest {
    # Configuration Système
    variable config
    array set config {
        version     "2.0.0"
        encoding    "utf-8"
        debug      0
        cache_size 1000
    }

    # Initialisation
    proc init {} {
        variable config
        
        # Load core modules
        source [file join $::scripts_dir "core/database.tcl"]
        source [file join $::scripts_dir "core/cache.tcl"]
        source [file join $::scripts_dir "core/api.tcl"]
        
        # Initialize subsystems
        ::turrequest::db::init
        ::turrequest::cache::init
        ::turrequest::api::init
        
        # Load modules
        foreach module {request notify stats admin} {
            source [file join $::scripts_dir "modules/$module.tcl"]
        }
    }
}
```

## 🔄 2. Système de Requêtes

### 2.1 Gestion Requêtes
```tcl
namespace eval ::turrequest::request {
    # Structure Requête
    variable request_template {
        id          ""
        user        ""
        title       ""
        details     ""
        priority    3
        status      "new"
        created     0
        updated     0
        tags        {}
        votes       0
        filled_by   ""
        fill_date   0
    }

    # Création Requête
    proc create {user title args} {
        variable request_template
        
        # Validation
        if {![validate_request $title]} {
            return -code error "Invalid request format"
        }
        
        # Rate limiting
        if {[rate_limit_exceeded $user]} {
            return -code error "Rate limit exceeded"
        }
        
        # Create request
        set request [dict create {*}$request_template]
        dict set request id [generate_id]
        dict set request user $user
        dict set request title $title
        dict set request created [clock seconds]
        
        # Optional args
        foreach {key value} $args {
            dict set request $key $value
        }
        
        # Save & notify
        save_request $request
        notify_new_request $request
        
        return [dict get $request id]
    }
}
```

### 2.2 Cache System
```tcl
namespace eval ::turrequest::cache {
    # Cache Configuration
    variable cache
    array set cache {
        max_size    1000
        ttl         3600
        hits        0
        misses      0
    }

    # LRU Cache Implementation
    proc get_cached {key} {
        variable cache
        
        if {[dict exists $cache(data) $key]} {
            incr cache(hits)
            set entry [dict get $cache(data) $key]
            
            if {[is_valid $entry]} {
                return [dict get $entry value]
            }
            
            # Expired
            dict unset cache(data) $key
        }
        
        incr cache(misses)
        return ""
    }
}
```

## 📊 3. Performance Optimizations

### 3.1 Memory Management
```tcl
namespace eval ::turrequest::optimize {
    # Memory Pool
    variable mem_pool
    array set mem_pool {
        max_size    "50MB"
        chunks      {}
        free_list   {}
    }

    # Efficient String Handling
    proc string_pool {str} {
        variable string_cache
        
        if {![info exists string_cache($str)]} {
            set string_cache($str) $str
        }
        
        return $string_cache($str)
    }

    # Resource Cleanup
    proc cleanup {} {
        variable mem_pool
        variable string_cache
        
        # Cleanup unused memory
        foreach chunk $mem_pool(free_list) {
            unset mem_pool(chunks,$chunk)
        }
        
        # Clear string cache
        if {[array size string_cache] > 10000} {
            array unset string_cache
        }
    }
}
```

### 3.2 Event Processing
```tcl
namespace eval ::turrequest::events {
    # Event Queue
    variable event_queue
    array set event_queue {
        max_size    5000
        workers     4
        batch_size  100
    }

    # Async Processing
    proc process_events {} {
        variable event_queue
        
        while {[llength $event_queue(pending)]} {
            set batch [lrange $event_queue(pending) 0 $event_queue(batch_size)]
            set event_queue(pending) [lrange $event_queue(pending) $event_queue(batch_size) end]
            
            parallel_process $batch
        }
    }
}
```

## 🔌 4. Intégrations

### 4.1 glFTPd Hooks
```tcl
namespace eval ::turrequest::glftpd {
    # Hook Points
    variable hooks
    array set hooks {
        pre_request  {}
        post_request {}
        fill_request {}
        wipe_request {}
    }

    # Event Handlers
    proc handle_pre_request {request} {
        # Validation & preprocessing
        foreach hook $hooks(pre_request) {
            if {[catch {$hook $request} result]} {
                log_error "Pre-request hook failed: $result"
                return 0
            }
        }
        return 1
    }
}
```

### 4.2 pzs-ng Integration
```tcl
namespace eval ::turrequest::pzsng {
    # Race Detection
    proc check_race {release} {
        set requests [get_active_requests]
        
        foreach request $requests {
            if {[match_pattern $release [dict get $request title]]} {
                handle_match $request $release
            }
        }
    }

    # Auto-Fill
    proc handle_match {request release} {
        if {[validate_release $release]} {
            auto_fill_request $request $release
            notify_fill $request
            update_stats $request
        }
    }
}
```

## 🔐 5. Sécurité

### 5.1 Input Validation
```tcl
namespace eval ::turrequest::security {
    # Validation Rules
    variable rules
    array set rules {
        title_max   100
        desc_max    1000
        tags_max    10
        blacklist   {
            rm -rf
            sudo
            eval
        }
    }

    # Sanitization
    proc sanitize_input {input} {
        # Remove dangerous characters
        set safe [regsub -all {\[|\]|\{|\}|\$|\[|\]|\\|\|} $input ""]
        
        # Check blacklist
        foreach term $rules(blacklist) {
            if {[string first $term $safe] != -1} {
                return -code error "Invalid input"
            }
        }
        
        return $safe
    }
}
```

### 5.2 Access Control
```tcl
namespace eval ::turrequest::acl {
    # Permission System
    variable permissions
    array set permissions {
        admin   {create delete modify view}
        mod     {create modify view}
        user    {create view}
    }

    # Check Permissions
    proc check_access {user action resource} {
        set role [get_user_role $user]
        
        if {![info exists permissions($role)]} {
            return 0
        }
        
        return [expr {$action in $permissions($role)}]
    }
}
```