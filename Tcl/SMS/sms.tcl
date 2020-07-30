# ---------------------------------------------------------------------------
# 0. EEM Script
# ---------------------------------------------------------------------------
::cisco::eem::event_register_syslog pattern "New SMS received" 

namespace import ::cisco::eem::*
namespace import ::cisco::lib::*

# ---------------------------------------------------------------------------
# 1. Procedures
# ---------------------------------------------------------------------------
proc CLIProc {clifd cmds} {
    global errorInfo cmd_output
    foreach a_cmd $cmds {
        if [catch {cli_exec $clifd $a_cmd} result] {
            error $result $errorInfo
        } else {
            set cmd_output $result
        }
    }
}
# ---------------------------------------------------------------------------
# 2. Body
# ---------------------------------------------------------------------------

if [catch {cli_open} result] {
    error $result $errorInfo
} else {
    array set cli1 $result
}

# ---------------------------------------------------------------------------
# 3. Get SMS Index Number
# ---------------------------------------------------------------------------
# array set arr_einfo [event_reqinfo]
# set msg $arr_einfo(msg)
# set syslog_line [split $msg]
# set num [lindex $syslog_line 11]
# regsub -all .$ $num "" num
# action_syslog msg "Number is $num"

# ---------------------------------------------------------------------------
# 4. Get SMS Message & From Mobile Number
# ---------------------------------------------------------------------------
set Cmds [list "enable" "cellular 0/2/0 lte sms view summary" ]
CLIProc $cli1(fd) $Cmds

foreach line [split $cmd_output \n] {
    set instr_line [split $line]
    set instr [lindex $instr_line 0]
    switch $instr {
        0 {
            regsub -all "{}" $instr_line "" instr_line
            set mobileNum [lindex $instr_line 1]
            set smsMsg [lindex $instr_line 5]
        }
    }
}

action_syslog msg "Received From : $mobileNum"
action_syslog msg "Received Message : $smsMsg"

# ---------------------------------------------------------------------------
# 5. Append SMS log file
# ---------------------------------------------------------------------------
if [file exists sms.log] {
            puts "file sms.log being overwritten"
        }
set myfileid [open sms.log a+]
puts $myfileid $cmd_output
close $myfileid

# ---------------------------------------------------------------------------
# 6. Actions
# ---------------------------------------------------------------------------
switch -regexp $smsMsg {
    Command {
        set Cmds [list "enable" "cellular 0/2/0 lte sms send $mobileNum Cpu, Serial, Route, Ios, RttCisco, RttAmazon" ]
        CLIProc $cli1(fd) $Cmds
    }
    ^[0-9]+$ {
        set Cmds [list "enable" "cellular 0/2/0 lte sms send $smsMsg Hello from ISR1100LTE! Please send #Command# to me!" 
]
        CLIProc $cli1(fd) $Cmds
    }
    Cpu {
        set Cmds [list "enable" "show proc cpu | i CPU" ]
        CLIProc $cli1(fd) $Cmds
        set Cmds [list "enable" "cellular 0/2/0 lte sms send $mobileNum $cmd_output" ]
        CLIProc $cli1(fd) $Cmds
    }
    Serial {
        set Cmds [list "enable" "sh snmp chassis" ]
        CLIProc $cli1(fd) $Cmds
        set Cmds [list "enable" "cellular 0/2/0 lte sms send $mobileNum $cmd_output" ]
        CLIProc $cli1(fd) $Cmds
    }
    Route {
        set Cmds [list "enable" "sh ip route summary | be Total" ]
        CLIProc $cli1(fd) $Cmds
        set Cmds [list "enable" "cellular 0/2/0 lte sms send $mobileNum $cmd_output" ]
        CLIProc $cli1(fd) $Cmds
    }
    Ios {
        set Cmds [list "enable" "sh version | i bin" ]
        CLIProc $cli1(fd) $Cmds
        set Cmds [list "enable" "cellular 0/2/0 lte sms send $mobileNum $cmd_output" ]
        CLIProc $cli1(fd) $Cmds
    }
    RttCisco {
        set Cmds [list "enable" "sh ip sla statistics 100 | i Latest RTT" ]
        CLIProc $cli1(fd) $Cmds
        set Cmds [list "enable" "cellular 0/2/0 lte sms send $mobileNum $cmd_output" ]
        CLIProc $cli1(fd) $Cmds
    }
    RttAmazon {
        set Cmds [list "enable" "sh ip sla statistics 103 | i Latest RTT" ]
        CLIProc $cli1(fd) $Cmds
        set Cmds [list "enable" "cellular 0/2/0 lte sms send $mobileNum $cmd_output" ]
        CLIProc $cli1(fd) $Cmds
    }
    Vlan[0-9]{1,2} {
        set vlanNum [string trim $smsMsg Vlan]
                set Cmds [list "enable" "conf t" "int range gi 0/1/0 - 3" "switchport access vlan $vlanNum" "end" "write memory" ]
        CLIProc $cli1(fd) $Cmds
        append smsmsg "gi 0/1/0 - 3 is changed to " "$smsMsg"
        set Cmds [list "enable" "cellular 0/2/0 lte sms send $mobileNum $smsmsg" ]
        CLIProc $cli1(fd) $Cmds
    }
    default {
        set Cmds [list "enable" "cellular 0/2/0 lte sms send $mobileNum $smsMsg" ]
        CLIProc $cli1(fd) $Cmds
    }
} 

# ---------------------------------------------------------------------------
# 7. Clear messages on Modem
# ---------------------------------------------------------------------------
if [catch {cli_exec $cli1(fd) "enable"} result] {
    error $result $errorInfo
}
if [catch {cli_write $cli1(fd) "cellular 0/2/0 lte sms delete all"} result] {
    error $result $errorInfo
}
if [catch {cli_read_pattern $cli1(fd) "Are you sure you want to delete all SMS?"} result] {
    error $result $errorInfo
}
if [catch {cli_write $cli1(fd) "\n"} result] {
    error $result $errorInfo
}
if [catch {cli_read $cli1(fd)} result] {
    error $result $errorInfo
}

if [catch {cli_close $cli1(fd) $cli1(tty_id)} result] {
    error $result $errorInfo
}
