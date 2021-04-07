#
# usage:        lmopts.sh
#
# abstract:     This Bourne Shell script is sourced by each license manager
#		scripts to obtain certain site/user dependent information
#		as explained below. The first occurrence of this file
#		in the directory list below is used.
#
#			. 		(current)
#			$LM_ROOT	(default location)
#
#		* $LM_ROOT - $MATLAB/etc for a full MATLAB installation
#                            where $MATLAB is the MATLAB root directory.
#
#		Most of the time this file in the default location need not
#		be modified at all and nothing needs to be done. However, if
#		you want to change the defaults you will need to modify this
#		file. You may override some of the defaults on the command
#		line of each script.
#
#		There are two modes of usage of the license manager scripts:
#		MathWorks mode, and Globetrotter mode. Each script handles
#		both modes and determines which one to use by reading this
#		file. If it cannot read this file then Globetrotter mode is
#		assumed. The mode can be switched at the command level by
#		using the '-w' option.
#
#		MathWorks mode means that a 'cannonical' looking license file
#		is constructed and run out of /var/tmp for all platforms. Also
#		the daemons are killed using the 'kill' command rather than
#		running the Globetrotter lmdown executable.
#
#		Currently, the following variables are available to change:
#
#		LM_UTIL_MODE		(license manager script mode)
#		LM_ROOT			(license manager root directory)
#		ARCH			(machine architecture)
#		LM_FILE			(path of the initial license file)
#		LM_START_FILE		(path of the license file actually
#					 used at startup)
#		LM_LOGFILE		(path of the debug log file)
#		LM_LOGFILE_REDUNDANT    (path of the debug log file for 
#					 redundant servers)
#		LM_ARGS_LMGRD		(special arguments to use with lmgrd)
#		LM_ADMIN_USER		(username to start/stop license
#					 manager - CANNOT be superuser)
#		LM_LMDEBUG_LOG		(path of the lmdebug log file) 
#		LM_BOOT_FRAGMENT	(path to the file containing the
#				 	 boot fragment)
#		LM_DAEMON_WAIT		(time to wait for MathWorks daemon
#					 to come up)
#
#               (MathWorks script mode only)
#		LM_RUN_DIR		(directory where the cannonical
#					 license file and links are
#					 constructed)
#		LM_MARKER		(distinquishing marker used in
#					 forming LM_START_FILE)
#
# note(s):	1. The default values are
#
#		   MathWorks and Globetrotter modes:
#		   --------------------------------
#
#		   LM_UTIL_MODE		(license manager script mode)
#
#			This is set to 1, i.e. MathWorks mode.
#
#			NOTE: Any other value means Globetrotter mode.
#
#		   LM_ROOT		(license manager root directory)
#
#			This is set by install_matlab. 
#
#		        NOTE: The value of LM_ROOT called LM_ROOTdefault is
#			      determined first by each license manager script
#			      before this file is sourced. If the value of
#			      LM_ROOT placed in this script by install_matlab
#			      is different than LM_ROOTdefault then
#			      LM_ROOTdefault is used as the value of LM_ROOT.
#
#                  ARCH                 (machine architecture)
#
#                       This is the local machine architecture. It is
#			set by the arch.sh utility script if initially
#			empty or is invalid. Use the -arch argument on
#			any license manager script to set its value instead
#			of having arch.sh do it.
#
#		   LM_FILE		(path of the initial license file)
#
#		        This is set to $LM_ROOT/license.dat.
#
#		   LM_START_FILE	(path of the license file actually
#					 used at startup)
#
#			MathWorks mode:		$LM_RUN_DIR/$LM_MARKER.dat
#			Globetrotter mode:      $LM_ROOT/license.dat
#
#
#		   LM_LOGFILE		(path of the debug log file)
#
#			This is set to /var/tmp/lm_TMW.log
#		   
#		   LM_LOGFILE_REDUNDANT	(path of the debug log file for
#				         redundant servers)
#
#			This is set to /var/tmp/lm_TMW.log
#		   
#		   LM_ARGS_LMGRD	(special arguments to use with lmgrd)
#
#			This is set to '$arglist_lmgrd'.
#
#		   LM_ADMIN_USER	(username to start/stop license
#					 manager - CANNOT be superuser!)
#
#		        This is empty.
#
#
#		   LM_LMDEBUG_LOG	(path of the lmdebug log file) 
#
#			./lmdebug.out
#
#		   LM_BOOT_FRAGMENT	(path to the file containing the
#				 	 boot fragment)
#
#			sol2	-	/etc/init.d/lmgrd
#			glnx86  -	/etc/init.d/flexnet
#			mac     -       (blank for now)
#
#		   LM_DAEMON_WAIT	(time to wait for MathWorks daemon
#					 to come up)
#
#			3 seconds
#
#		   MathWorks mode only: (These should not be changed.)
#		   -------------------
#
#		   LM_RUN_DIR		(directory where the cannonical
#					 license file and links are
#					 constructed)
#
#			This is set to /var/tmp.
#	
#		   LM_MARKER		(distinquishing marker used in
#					 forming LM_START_FILE)
#
#			This is set to 'lm_TMW'.
#
# Copyright 1996-2007 The MathWorks, Inc.
#----------------------------------------------------------------------------
#
# Determine the arch.
#
#   -------------------------------------------------------------
#
    LM_UTIL_DIR=
#
#   -------------------------------------------------------------
#
    if [ ! "$LM_UTIL_DIR" ]; then
	LM_UTIL_DIR=$LM_UTIL_DIRdefault
    fi
#
    if [ -f $LM_UTIL_DIR/arch.sh ]; then
        . $LM_UTIL_DIR/arch.sh
        if [ "$ARCH" = "unknown" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo '    Error: We could not determine the machine architecture for your'
echo '           host. Please contact:'
echo ' '
echo '               MathWorks Technical Support'
echo ' '
echo '           for further assistance.'
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            exit 1
	fi
    else
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo "    Error: The 'arch' script could not be found."
echo '           Normally it is in the directory:'
echo ' '
echo '               $LM_ROOT/util'
echo ' '
echo '           This could be caused by improper installation.'
echo '           If you cannot resolve the problem please contact:'
echo ' '
echo '               MathWorks Technical Support'
echo ' '
echo '           for further assistance.'
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	exit 1
    fi
#
#****************************************************************************
# IMPORTANT! Modify ONLY if you don't like the defaults.
#****************************************************************************
#
#****************************************************************************
# Platform specific section:
#****************************************************************************
#
    case "$ARCH" in
	sol64|sol2)
#----------------------------------------------------------------------------
	    LM_BOOT_FRAGMENT=/etc/init.d/lmgrd
	    ;;
	glnx86|glnxa64)
#----------------------------------------------------------------------------
	    LM_BOOT_FRAGMENT=/etc/init.d/flexnet
	    ;;
	mac|maci|maci64)
#----------------------------------------------------------------------------
	    LM_BOOT_FRAGMENT=
	    ;;
	*)
#----------------------------------------------------------------------------
	    LM_BOOT_FRAGMENT=''
	    ;;
    esac
#
    LM_ROOT=$LM_ROOTdefault
#
#****************************************************************************
# Platform independent section:
#****************************************************************************
#  
#   LM_UTIL_MODE:   0 - Globetrotter mode
#		    1 - MathWorks mode
#
    LM_UTIL_MODE=1
#
    if [ "$LM_SWITCHMODE" != "" ]; then
	if [ "$LM_UTIL_MODE" = "0" ]; then
	    LM_UTIL_MODE=1 
	else
	    LM_UTIL_MODE=0
	fi
    fi
#
# Mathworks mode:
# --------------
#
    if [ "$LM_UTIL_MODE" = "1" ]; then
	LM_FILE='$LM_ROOT/license.dat'
	LM_LOGFILE=/var/tmp/lm_TMW.log
	LM_LOGFILE_REDUNDANT=/var/tmp/lm_TMW.log
	LM_ARGS_LMGRD='$arglist_lmgrd'
	LM_ADMIN_USER=
	LM_LMDEBUG_LOG='./lmdebug.out'
	LM_DAEMON_WAIT=3
#
# Do not change these
#
	LM_RUN_DIR=/var/tmp
	LM_MARKER=lm_TMW
	LM_START_FILE='$LM_RUN_DIR/$LM_MARKER.dat'
    fi
#
# Globetrotter mode:
# -----------------
#
    if [ "$LM_UTIL_MODE" != "1" ]; then
	LM_FILE='$LM_ROOT/license.dat'
	LM_LOGFILE=/var/tmp/lm_TMW.log
	LM_LOGFILE_REDUNDANT=/var/tmp/lm_TMW.log
	LM_ARGS_LMGRD='$arglist_lmgrd'
	LM_ADMIN_USER=
	LM_LMDEBUG_LOG='./lmdebug.out'
	LM_DAEMON_WAIT=3
#
	LM_START_FILE='$LM_FILE'
    fi
