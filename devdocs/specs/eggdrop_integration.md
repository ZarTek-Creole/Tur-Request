# 🤖 Intégration Eggdrop Tur-Request

## 📋 1. Architecture Bot

### 1.1 Structure Scripts
```tcl
/scripts/bot/
├── core/
│   ├── init.tcl        # Initialisation bot
│   ├── commands.tcl    # Gestionnaire commandes
│   └── events.tcl      # Gestionnaire événements
├── commands/
│   ├── request.tcl     # Commandes requêtes
│   ├── admin.tcl       # Commandes admin
│   ├── search.tcl      # Recherche requêtes
│   └── stats.tcl       # Statistiques
└── modules/
    ├── format.tcl      # Formatage messages
    ├── notify.tcl      # Notifications
    └── auth.tcl        # Authentification
```

### 1.2 Core System
```tcl
namespace eval ::turrequest::bot {
    # Configuration Bot
    variable config
    array set config {
        version      "2.0.0"
        channels    {#requests #announce}
        prefix      "!"
        colors      1
        flood_prot  1
    }

    # Initialisation
    proc init {} {
        variable config
        
        # Load core modules
        source [file join $::bot_scripts "core/commands.tcl"]
        source [file join $::bot_scripts "core/events.tcl"]
        
        # Load command modules
        foreach module {request admin search stats} {
            source [file join $::bot_scripts "commands/$module.tcl"]
        }
        
        # Initialize handlers
        ::turrequest::bot::commands::init
        ::turrequest::bot::events::init
        
        putlog "Tur-Request Bot v$config(version) initialized"
    }
}
```

## 🎯 2. Commandes IRC

### 2.1 Commandes Requêtes
```tcl
namespace eval ::turrequest::bot::commands::request {
    # Liste Commandes
    variable commands
    array set commands {
        request     "Créer une requête"
        fill       "Remplir une requête"
        cancel     "Annuler une requête"
        info       "Info sur une requête"
        list       "Liste des requêtes"
        search     "Rechercher requêtes"
    }

    # Handler Commandes
    proc handle_request {nick host hand chan text} {
        set args [split $text]
        set cmd [lindex $args 0]
        set params [lrange $args 1 end]
        
        switch -exact -- $cmd {
            "new"    { create_request $nick $params }
            "fill"   { fill_request $nick $params }
            "cancel" { cancel_request $nick $params }
            "info"   { request_info $nick $params }
            "list"   { list_requests $nick $params }
            "search" { search_requests $nick $params }
            default  { show_help $nick $cmd }
        }
    }

    # Création Requête
    proc create_request {nick params} {
        # Validation
        if {[llength $params] < 1} {
            send_notice $nick "Usage: !request new <title> \[details\]"
            return
        }
        
        set title [lindex $params 0]
        set details [join [lrange $params 1 end]]
        
        if {[catch {
            set id [::turrequest::request::create $nick $title details $details]
            send_notice $nick "Requête créée avec ID: $id"
            announce_request $id
        } error]} {
            send_notice $nick "Erreur: $error"
        }
    }
}
```

### 2.2 Commandes Admin
```tcl
namespace eval ::turrequest::bot::commands::admin {
    # Commandes Admin
    variable admin_commands
    array set admin_commands {
        adduser     "Ajouter utilisateur"
        deluser     "Supprimer utilisateur"
        setflags    "Modifier flags"
        reload      "Recharger config"
        cleanup     "Nettoyage système"
    }

    # Handler Admin
    proc handle_admin {nick host hand chan text} {
        # Vérification permissions
        if {![is_admin $nick]} {
            send_notice $nick "Permission refusée"
            return
        }
        
        set args [split $text]
        set cmd [lindex $args 0]
        set params [lrange $args 1 end]
        
        switch -exact -- $cmd {
            "adduser"  { add_user $nick $params }
            "deluser"  { del_user $nick $params }
            "setflags" { set_flags $nick $params }
            "reload"   { reload_config $nick }
            "cleanup"  { system_cleanup $nick }
            default    { show_admin_help $nick }
        }
    }
}
```

## 📢 3. Système Notifications

### 3.1 Event Handlers
```tcl
namespace eval ::turrequest::bot::events {
    # Event Types
    variable events
    array set events {
        REQUEST_NEW     "Nouvelle requête"
        REQUEST_FILL    "Requête remplie"
        REQUEST_CANCEL  "Requête annulée"
        SYSTEM_ALERT    "Alerte système"
    }

    # Event Processing
    proc process_event {type data} {
        variable events
        
        switch -exact -- $type {
            "REQUEST_NEW"    { announce_new_request $data }
            "REQUEST_FILL"   { announce_fill $data }
            "REQUEST_CANCEL" { announce_cancel $data }
            "SYSTEM_ALERT"   { broadcast_alert $data }
        }
    }

    # Formatage Messages
    proc format_message {type data} {
        switch -exact -- $type {
            "REQUEST_NEW" {
                return "\002\00303Nouvelle Requête\003\002 ID: [dict get $data id] - \
                       Par: [dict get $data user] - [dict get $data title]"
            }
            "REQUEST_FILL" {
                return "\002\00307Requête Remplie\003\002 ID: [dict get $data id] - \
                       Par: [dict get $data filled_by]"
            }
        }
    }
}
```

### 3.2 Notification System
```tcl
namespace eval ::turrequest::bot::notify {
    # Configuration
    variable config
    array set config {
        channels    {#requests #announce}
        highlights  1
        colors     1
        batch_size 5
    }

    # Notification Queue
    proc queue_notification {type data {priority 0}} {
        variable notify_queue
        
        set notification [dict create \
            type $type \
            data $data \
            priority $priority \
            timestamp [clock seconds] \
        ]
        
        lappend notify_queue $notification
        process_queue
    }

    # Queue Processing
    proc process_queue {} {
        variable notify_queue
        variable config
        
        # Sort by priority
        set notify_queue [lsort -decreasing -index priority $notify_queue]
        
        # Process batch
        set batch [lrange $notify_queue 0 $config(batch_size)]
        foreach notification $batch {
            send_notification $notification
        }
        
        # Update queue
        set notify_queue [lrange $notify_queue $config(batch_size) end]
    }
}
```

## 🔐 4. Sécurité

### 4.1 Authentication
```tcl
namespace eval ::turrequest::bot::auth {
    # Auth Configuration
    variable auth_config
    array set auth_config {
        method      "hostmask"
        cache_time  3600
        max_fails   3
        ban_time    1800
    }

    # User Authentication
    proc authenticate {nick host hand} {
        variable auth_config
        
        # Check cache
        if {[is_cached $nick]} {
            return [get_cached_auth $nick]
        }
        
        # Verify auth
        switch -exact -- $auth_config(method) {
            "hostmask" { set result [check_hostmask $nick $host] }
            "account"  { set result [check_account $nick] }
            default   { set result 0 }
        }
        
        # Cache result
        cache_auth $nick $result
        return $result
    }
}
```

### 4.2 Rate Limiting
```tcl
namespace eval ::turrequest::bot::ratelimit {
    # Rate Limits
    variable limits
    array set limits {
        request     {count 5 period 300}
        search      {count 10 period 60}
        admin      {count 20 period 300}
    }

    # Check Rate Limit
    proc check_limit {nick type} {
        variable limits
        
        if {![info exists limits($type)]} {
            return 1
        }
        
        set count [dict get $limits($type) count]
        set period [dict get $limits($type) period]
        
        if {[get_user_count $nick $type $period] >= $count} {
            return 0
        }
        
        incr_user_count $nick $type
        return 1
    }
}
```

## 📊 5. Monitoring

### 5.1 Stats Collection
```tcl
namespace eval ::turrequest::bot::stats {
    # Metrics
    variable metrics
    array set metrics {
        commands    0
        users      0
        requests   0
        fills      0
        errors     0
    }

    # Collection
    proc collect_metrics {} {
        variable metrics
        
        # Update metrics
        set metrics(users) [llength [userlist]]
        set metrics(requests) [::turrequest::request::count_active]
        
        # Export metrics
        export_prometheus_metrics
    }

    # Prometheus Export
    proc export_prometheus_metrics {} {
        variable metrics
        
        foreach {key value} [array get metrics] {
            puts "turrequest_bot_${key}_total $value"
        }
    }
}
```

### 5.2 Health Checks
```tcl
namespace eval ::turrequest::bot::health {
    # Health Checks
    variable checks
    array set checks {
        connection  {status 1 last_check 0}
        database   {status 1 last_check 0}
        cache      {status 1 last_check 0}
    }

    # System Check
    proc check_health {} {
        variable checks
        
        # Check components
        set checks(connection,status) [check_connection]
        set checks(database,status) [check_database]
        set checks(cache,status) [check_cache]
        
        # Update timestamps
        foreach key [array names checks] {
            set checks($key,last_check) [clock seconds]
        }
        
        return [expr {
            $checks(connection,status) &&
            $checks(database,status) &&
            $checks(cache,status)
        }]
    }
}
```
``` 