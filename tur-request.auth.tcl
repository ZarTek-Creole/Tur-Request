###############################################################################
# Tur-Request v2.0.0 - Module Authentification glFTPd
###############################################################################

namespace eval ::turrequest::auth {
    # Variables globales
    variable glconf
    variable users
    array set users {}
    
    # Chargement configuration glFTPd
    proc load_glftpd_conf {} {
        variable glconf
        
        set conf_file [file join $::turrequest::glroot "etc/glftpd.conf"]
        if {![file exists $conf_file]} {
            putlog "Erreur: glftpd.conf non trouvé dans $conf_file"
            return 0
        }
        
        set fd [open $conf_file r]
        set data [read $fd]
        close $fd
        
        array set glconf {}
        foreach line [split $data \n] {
            set line [string trim $line]
            if {$line eq "" || [string index $line 0] eq "#"} continue
            
            set parts [split $line]
            set key [string tolower [lindex $parts 0]]
            set val [join [lrange $parts 1 end]]
            set glconf($key) $val
        }
        
        return 1
    }
    
    # Chargement utilisateur glFTPd
    proc load_user {username} {
        variable users
        
        set passwd_file [file join $::turrequest::glroot "etc/passwd"]
        if {![file exists $passwd_file]} {
            putlog "Erreur: passwd non trouvé dans $passwd_file"
            return 0
        }
        
        set fd [open $passwd_file r]
        set found 0
        while {[gets $fd line] >= 0} {
            set line [string trim $line]
            if {$line eq "" || [string index $line 0] eq "#"} continue
            
            set parts [split $line :]
            if {[llength $parts] < 7} continue
            
            set name [lindex $parts 0]
            if {[string equal -nocase $name $username]} {
                array set users [list \
                    $username [list \
                        uid [lindex $parts 2] \
                        gid [lindex $parts 3] \
                        flags [lindex $parts 6] \
                        homedir [lindex $parts 5] \
                        groups {} \
                    ] \
                ]
                set found 1
                break
            }
        }
        close $fd
        
        if {!$found} {
            return 0
        }
        
        # Chargement groupes
        set group_file [file join $::turrequest::glroot "etc/group"]
        if {[file exists $group_file]} {
            set fd [open $group_file r]
            while {[gets $fd line] >= 0} {
                set line [string trim $line]
                if {$line eq "" || [string index $line 0] eq "#"} continue
                
                set parts [split $line :]
                if {[llength $parts] < 4} continue
                
                set group_name [lindex $parts 0]
                set members [split [lindex $parts 3] ,]
                
                if {[lsearch -nocase $members $username] != -1} {
                    lappend users($username,groups) $group_name
                }
            }
            close $fd
        }
        
        return 1
    }
    
    # Vérification utilisateur
    proc check_user {username} {
        variable users
        
        # Chargement utilisateur si pas en cache
        if {![info exists users($username)]} {
            if {![load_user $username]} {
                return 0
            }
        }
        
        return 1
    }
    
    # Obtenir groupes utilisateur
    proc get_groups {username} {
        variable users
        
        if {![check_user $username]} {
            return {}
        }
        
        return $users($username,groups)
    }
    
    # Vérifier appartenance groupe
    proc is_in_group {username group} {
        set groups [get_groups $username]
        return [expr {[lsearch -nocase $groups $group] != -1}]
    }
    
    # Vérifier flags utilisateur
    proc has_flags {username flags} {
        variable users
        
        if {![check_user $username]} {
            return 0
        }
        
        foreach flag [split $flags ""] {
            if {[string first $flag $users($username,flags)] == -1} {
                return 0
            }
        }
        return 1
    }
    
    # Obtenir home directory
    proc get_home {username} {
        variable users
        
        if {![check_user $username]} {
            return ""
        }
        
        return $users($username,homedir)
    }
    
    # Vérifier crédits
    proc check_credits {username section} {
        variable glconf
        
        # TODO: Implémenter vérification crédits
        return 1
    }
    
    # Vérifier ratio
    proc check_ratio {username} {
        variable glconf
        
        # TODO: Implémenter vérification ratio
        return 1
    }
    
    # Vérifier permissions
    proc check_perms {username path {write 0}} {
        variable glconf
        
        # TODO: Implémenter vérification permissions
        return 1
    }
}

# Chargement configuration glFTPd
if {![::turrequest::auth::load_glftpd_conf]} {
    putlog "Erreur: Impossible de charger la configuration glFTPd"
}

putlog "Tur-Request: Module Auth chargé"
