# 🚄 Intégration pzs-ng Tur-Request

## 📋 1. Architecture

### 1.1 Structure Hooks
```tcl
/scripts/hooks/
├── pzs-ng/
│   ├── pre.tcl         # Pre-hooks (PRE_*)
│   ├── post.tcl        # Post-hooks (COMPLETE_*)
│   ├── race.tcl        # Race hooks (RACE_*)
│   └── wipe.tcl        # Wipe hooks (WIPE_*)
├── events/
│   ├── race.tcl        # Événements race
│   ├── complete.tcl    # Événements complete
│   └── wipe.tcl        # Événements wipe
└── utils/
    ├── match.tcl       # Pattern matching
    ├── parse.tcl       # Parsing release
    └── format.tcl      # Formatage output
```

### 1.2 Points d'Intégration
```yaml
Hook Points:
  PRE_HOOK:
    - PRE_RACE_START
    - PRE_RACE_DATA
    - PRE_COMPLETE
  
  RACE_HOOK:
    - RACE_DATA
    - RACE_STATUS
    - RACE_UPDATE
  
  POST_HOOK:
    - COMPLETE_RACE
    - COMPLETE_STAT
    - POST_CHECK
  
  WIPE_HOOK:
    - PRE_WIPE
    - WIPE_DATA
    - POST_WIPE
```

## 🔄 2. Système Race

### 2.1 Détection Race
```tcl
namespace eval ::turrequest::pzsng::race {
    # Configuration Race
    variable race_config
    array set race_config {
        min_files   1
        min_size    "10MB"
        max_time    3600
        patterns    {
            VIDEO   {*.mkv *.mp4 *.avi}
            AUDIO   {*.mp3 *.flac *.m4a}
            ARCHIVE {*.rar *.zip *.7z}
        }
    }

    # Race Handler
    proc handle_race {release_data} {
        # Validation release
        if {![validate_release $release_data]} {
            return 0
        }
        
        # Check patterns
        set type [detect_release_type $release_data]
        if {$type eq ""} {
            return 0
        }
        
        # Process race
        process_race $release_data $type
        return 1
    }

    # Pattern Matching
    proc match_request_pattern {release request} {
        set release_name [dict get $release name]
        set request_pattern [dict get $request title]
        
        # Pattern matching rules
        if {[regexp -nocase $request_pattern $release_name]} {
            return 1
        }
        
        # Check tags
        foreach tag [dict get $request tags] {
            if {[string match -nocase "*${tag}*" $release_name]} {
                return 1
            }
        }
        
        return 0
    }
}
```

### 2.2 Auto-Fill System
```tcl
namespace eval ::turrequest::pzsng::autofill {
    # Auto-Fill Config
    variable config
    array set config {
        enabled     1
        max_match   3
        threshold   0.8
        timeout     300
    }

    # Auto-Fill Handler
    proc handle_complete {release} {
        variable config
        
        if {!$config(enabled)} {
            return 0
        }
        
        # Get matching requests
        set matches [find_matching_requests $release]
        
        # Process matches
        foreach match $matches {
            if {[verify_match $match $release]} {
                fill_request $match $release
                notify_fill $match $release
                update_stats $match
            }
        }
    }

    # Match Verification
    proc verify_match {request release} {
        # Size check
        if {![verify_size $request $release]} {
            return 0
        }
        
        # Quality check
        if {![verify_quality $request $release]} {
            return 0
        }
        
        # Format check
        if {![verify_format $request $release]} {
            return 0
        }
        
        return 1
    }
}
```

## 📊 3. Statistiques Race

### 3.1 Collecte Stats
```tcl
namespace eval ::turrequest::pzsng::stats {
    # Stats Types
    variable stats
    array set stats {
        races       0
        releases    0
        filled      0
        failed      0
        size        0
        files       0
    }

    # Collection
    proc collect_race_stats {race_data} {
        variable stats
        
        # Update counters
        incr stats(races)
        incr stats(releases)
        
        # Size stats
        incr stats(size) [dict get $race_data size]
        incr stats(files) [dict get $race_data files]
        
        # Export stats
        export_race_stats
    }

    # Export Stats
    proc export_race_stats {} {
        variable stats
        
        # Format for Prometheus
        foreach {key value} [array get stats] {
            puts "turrequest_pzsng_${key}_total $value"
        }
    }
}
```

### 3.2 Performance Metrics
```tcl
namespace eval ::turrequest::pzsng::metrics {
    # Metrics Config
    variable metrics
    array set metrics {
        processing_time 0
        match_rate     0
        fill_rate      0
        error_rate     0
    }

    # Performance Tracking
    proc track_performance {type data} {
        variable metrics
        set start [clock milliseconds]
        
        # Process data
        if {[catch {
            process_data $type $data
        } result]} {
            incr metrics(error_rate)
        }
        
        # Update metrics
        set duration [expr {[clock milliseconds] - $start}]
        set metrics(processing_time) [expr {
            ($metrics(processing_time) + $duration) / 2
        }]
        
        # Export metrics
        export_performance_metrics
    }
}
```

## 🔌 4. Intégration Système

### 4.1 Event Handlers
```tcl
namespace eval ::turrequest::pzsng::events {
    # Event Types
    variable events
    array set events {
        RACE_START  "Début race"
        RACE_DATA   "Données race"
        RACE_CLOSE  "Fin race"
        COMPLETE    "Complete"
        ERROR      "Erreur"
    }

    # Event Processing
    proc process_event {type data} {
        variable events
        
        switch -exact -- $type {
            "RACE_START" {
                handle_race_start $data
                notify_race_start $data
            }
            "RACE_DATA" {
                update_race_data $data
                check_requests $data
            }
            "RACE_CLOSE" {
                finalize_race $data
                cleanup_race $data
            }
            "COMPLETE" {
                handle_complete $data
                process_autofill $data
            }
            "ERROR" {
                log_error $data
                notify_error $data
            }
        }
    }
}
```

### 4.2 Système Notification
```tcl
namespace eval ::turrequest::pzsng::notify {
    # Notification Config
    variable config
    array set config {
        channels    {#requests #races}
        formats     {
            RACE     "\00304⚡\003 %s"
            COMPLETE "\00303✓\003 %s"
            ERROR    "\00305❌\003 %s"
        }
    }

    # Formatage Messages
    proc format_race_message {type data} {
        variable config
        
        set template [dict get $config formats $type]
        set message [format_data $data]
        
        return [format $template $message]
    }

    # Notification Handler
    proc send_notification {type data} {
        variable config
        
        set message [format_race_message $type $data]
        foreach channel $config(channels) {
            putserv "PRIVMSG $channel :$message"
        }
    }
}
```

## 🔐 5. Sécurité & Validation

### 5.1 Validation Release
```tcl
namespace eval ::turrequest::pzsng::validate {
    # Validation Rules
    variable rules
    array set rules {
        min_size    "10MB"
        max_size    "100GB"
        formats     {
            VIDEO   {*.mkv *.mp4}
            AUDIO   {*.mp3 *.flac}
            ARCHIVE {*.rar *.zip}
        }
        excluded    {
            DIRS    {sample proof}
            FILES   {*.nfo *.sfv}
        }
    }

    # Release Validation
    proc validate_release {release} {
        variable rules
        
        # Size check
        if {![check_size $release $rules(min_size) $rules(max_size)]} {
            return 0
        }
        
        # Format check
        if {![check_format $release $rules(formats)]} {
            return 0
        }
        
        # Exclusion check
        if {[is_excluded $release $rules(excluded)]} {
            return 0
        }
        
        return 1
    }
}
```

### 5.2 Sécurité Système
```tcl
namespace eval ::turrequest::pzsng::security {
    # Security Config
    variable config
    array set config {
        max_processes 10
        timeout       30
        max_retries   3
        safe_paths    {
            "/site/incoming"
            "/site/requests"
        }
    }

    # Path Security
    proc verify_path {path} {
        variable config
        
        # Check safe paths
        set safe 0
        foreach safe_path $config(safe_paths) {
            if {[string match "${safe_path}*" $path]} {
                set safe 1
                break
            }
        }
        
        return $safe
    }

    # Process Security
    proc secure_operation {operation data} {
        variable config
        
        # Resource limits
        if {[get_process_count] >= $config(max_processes)} {
            return 0
        }
        
        # Timeout handling
        after $config(timeout) {
            if {![info exists ::operation_complete]} {
                abort_operation $operation
            }
        }
        
        return 1
    }
}
``` 