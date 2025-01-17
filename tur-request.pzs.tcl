###############################################################################
# Tur-Request v2.0.0 - Module pzs-ng
###############################################################################

namespace eval ::turrequest::pzs {
    # Variables globales
    variable config
    variable cache
    array set cache {}
    
    # Initialisation
    proc init {} {
        variable config
        
        # Configuration par défaut
        array set config {
            enabled     1
            auto_fill   1
            match_score 0.8
            exclude_dirs {
                sample
                proof
                covers
                subs
            }
        }
        
        # Chargement hooks
        if {$config(enabled)} {
            bind PRE_HOOK * * ::turrequest::pzs::pre_hook
            bind RACE_HOOK * * ::turrequest::pzs::race_hook
            bind POST_HOOK * * ::turrequest::pzs::post_hook
            bind WIPE_HOOK * * ::turrequest::pzs::wipe_hook
            putlog "Tur-Request: Hooks pzs-ng activés"
        }
    }
    
    # Hook pré-upload
    proc pre_hook {event section file} {
        variable config
        if {!$config(enabled)} return
        
        # Vérification dossier exclu
        foreach dir $config(exclude_dirs) {
            if {[string match -nocase "*/$dir/*" $file]} {
                return
            }
        }
        
        # Cache du fichier
        set cache($file) [list \
            event $event \
            section $section \
            time [clock seconds] \
        ]
    }
    
    # Hook race
    proc race_hook {event section file data} {
        variable config
        if {!$config(enabled)} return
        
        # Vérification auto-fill
        if {!$config(auto_fill)} return
        
        # Vérification dossier exclu
        foreach dir $config(exclude_dirs) {
            if {[string match -nocase "*/$dir/*" $file]} {
                return
            }
        }
        
        # Extraction infos race
        array set race $data
        if {![info exists race(release)]} return
        
        # Recherche requêtes correspondantes
        set matches [find_matching_requests $race(release)]
        if {[llength $matches] == 0} return
        
        # Auto-fill
        foreach {id score} $matches {
            if {$score >= $config(match_score)} {
                fill_request $id $file $race(user)
            }
        }
    }
    
    # Hook post-upload
    proc post_hook {event section file data} {
        variable config
        if {!$config(enabled)} return
        
        # Nettoyage cache
        if {[info exists cache($file)]} {
            unset cache($file)
        }
    }
    
    # Hook wipe
    proc wipe_hook {event section file} {
        variable config
        if {!$config(enabled)} return
        
        # Annulation auto-fill si release wipe
        set reqs [db eval {
            SELECT id FROM requests
            WHERE status = 'filled'
            AND fill_path LIKE '%' || $file || '%'
        }]
        
        foreach id $reqs {
            cancel_fill $id "Release wipe: $file"
        }
    }
    
    # Recherche requêtes correspondantes
    proc find_matching_requests {release} {
        # Récupération requêtes en attente
        set reqs [db eval {
            SELECT id, title, details
            FROM requests
            WHERE status = 'pending'
        }]
        
        set matches {}
        foreach {id title details} $reqs {
            # Calcul score correspondance
            set score [match_score $release $title $details]
            if {$score > 0} {
                lappend matches $id $score
            }
        }
        
        # Tri par score décroissant
        set matches [lsort -decreasing -index 1 -real $matches]
        return $matches
    }
    
    # Calcul score correspondance
    proc match_score {release title details} {
        # Normalisation
        set release [string tolower $release]
        set title [string tolower $title]
        set details [string tolower $details]
        
        # Score initial
        set score 0.0
        
        # Correspondance exacte titre
        if {[string equal $release $title]} {
            return 1.0
        }
        
        # Correspondance partielle titre
        if {[string first $title $release] != -1} {
            set score 0.8
        } elseif {[string first $release $title] != -1} {
            set score 0.6
        }
        
        # Bonus mots communs
        set release_words [split [regsub -all {[^[:alnum:]]} $release " "] " "]
        set title_words [split [regsub -all {[^[:alnum:]]} $title " "] " "]
        set details_words [split [regsub -all {[^[:alnum:]]} $details " "] " "]
        
        set common_words 0
        foreach word $release_words {
            if {$word eq ""} continue
            if {[lsearch -exact $title_words $word] != -1} {
                incr common_words
            } elseif {[lsearch -exact $details_words $word] != -1} {
                incr common_words
            }
        }
        
        # Bonus basé sur nombre mots communs
        if {[llength $release_words] > 0} {
            set word_score [expr {double($common_words) / [llength $release_words]}]
            set score [expr {$score + $word_score * 0.4}]
        }
        
        # Score final entre 0 et 1
        return [expr {$score > 1.0 ? 1.0 : $score}]
    }
    
    # Remplissage requête
    proc fill_request {id path user} {
        # Vérification requête
        set req [db eval {
            SELECT user as requester, title
            FROM requests
            WHERE id = $id
            AND status = 'pending'
        }]
        if {[llength $req] == 0} return
        
        array set r $req
        
        # Mise à jour requête
        set now [clock seconds]
        db eval {
            UPDATE requests SET
                status = 'filled',
                filler = $user,
                fill_path = $path,
                filled = $now
            WHERE id = $id
        }
        
        # Points
        ::turrequest::points::add $user $::turrequest::points(fill)
        
        # Notification
        putserv "PRIVMSG $::turrequest::request_chan :[format $::turrequest::format(filled) \
            id $id title $r(title) filler $user path $path]"
        
        putlog "Tur-Request: Auto-fill requête #$id par $user avec $path"
    }
    
    # Annulation remplissage
    proc cancel_fill {id reason} {
        # Mise à jour requête
        db eval {
            UPDATE requests SET
                status = 'pending',
                filler = NULL,
                fill_path = NULL,
                filled = NULL
            WHERE id = $id
        }
        
        putlog "Tur-Request: Annulation fill requête #$id - $reason"
    }
}

# Initialisation module
::turrequest::pzs::init

putlog "Tur-Request: Module pzs-ng chargé" 