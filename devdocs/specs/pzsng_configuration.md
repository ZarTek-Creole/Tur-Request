# 🚄 Configuration pzs-ng

## 📋 Installation & Setup

### 1. Prérequis
```bash
# Dépendances
- gcc
- make
- tcl-dev
- libssl-dev
- zlib1g-dev

# Structure
/glftpd/
└── sitebot/
    ├── modules/
    ├── plugins/
    └── scripts/
```

### 2. Compilation
```bash
# Options de compilation
./configure \
  --with-tcl=/usr/lib \
  --with-tclinclude=/usr/include/tcl \
  --with-storage=/glftpd/ftp-data/pzs-ng \
  --enable-static

# Installation
make
make install
```

## 🔧 Configuration Core

### 1. zsconfig.h
```c
// Base Configuration
#define sitepath            "/glftpd/site"
#define storage             "/glftpd/ftp-data/pzs-ng"
#define site_root          "/glftpd"
#define log                "/glftpd/ftp-data/logs/glftpd.log"

// Features
#define enable_audio_info    TRUE
#define enable_nfo_check     TRUE
#define enable_sfv_check     TRUE
#define enable_zip_clean     TRUE

// Limits
#define max_users_per_race   10
#define max_groups_per_race  5
#define min_release_size     10240
#define max_release_size     0
```

### 2. Race Settings
```yaml
Race Configuration:
  # Timing
  min_race_time: 30
  max_race_time: 3600
  grace_period: 60

  # Requirements
  min_files_per_race: 1
  max_files_per_race: 0
  required_files:
    - ".sfv"
    - ".nfo"
    
  # Scoring
  points_per_file: 1
  points_per_mb: 0.5
  bonus_first_file: 2
  penalty_incomplete: -5
```

## 📊 Stats & Tracking

### 1. Race Stats
```yaml
Stats Collection:
  User Stats:
    - Files uploaded
    - Speed average
    - Race position
    - Points earned

  Group Stats:
    - Total files
    - Total size
    - Race wins
    - Average position

  Release Stats:
    - Completion time
    - Number racers
    - Total size
    - Average speed
```

### 2. Storage Format
```yaml
Database Structure:
  Users:
    - username
    - groupname
    - stats_daily
    - stats_weekly
    - stats_monthly
    - stats_alltime

  Groups:
    - groupname
    - stats_daily
    - stats_weekly
    - stats_monthly
    - stats_alltime

  Releases:
    - release_name
    - section
    - files_total
    - size_total
    - time_start
    - time_complete
```

## 🛠 Hooks & Events

### 1. Pre-Hook Scripts
```bash
# Upload Hooks
pre_check() {
    # Validation SFV
    # Check espace
    # Vérification dupe
}

pre_race() {
    # Initialisation race
    # Création structure
    # Notification début
}
```

### 2. Post-Hook Scripts
```bash
# Complete Hooks
post_complete() {
    # Validation release
    # Calcul stats
    # Annonces
    # Cleanup
}

post_race() {
    # Finalisation race
    # Attribution points
    # Génération stats
    # Notifications
}
```

## 🔍 Validation & Checks

### 1. File Validation
```yaml
Checks:
  SFV:
    - Format check
    - CRC validation
    - File count
    - Naming convention

  NFO:
    - Size check
    - Format check
    - Required fields
    - Encoding

  ZIP:
    - Integrity check
    - Content validation
    - Compression check
    - Password check
```

### 2. Release Rules
```yaml
Rules:
  Structure:
    - Directory naming
    - File organization
    - Required files
    - Forbidden files

  Content:
    - File types
    - Compression
    - Naming patterns
    - Metadata
```

## 📈 Performance

### 1. Optimisation
```yaml
System:
  IO:
    buffer_size: 16MB
    read_ahead: 256KB
    aio_threads: 8
    io_scheduler: "deadline"
  
  Memory:
    cache_size: 256MB
    shared_buffers: 128MB
    temp_buffers: 64MB
    work_mem: 32MB
  
  Network:
    tcp_window: 65536
    tcp_backlog: 2048
    keepalive_time: 60
    max_connections: 1000
  
  Processing:
    thread_pool: 16
    worker_processes: auto
    job_queue_size: 5000
    batch_size: 1000
```

### 2. Monitoring & Metrics
```yaml
Metrics:
  Collection:
    interval: 10s
    retention: 30d
    resolution: 1s
  
  Performance:
    - throughput:
        type: gauge
        labels: [section, user, group]
    - latency:
        type: histogram
        buckets: [10ms, 50ms, 100ms, 500ms]
    - errors:
        type: counter
        labels: [type, source]
    
  Race:
    - active_races:
        type: gauge
        labels: [section]
    - completion_time:
        type: histogram
        buckets: [30s, 1m, 5m, 10m]
    - transfer_speed:
        type: gauge
        labels: [user, group]
```

## 🔐 Sécurité

### 1. Access Control
```yaml
Permissions:
  Users:
    - Upload rights
    - Race participation
    - Stats access
    - Command usage

  Groups:
    - Section access
    - Race priority
    - Bonus points
    - Special rights
```

### 2. Validation
```yaml
Security:
  Input:
    - Path validation
    - Command sanitization
    - Parameter checking
    - Size limits

  Process:
    - Resource limits
    - Timeout handling
    - Error recovery
    - Logging
```

## 📝 Logging & Debug

### 1. Log Configuration
```yaml
Log Settings:
  Files:
    - race.log
    - error.log
    - debug.log
    - stats.log

  Format:
    - Timestamp
    - Event type
    - Details
    - Source
```

### 2. Debug Options
```yaml
Debug:
  Levels:
    1: Errors only
    2: Warnings
    3: Info
    4: Debug
    5: Trace

  Output:
    - Console
    - File
    - Syslog
    - Bot
``` 