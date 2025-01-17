# 🤖 Configuration Eggdrop

## 📋 Installation & Setup

### 1. Prérequis
```bash
# Dépendances
- tcl8.6
- tcl8.6-dev
- openssl
- libssl-dev
- build-essential

# Structure
/glftpd/sitebot/
├── eggdrop.conf
├── scripts/
├── logs/
└── modules/
```

### 2. Compilation
```bash
# Configuration
./configure \
  --with-tclinc=/usr/include/tcl8.6 \
  --with-tcllib=/usr/lib/tcl8.6 \
  --with-ssl

# Installation
make config
make
make install
```

## 🔧 Configuration Core

### 1. eggdrop.conf
```tcl
# Bot Settings
set nick "SiteBot"
set altnick "SiteBot_"
set realname "Site Bot"
set username "sitebot"

# Server Settings
set servers {
    irc.server.net:6667
    irc.backup.net:6667
}

# Channel Settings
set channels {
    "#site"
    "#site-staff"
    "#site-announce"
}

# Security
set ssl-verify-server 1
set ssl-certificate "eggdrop.crt"
set ssl-private-key "eggdrop.key"
```

### 2. User Settings
```tcl
# User Flags
set user-flags {
    n - Owner
    m - Master
    o - Op
    v - Voice
    f - Friend
}

# Access Levels
set access-levels {
    owner   500
    master  400
    op      100
    voice    50
    friend   10
}
```

## 🛠 Scripts & Modules

### 1. Core Scripts
```tcl
# Script Loading
source scripts/core/config.tcl
source scripts/core/utils.tcl
source scripts/core/database.tcl

# Module Loading
loadmodule blowfish
loadmodule dns
loadmodule channels
loadmodule irc
```

### 2. Site Scripts
```tcl
# Site Integration
source scripts/site/announce.tcl
source scripts/site/stats.tcl
source scripts/site/commands.tcl

# Custom Modules
loadmodule sitecmds
loadmodule statstracker
loadmodule racetools
```

## 📊 Commandes & Events

### 1. Command Bindings
```tcl
# Public Commands
bind pub - !site pub:site_command
bind pub - !user pub:user_command
bind pub - !stats pub:stats_command

# Private Commands
bind msg - auth msg:auth_command
bind msg - help msg:help_command
bind msg - status msg:status_command
```

### 2. Event Handlers
```tcl
# Event Processing
bind join - * join:handler
bind part - * part:handler
bind sign - * sign:handler
bind nick - * nick:handler

# Site Events
bind evnt - UPLOAD evnt:upload_handler
bind evnt - COMPLETE evnt:complete_handler
bind evnt - RACE evnt:race_handler
```

## 🔐 Sécurité

### 1. Authentication
```tcl
# Auth Methods
set auth-methods {
    password    "Standard password auth"
    cert        "SSL certificate auth"
    otp         "One-time password"
}

# Auth Settings
set auth-timeout 300
set auth-attempts 3
set auth-lockout 1800
```

### 2. Access Control
```tcl
# Channel Security
set channel-security {
    "#site" {
        flags "tn"
        autoop 1
        autovoice 1
        flood "5:10"
    }
    "#site-staff" {
        flags "n"
        invite-only 1
        secret 1
    }
}

# Command Security
set command-security {
    site    "m"
    user    "o"
    stats   "v"
}
```

## 📈 Monitoring & Logs

### 1. Log Configuration
```tcl
# Log Settings
logfile mco * "logs/eggdrop.log"
logfile jpk #site "logs/site.log"
logfile mco #site-staff "logs/staff.log"

# Log Format
set log-format {
    timestamp   "%Y-%m-%d %H:%M:%S"
    level       "[%s]"
    channel     "(%s)"
    message     "%s"
}
```

### 2. Monitoring
```tcl
# Performance
set monitor-settings {
    memory-limit    "50MB"
    cpu-limit       "25%"
    script-timeout  "30"
}

# Health Checks
set health-checks {
    irc-connection 60
    script-status  300
    bot-response   10
}
```

## 🔄 Maintenance

### 1. Backup
```tcl
# Backup Settings
set backup {
    userfile    86400
    channelfile 86400
    configfile  604800
}

# Backup Location
set backup-path "/glftpd/backup/sitebot/"
set backup-compress 1
set backup-rotate 5
```

### 2. Maintenance
```tcl
# Auto Maintenance
set maintenance {
    userfile-check  604800
    channel-check   86400
    script-reload   604800
}

# Cleanup
set cleanup {
    temp-files  604800
    old-logs    2592000
    seen-data   7776000
}
```

## 📝 Notifications

### 1. Announce Templates
```tcl
# Release Templates
set announce-templates {
    new     "NOUVEAU: %s - Par: %s - Dans: %s"
    complete "COMPLETE: %s - Temps: %s - Vitesse: %s"
    race    "RACE: %s - %d fichiers - %d groupes"
}

# Staff Templates
set staff-templates {
    alert   "ALERTE: %s"
    warning "ATTENTION: %s"
    info    "INFO: %s"
}
```

### 2. Notification Rules
```tcl
# Channel Rules
set notify-rules {
    "#site" {
        new      1
        complete 1
        race     1
    }
    "#site-staff" {
        alert    1
        warning  1
        info     1
    }
}

# Filters
set notify-filters {
    size     ">100MB"
    priority ">1"
    type     "RELEASE|SAMPLE|PROOF"
}
```

## 🔍 Debug & Testing

### 1. Debug Mode
```tcl
# Debug Settings
set debug-settings {
    level       4
    channels    "#site-debug"
    log-file    "debug.log"
    timestamps  1
}

# Debug Commands
set debug-commands {
    .debug     "Toggle debug mode"
    .trace     "Script tracing"
    .meminfo   "Memory usage"
    .status    "Bot status"
}
```

### 2. Testing
```tcl
# Test Suite
set test-suite {
    commands    "Test all commands"
    events      "Test event handlers"
    security    "Test security features"
    performance "Test bot performance"
}

# Test Output
set test-output {
    console 1
    log     1
    channel "#site-debug"
}
``` 