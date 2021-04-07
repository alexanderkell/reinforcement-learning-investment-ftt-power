#!/bin/sh
#
# usage:        arch.sh
#
# abstract:     This Bourne Shell script determines the architecture
#               of the the current machine.
#
#               ARCH      - Machine architecture
#
#               IMPORTANT: The shell function 'check_archlist' is used
#                          by this routine and MUST be loaded first.
#                          This can be done by sourcing the file,
#
#                              archlist.sh
#
#                          before using this routine.
#
# note(s):      1. This routine must be called using a . (period)
#
#               2. Also returns ARCH_MSG which may contain additional
#                  information when ARCH returns 'unknown'.
#
# Copyright 1986-2016 The MathWorks, Inc.
#----------------------------------------------------------------------------
#
#=======================================================================
# Functions:
#   realfilepath ()
#   matlab_arch ()
#=======================================================================
    realfilepath () { # Returns the actual path in the file system
                      # of a file. It follows links. It returns an
                      # empty path if an error occurs.
                      #
                      # Returns a 1 status if the file does not exist
                      # or appears to be a circular link. Otherwise,
                      # a 0 status is returned.
                      #
                      # usage: realfilepath filepath
                      #
    filename=$1
#
# Now it is either a file or a link to a file.
#
    cpath=`pwd`

#
# Follow up to 8 links before giving up. Same as BSD 4.3
#
      n=1
      maxlinks=8
      while [ $n -le $maxlinks ]
      do
#
# Get directory correctly!
#
	newdir=`echo "$filename" | awk '
                        { tail = $0
                          np = index (tail, "/")
                          while ( np != 0 ) {
                             tail = substr (tail, np + 1, length (tail) - np)
                             if (tail == "" ) break
                             np = index (tail, "/")
                          }
                          head = substr ($0, 1, length ($0) - length (tail))
                          if ( tail == "." || tail == "..")
                             print $0
                          else
                             print head
                        }'`
	if [ ! "$newdir" ]; then
	    newdir="."
	fi
	(cd "$newdir") > /dev/null 2>&1
	if [ $? -ne 0 ]; then
	    return 1
	fi
	cd "$newdir"
#
# Need the function pwd - not the built in one
#
	newdir=`/bin/pwd`
#
	newbase=`expr //"$filename" : '.*/\(.*\)' \| "$filename"`
        lscmd=`ls -ld "$newbase" 2>/dev/null`
	if [ ! "$lscmd" ]; then
	    return 1
	fi
#
# Check for link portably
#
	if [ `expr "$lscmd" : '.*->.*'` -ne 0 ]; then
	    filename=`echo "$lscmd" | awk '{ print $NF }'`
	else
#
# It's a file
#
	    dir="$newdir"
	    command="$newbase"
#
	    cd "$dir"
#
# On Mac OS X, the -P option to pwd causes it to return a resolved path, but
# on 10.5 and later, -P is no longer the default, so we are now passing -P explicitly.
#
            if [ "$ARCH" = 'maci64' ]; then
                echo `/bin/pwd -P`/$command
#
# The Linux version of pwd returns a resolved path by default, and there is
# no -P option
#
            else
                echo `/bin/pwd`/$command
            fi
	    break
	fi
	n=`expr $n + 1`
      done
      if [ $n -gt $maxlinks ]; then
	return 1
      fi

    cd "$cpath"
    }
#
#
#=======================================================================
    matlab_arch () {  # Determine the architecture for MATLAB
                      # It returns the value in the ARCH variable.
                      # If 'unknown' is returned then sometimes a
                      # diagnostic message is returned in ARCH_MSG.
                      #
                      # Always returns a 0 status.
                      #
                      # usage: matlab_arch
                      #
        ARCH="unknown"
#
        if [ -f /bin/uname ]; then
            case "`/bin/uname`" in
                Linux)
                    case "`/bin/uname -m`" in
                        x86_64)
                            ARCH="glnxa64"
                            ;;
                    esac
                    ;;
            esac
        elif [ -f /usr/bin/uname ]; then
            case "`/usr/bin/uname`" in
                Darwin)                                 # Mac OS X
                    case "`/usr/bin/uname -p`" in
                        i386)
                            ARCH="maci64"
                            ;;
						arm)
							ARCH="maci64"
							;;
					esac
                    ;;
            esac
        fi
        return 0
    }
#=======================================================================
#
# The local shell function check_archlist is assumed to be loaded before this
# function is sourced.
#
    ARCH_MSG=''
    check_archlist ARCH=$ARCH
    if [ "$ARCH" = "" ]; then
        if [ "$MATLAB_ARCH" != "" ]; then
            check_archlist MATLAB_ARCH=$MATLAB_ARCH
        fi
        if [ "$ARCH" = "" ]; then
            matlab_arch
        fi
    fi
    Arch=$ARCH
