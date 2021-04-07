#
# usage:	setlmenv.sh
#
# abstract:	This Bourne Shell script determines the values of the
#		following license manager environment variables.
#
#    MathWorks or Flexera script mode:
#
#	LM_SET_ENV		(license manager variables set or not)
#	LM_UTIL_MODE		(license manager script mode)
#	LM_ROOT			(license manager root directory)
#	AUTOMOUNT_MAP		(path prefix map for automounting)
#	ARCH			(machine architecture)
#	LM_FILE			(path of the initial license file)
#	LM_START_FILE		(path of the license file actually
#				 used at startup)
#	LM_LOGFILE		(path of the FLEXnet debug logfile. This
#				 is set to LM_LOGFILE_REDUNDANT if
#				 LM_NSERVERS = 3)
#	LM_LOGFILE_REDUNDANT	(path of the FLEXnet debug logfile for
#				 redundant servers)
#       LM_ARGS_LMGRD           (special arguments to use with lmgrd)
#       LM_ADMIN_USER           (username to start/stop license
#                                manager - CANNOT be superuser!)
#	LM_LMDEBUG_LOG		(path of the lmdebug logfile) 
#       LM_DAEMON_WAIT		(time to wait for MathWorks daemon
#                                to come up)
#
#    MathWorks script mode only:
#
#	LM_RUN_DIR		(directory where the cannonical license
#				 file and links are constructed)
#	LM_MARKER		(distinquishing marker used in forming
#				 LM_START_FILE)
#
#    Architecture dependent:
#
#	LM_BOOT_FRAGMENT	(path to the file containing the
#				 boot fragment)
#
#    Cannot change (hardwired into MATLAB):             
#
#	LM_LOCKFILE		(file used by lmgrd to prevent multiple
#				 copies of the daemons to be run at the
#				 same time.)	
#
#    Determines:
#
#	LM_NSERVERS		(the number of servers. It will error
#				 if not 1 or 3.)
#	LM_PORTATHOST		(if LM_FILE is of the form port@host
#				 then 1 else 0)
#				
#
# note(s):      1. This routine must be called using a . (period)
#
# Copyright 1996-2010 The MathWorks, Inc. 
#----------------------------------------------------------------------------
#=======================================================================
# Functions:
#   actualpath ()
#   badlogfilemsg ()
#   bld_empty_file ()
#   bld_sym_link ()
#   check_binaries ()
#   check_licensefile ()
#   check_portathost ()
#   check_readfile ()
#   check_writelogfile ()
#   cleanup ()
#   combine_cont_lines ()
#   comment_lines ()
#   displayid ()
#   echon ()
#   getfileowner ()
#   getpidinfo ()
#   getpsinfo ()
#   getserver_ports ()
#   getusername ()
#   hostname ()
#   interactive ()
#   issuperuser ()
#   license_number ()
#   llsfile ()
#   process_exist ()
#   righthost ()
#   rm_if_owner ()
#   searchpath ()
#   serverlines ()
#   setlockfile ()
#=======================================================================
    actualpath () { # Determine the actual path of a file following
		    # all links. Returns the real path or null if it
		    # is not a file.
                    #
		    # Always returns a 0 status.
		    #
                    # usage: actualpath path
                    #

        File=$1
        Filepath=
#
        lsCmd=`ls -ld $File 2>/dev/null`
        if [ "$lsCmd" ]; then
#
# Check for link portably
#
	    if [ `expr "$lsCmd" : '.*->.*'` -eq 0 ]; then
    	        if [ ! -d $File ]; then
	            Filepath=$File
                fi
            else
#
# A directory link?
#
		if [ -d $File ]; then
	            :
                else
#
# Now it is either a file, link to a file, or still a bad path.
#
	            cpath=`/bin/pwd`
                    localFile=$File
#
# Follow up to 8 links before giving up. Same as BSD 4.3
#
	            n=1
    	            while [ $n -le 8 ]
    	            do
#
# Get directory correctly!
#
   	                newDir=`echo "$localFile" | awk '
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
	                if [ ! "$newDir" ]; then
	                    newDir="."
	                fi
			if [ ! -d $newDir ]; then
		            break
	                fi
	                cd $newDir
	                newDir=`/bin/pwd`
	 newBase=`expr //$localFile : '.*/\(.*\)' \| $localFile`
                        lsCmd=`ls -l $newBase 2>/dev/null`
	                if [ ! "$lsCmd" ]; then
		            break
	                fi
#
# Check for link portably
#
	                if [ `expr "$lsCmd" : '.*->.*'` -ne 0 ]; then
	                    localFile=`echo "$lsCmd" | \
				awk '{ print $NF }'`
	                else
#
# It's a file
#
	                    Filepath=$newDir/$newBase
	                fi
		        n=`expr $n + 1`
    	            done
    	            cd $cpath
	        fi
	    fi
        fi
	echo $Filepath
	return 0
    }
#=======================================================================
    badlogfilemsg ()  { # Outputs an informative message about why the
			# a logfile cannot be written in. This can be
			# used by any logfile.
			#
			# cases: 1. file exists, but cannot be written into
			#	 2. file does not exist, and cannot be
			#           created
			#	 3. parent directory does not exist
			#
                    	# Always returns a status of 0
                    	#
                    	# usage: badlogfilemsg LM_LOG LM_LOGNAME
                    	#
	LM_LOG=$1
	LM_LOGNAME=$2
	if [ -f $LM_LOG ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo '    Error: Cannot write in logfile ($'"$LM_LOGNAME"').'
echo ' '
echo "           $LM_LOGNAME = $LM_LOG"
echo ' '
echo "                        `llsfile $LM_LOG`"
echo ' '
echo "           You are:     `displayid`"
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	else
#
# get dirname and check for that
#
	    dirlogname=`echo "$LM_LOG" | awk '
#--------------------------------------------------------------------------
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
#--------------------------------------------------------------------------
	    if [ ! -d $dirlogname ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo '    Error: Cannot create logfile ($'"$LM_LOGNAME"').'
echo ' '
echo "           $LM_LOGNAME = $LM_LOG"
echo ' '
echo "           Parent directory does not exist."
echo ' '
echo "           You are:     `displayid`"
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	    else
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo '    Error: Cannot create logfile ($'"$LM_LOGNAME"'). No permission.'
echo ' '          
echo "           $LM_LOGNAME = $LM_LOG"
echo ' '
echo '           Parent directory permission:'
echo ' '
echo "                        `llsfile $dirlogname`"
echo ' '
echo "           You are:     `displayid`"
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	    fi
	fi  
	exit 0
    }
#=======================================================================
    bld_empty_file () { # Create an empty file. This is possible if you 
		        # are a regular user or superuser and
			# LM_ADMIN_USER is defined. It assumed that
			# there is no existing file.
		        #
		        # Returns 0 status if file was created else 1.
		        #
		        # usage: bld_empty_file newfile
		        #

	newfile=$1
	issuperuser
	if [ $? -eq 0 ]; then
            if  [ "$LM_ADMIN_USER" = "" -o "$LM_ADMIN_USER" = "root" -o \
                "$LM_ADMIN_USER" = "0" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo '    Error: Cannot create file as superuser without'
echo '           LM_ADMIN_USER defined properly.'
echo ' '
echo "           LM_ADMIN_USER = $LM_ADMIN_USER"
echo ' '
echo "           cat /dev/null > $newfile"
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		return 1
	    else
	        su $LM_ADMIN_USER -c "cat /dev/null > $newfile"
		return $?
	    fi
	else
	    cat /dev/null > $newfile
	    return 0
	fi
    }
#=======================================================================
    bld_sym_link () { # Create a symbolic link. This is possible if you
		      # a regular user or superuser and LM_ADMIN_USER is
		      # defined. It assumed that there is no existing
		      # link.
		      #
		      # Returns 0 status if link was created else 1.
		      #
		      # usage: bld_sym_link link_to link_name
		      #

	link_to=$1
	link_name=$2
	issuperuser
	if [ $? -eq 0 ]; then
            if  [ "$LM_ADMIN_USER" = "" -o "$LM_ADMIN_USER" = "root" -o \
                "$LM_ADMIN_USER" = "0" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo '    Error: Cannot create symbolic link as superuser without'
echo '           LM_ADMIN_USER defined properly.'
echo ' '
echo "           LM_ADMIN_USER = $LM_ADMIN_USER"
echo ' '
echo "           ln -s $link_to $link_name"
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		return 1
	    else
	        su $LM_ADMIN_USER -c "ln -s $link_to $link_name"
		return $?
	    fi
	else
	    ln -s $link_to $link_name
	    return 0
	fi
    }
#=======================================================================
    check_binaries () { # Check for the existence of FLEXnet binaries.
                        #
                        # Returns 0 status if found else 1.
                        #
                        # usage: check_binaries
                        #
	if [ "$ARCH" != "unknown" -a "$ARCH" != "" ]; then
	    if [ ! -d $LM_ROOT/$ARCH ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo "    Error: No FLEXnet License Manager binaries for $ARCH."
echo ' ' 
echo '           Directory $LM_ROOT'"/$ARCH does not exist."
echo '           $LM_ROOT usually means $MATLAB/etc.'
echo ' '
echo '           This could be caused by improper installation.'
echo '           If you cannot resolve the problem please contact:'
echo ' '
echo '               MathWorks Technical Support'
echo ' '
echo '           for further assistance.'
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                return 1
	    fi
	fi
	return 0
    }
#=======================================================================
    check_licensefile () { # Check for the existence of the license file.
                           #
                           # Returns 0 status if found else 1. 
                           #
                           # usage: check_licensefile
                           #
#
# Skip if port@host
#
	    if [ "$LM_PORTATHOST" != "1" ]; then
                file=`actualpath $LM_FILE`
                if [ "$file" = "" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo '    Error: License file ($LM_FILE) does not exist.'
echo ' '
echo "           LM_FILE = $LM_FILE"
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                    return 1
                fi
            fi
	    return 0
    }
#=======================================================================
    check_portathost () { # Sets LM_PORTATHOST = 1 if LM_FILE as the
			  # form port@host
                          #
                          # Always returns a 0 status.
                          #
                          # usage: check_portathost
                          #
	LM_PORTATHOST=0
        if [ `expr "$LM_FILE" : '[^@/][^@/]*@[^@/][^@/]*$'` -ne 0 ]; then
	    LM_PORTATHOST=1
	fi
	return 0
    }
#=======================================================================
    check_readfile () { # Check that you can read a file. If you cannot
		        # or it does not exist then print a message.
			#
		        # Returns 0 status if yes else 1.
			#
			# usage: check_readfile file
			#
	file=`actualpath $1`
	if [ "$file" = "" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo "    Error: file does not exist . . ."
echo ' '
echo "           file = $1"
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	    return 1
	elif [ ! -r $1 ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo "    Error: file exists but cannot be read . . ."
echo ' '
echo "           file = $1"
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	    return 1
	else
	    return 0
	fi
    }
#=======================================================================
    check_writelogfile () { # Check that you can write into the FLEXnet
                            # debug logfile and set the final value
		            # LM_LOGFILE.
			    #
                            # Returns 0 status if yes else 1. 
                            #
                            # usage: check_writelogfile
                            #
	
	if [ "$LM_PORTATHOST" != "1" ]; then
	    serverlines
	    if [ $? -ne 0 ]; then
                return 1
	    fi
            if [ "$LM_NSERVERS" = "1" ]; then
	        LM_LOG=$LM_LOGFILE
	    else
	        LM_LOG=$LM_LOGFILE_REDUNDANT
	    fi
	else
	    LM_LOG=$LM_LOGFILE
        fi
#
# The logfile must be writeable by the current user
#
	issuperuser
	if [ $? -eq 0 ]; then
	    if  [ "$LM_ADMIN_USER" = "" -o "$LM_ADMIN_USER" = "root" -o \
		"$LM_ADMIN_USER" = "0" ]; then
                :
	    else
#
# Be sure that the logfile is writeable by LM_ADMIN_USER and exists
#
                if [ -f $LM_LOG ]; then
                    cmd="cat /dev/null >> $LM_LOG"
                    su $LM_ADMIN_USER -c "$cmd" 2> /dev/null
                    if [ $? -ne 0 ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo "    Error: Cannot write in logfile $LM_LOG."
echo ' '
echo "                        `llsfile $LM_LOG`"
echo ' '
echo "    You are running as: $LM_ADMIN_USER"
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			return 1
		    fi
                else
		    cmd="cat /dev/null > $LM_LOG"
                    su $LM_ADMIN_USER -c "umask 022; $cmd"
                fi
	    fi
        else
	    actual_username=`getusername`
	    if [ "$username" != "$actual_username" -a \
		 "$username" != "" -a \
		 "$actual_username" != "" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo "    Error: your username = $actual_username"
echo "           -u argument   = $username"
echo ' '
echo "           These cannot be different unless you are superuser."
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		 return 1
	    fi
	    if [ "$LM_ADMIN_USER" != "$actual_username" -a \
		 "$LM_ADMIN_USER" != "" -a \
		 "$actual_username" != "" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo "    Error: your username = $actual_username"
echo "           LM_ADMIN_USER = $LM_ADMIN_USER"
echo ' '
echo "           These cannot be different unless you are superuser."
echo ' '
echo "           Fix your lmopts.sh file or become the user specified by"
echo "           LM_ADMIN_USER."
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		return 1
	    fi
            (cat /dev/null >> $LM_LOG) 2>/dev/null
            if [ $? -ne 0 ]; then
        	if [ "$LM_NSERVERS" != "3" ]; then
	    	    LM_LOGNAME='LM_LOGFILE'
		else
	            LM_LOGNAME='LM_LOGFILE_REDUNDANT'
		fi
	        badlogfilemsg $LM_LOG $LM_LOGNAME
                return 1
	    fi
        fi
	if [ "$LM_PORTATHOST" != "1" ]; then
	    if [ "$LM_NSERVERS" = "3" ]; then
	        LM_LOGFILE=$LM_LOGFILE_REDUNDANT
            fi
	fi
	return 0
    }
#=======================================================================
    cleanup () { # Cleans up the remaining license manager files
                 #
                 # Always returns a 0 status.
                 #
                 # usage: cleanup
                 #
#
# Remove the lockfile and all marker files in any case.
#
        rm -f $LM_LOCKFILE $LM_RUN_DIR/$LM_MARKER.dat \
              $LM_RUN_DIR/$LM_MARKER.ld $LM_RUN_DIR/$LM_MARKER.vd* > /dev/null 2>&1
        return 0
    }
#=======================================================================
fixmacendings () { # This filter reads a license file on standard
                   # input and converts mac line endings (\r) to 
                   # unix endings (\n).
                   #
                   # Always returns a 0 status. 
                   #
                   # usage: fixmacendings
                   #
 awk '
#-----------------------------------------------------------------------
    BEGIN { controlr = sprintf ("%c", 13)
            controln = sprintf ("%c", 10)
	  }
          {
	     len = length($0);
	     newtext = "";
	     start = 1;
	     for (i = 1; i < len; i = i + 1) {
	        c1 = substr($0, i, 1);
	        c2 = substr($0, i+1, 1);
		if (c1 == controlr) {
		   if (c2 != controln) { # we do not want to change \r\n
		      # save substring and continue
		      newtext = newtext substr($0, start, (i-start)) controln;
		      start = i+1;
		   }
		}
	     }
	     if (newtext == "") {
	        print $0;
	     } else {
	        newtext = newtext substr($0,start,(len-start)+1);
	        print newtext;
	     }
	   }'
#-----------------------------------------------------------------------
	return 0
    }
#=======================================================================
    combine_cont_lines () { # This filter reads a license file on standard
		            # input and combines any non comment lines
		            # that use backslash characters and writes it
		            # to standard output.
	                    #
	                    # Always returns a 0 status. 
	                    #
	                    # usage: combine_cont_lines
	                    #
        awk '
#-----------------------------------------------------------------------
    BEGIN { backslash = sprintf ("%c", 92)   # set backslash
            controlr = sprintf("%c",13)  # set \r
            commentblock = 0; line = "" }
substr($1,1,1) == "#" { print
			if (substr($NF,length($NF),1) == backslash)
			    commentblock = 1
			next
		      }
commentblock == 1 { if (substr($NF,length($NF),1) != backslash)
			commentblock = 0
		    print
		    next
		  }
#Check for DOS line endings \r after a \.
substr($NF, length($NF)-1,1) == backslash {
		  if (substr($NF, length($NF),1) == controlr) {
		  	ix = index($0,backslash)
		  	line = line substr($0,1,ix-1) " " 
		  	next
		    }
		  }
substr($NF, length($NF),1) == backslash {
		  ix = index($0,backslash)
		  line = line substr($0,1,ix-1) " "
		  next
		  }
		  { if (line == "" )
		       line = $0
		    else
		       line = line $0
		    n = split(line,token)
		    line = token[1]
		    for (i = 2; i <= n; i = i + 1)
			line = line " " token[i]
		    print line
		    line = ""
		  }'
#-----------------------------------------------------------------------
	return 0
    }
#=======================================================================
    comment_lines ()  { # prints any line in the argument file to
			# standard output that does not start with:
			#
			# #
			# SERVER
			# DAEMON
			# FEATURE
			# INCREMENT
			# USE_SERVER
			# FEATURESET
			# PACKAGE
			# UPGRADE
			# VENDOR
			#
			# and is not a continuation line. i.e. the
			# previous line did not end with a \
			#
                        # Always returns a 0 status.
                        #
                        # usage: comment_lines file
                        #
	cat $1 | awk '
#-----------------------------------------------------------------------
    BEGIN { backslash = sprintf ("%c", 92)   # set backslash
            controlr = sprintf("%c",13)  # set \r
            commentblock = 0; keywordblock = 0; firstline = 0 }
commentblock == 1 { if (substr($NF,length($NF),1) != backslash)
			commentblock = 0
		    next
		  }
# If the line does not end with \, or \\r then end the keywordblock
keywordblock == 1 { if (substr($NF,length($NF),1) != backslash) {
		       # Does not end with \, check for \\r
		       if (substr($NF, length($NF)-1,1) != backslash) {
		          # Second to last char is not a \
		          keywordblock = 0
		       } else {
		          # Second to last char is a \
			  if (substr($NF, length($NF),1) != controlr) {
		             # Does not end with \r
			     keywordblock = 0
			  }
		       }
		    }
		    next
		  }
substr($1,1,1) == "#" { if (substr($NF,length($NF),1) == backslash)
			    commentblock = 1
			next
		      }
$1 == "SERVER" || $1 == "DAEMON" || \
$1 == "FEATURE" || $1 == "INCREMENT" || \
$1 == "USE_SERVER" || $1 == "FEATURESET" || \
$1 == "PACKAGE" || $1 == "UPGRADE"  || \
$1 == "VENDOR" {
		    if (substr($NF,length($NF),1) == backslash) {
			keywordblock = 1
		    }
	            #Check for DOS line endings \r after a \.
		    if (substr($NF, length($NF)-1,1) == backslash) {
			if (substr($NF, length($NF),1) == controlr) {
			    keywordblock = 1
			}
		    }
		  next
		  }
		  { if (firstline == 0) {
		        print "line#  line"
			firstline = 1
		    }
		    printf ("%5d  ", NR)
		    print $0
		  }'
#-----------------------------------------------------------------------
	return 0
    }
#=======================================================================
    displayid ()  { # returns the first 2 tokens (uid and gid)
		    # from the 'id' command. If 'id' is not on your
		    # path it returns a message.
		    #
                    # returns a status of 0 if id exists else 1
                    #
                    # usage: displayid
                    #
	(id) 2> /dev/null 1>&2
        if [ $? -eq 0 ]; then
	    id | awk '{ print $1, $2 }'
            return 0
        else
	    echo 'id command not on your search path'
	    return 1
	fi
    }
#=======================================================================
    echon () { # Echos out a message without the newline so that the 
	       # user can be prompted.
	       #
	       # Always returns a 0 status. 
	       #
	       # usage: echon mesg
	       #
        if [ "`echo -n`" != "" ]; then
            echo "$1\c"
        else
            echo -n "$1"
        fi
	return 0
    }
#=======================================================================
    getfileowner () { # Returns the username or uid if no name mapping
		      # is done of the file. The file is assumed to
		      # exist.
		      #
		      # Always returns a 0 status
		      #
		      # usage: getfileowner file
		      #
	ls -l $1 | awk '{ print $3 }'
	return 0
    }
#=======================================================================
    getpidinfo () { # Searches the output of ps to locate the pid and
		    # process name for all relevant license manager
		    # processes and writes them to standard output. The
		    # search string is an argument.
		    #
		    # System V:
#
#     1      2      3  4    5/6    6/7     7/8  8/9
#
#    root   289     1  0   Dec 05 ?       0:11 /usr/etc/lmgrd -c /var/flexlm/license.dat 
#    root   292   289  0   Dec 05 ?       0:19 sgifd -T baddog 4 -c /var/flexlm/license.dat 
#  martin  6284 14816  3 13:00:24 pts/6   0:00 grep lm 
# release 28984 28983  0   Dec 10 ?       0:00 sh -c while read line; do echo "$line" >> /var/tmp/lm_TMW.log; done 
# release 28983     1  0   Dec 10 ?       0:00 /bin/sh /rel/V5/release/5p0/5p0/non_bat0/work.etc/scripts/etc/lmboot 
# release 28985 28984  0   Dec 10 ?       0:05 /var/tmp/lm_TMW.ld -z -c /var/tmp/lm_TMW.dat 
#
		    # Long listing:
		    #
		    #  sol2       -OK-
		    #  glnx86     w
		    #
		    # Always returns a 0 status.
		    #
                    # usage: getpidinfo searchstr
                    #
#
        searchstr=$1
#
# You have to use 'ps -ef' because 'ps -f' can fail for two
# reasons:
#     1. wrong ps
#     2. 'ps: no controlling terminal'
#
# Send ps output to a file instead of a pipe so that the grep process
# doesn't get found by the grep.
#
        (ps -ef) > /dev/null 2>&1
	if [ $? -ne 0 ]; then
#
# Pure BSD version:
#
            temppidfile=/tmp/tmppids$$
	    ps agxw > $temppidfile
	    egrep $searchstr $temppidfile | awk '{ print $1, $5 }'
	    rm $temppidfile
#
    	elif [ "$ARCH" != "glnx86" ]; then
#
# System V version:
#

            temppidfile=/tmp/tmppids$$
            ps -ef > $temppidfile
            egrep $searchstr $temppidfile | awk '
#-----------------------------------------------------------------------
                    { if (length($5) != 3)
		           print $2, $8
		      else
		           print $2, $9
		     }'
	    rm $temppidfile

#-----------------------------------------------------------------------
	else 
#
# Linux special case: Older versions of ps axw have a "<" for token 4
#
            temppidfile=/tmp/tmppids$$
            ps axw > $temppidfile
            egrep $searchstr $temppidfile | awk '
                    { if ($4 == "<" )
                          print $1, $6
                      else if ($4 != "<")
                          print $1, $5  }'
	    rm $temppidfile
    	fi
        return 0
    }
#=======================================================================
    getpsinfo () { # Outputs the license manager ps entries
		   # to standard output. The search string is an 
		   # argument.
		   #
		   # Always returns a 0 status.
		   #
                   # usage: getpidinfo searchstr
                   #
#
        searchstr=$1
#
# You have to use 'ps -ef' because 'ps -f' can fail for two
# reasons:
#     1. wrong ps
#     2. 'ps: no controlling terminal'
#
# Send ps output to a file instead of a pipe so that the grep process
# doesn't get found by the grep.
#
        (ps -ef) > /dev/null 2>&1
	if [ $? -ne 0 ]; then
#
# Pure BSD version:
#
            temppidfile=/tmp/tmppids$$
	    ps agxw > $temppidfile
	    egrep $searchstr $temppidfile
            rm $temppidfile
#
    	elif [ "$ARCH" != "glnx86" ]; then
#
# System V version:
#
            temppidfile=/tmp/tmppids$$
            ps -ef > $temppidfile
            egrep $searchstr $temppidfile
            rm $temppidfile
	else
#
# Linux special case:
#
            temppidfile=/tmp/tmppids$$
	    ps axw > $temppidfile
	    egrep $searchstr $temppidfile
            rm $temppidfile
    	fi
        return 0
    }
#=======================================================================
    getserver_ports () { # Outputs the list of ports separated by
			 # blanks. Each port number is taken from a
			 # SERVER line in the license file.
                         #
			 # It is assumed that the license file exists.
			 #
			 # Returns a 0 status if found entries else 1.
			 #
                         # usage: getserver_port
                         #
	list=`cat $LM_FILE | fixmacendings | combine_cont_lines | awk '
#--------------------------------------------------------------------------
	$1 == "SERVER" && NF == 4 { print $4 }'`
#--------------------------------------------------------------------------
	if [ "$list" != "" ]; then
	    flist=""
	    for port in $list
	    do
	        flist="$flist $port"
	    done
	    if [ "$flist" != "" ]; then
	        echo $flist
	        return 0
	    else
		echo ''
		return 1
	    fi
	else
	    echo ''
	    return 1
	fi
    }
#=======================================================================
    getusername ()  { # Returns the username. Try the id command. If
		      # not on the path return an empty string. Use
		      # the numeric id if the username isn't there.
		      #
		      # uid=153(martin) gid=101
		      #
                      # Returns a 0 status if username is not empty
		      # else 1.
                      #
                      # usage: getusername
                      #
	(id) 2> /dev/null 1>&2
	if [ $? -eq 0 ]; then
	    id | awk '
#--------------------------------------------------------------------------
	    { ix1 = index($1,"(")
	      if ((length($1) - ix1) == 1) {
		   ix0=index($1,"=")
		   print substr($1,ix0+1,ix1-ix0-1)
	      }
	      else
	           print substr($1,ix1+1,length($1)-ix1-1)
	    }'
#--------------------------------------------------------------------------
            return 0
        else
	    echo ''
	    return 1
	fi
    }
#=======================================================================
    interactive () { # Determines whether you are running interactive
		     # or not.
		     #
		     # Returns 0 status if interactive else 1.
		     #
		     # usage: interactive
		     #
        if [ "$INTERACTIVE" = "" ]; then
	    (tty) > /dev/null 2>&1
            return $?
	else
	    return 0
	fi
    }
#=======================================================================
    issuperuser () { # Determines whether the current user is superuser
		     # or not. We assume uid=0 is always superuser.
		     # If id does not exist we try to create a file
		     # called $$check in / and delete it.
		     # 
                     # Returns a 0 status if superuser else 1.
                     #
                     # usage: issuperuser
                     #
	(id) 2> /dev/null 1>&2
        if [ $? -eq 0 ]; then
	    user="`id`"
            if [  `expr "$user" : 'uid=0('` -ne 6 ]; then
		return 1
	    else
		return 0
	    fi
	else
#
# Command 'id' is not on the path. Try the file check method.
#
	    (cat /dev/null > /$$check) > /dev/null 2>&1
	    if [ $? -eq 0 ]; then
		rm -f /$$check
		return 0
	    else
		return 1
	    fi
	fi
    }
#=======================================================================
    license_number () { # Searches the license file for the line
			#
			#     # LicenseNo: mathworks     HostID: ANY
			#
			# and writes the token after 'LicenseNo:' to
			# standard output.
			#
			# If the license file cannot be found output
			#     "no_license_file"
		        # else try to locate it in the license file
			# and output the appropriate value.
			#
		 	# Always returns a 0 status.
		 	#
		 	# usage: license_number
		 	#
	if [ ! -f "$LM_FILE" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo "no_license_file"
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	    return 0
	fi
	cat $LM_FILE | awk '
#--------------------------------------------------------------------------
    BEGIN {unknown = 1}
    /LicenseNo:/ { n = split($0,a)
		   for (i = 1; i <= n; i = i + 1)
		       if (index(a[i],"LicenseNo:") != 0) {
			    if (i == n || index(a[i+1],"HostID:") != 0)
		                print "blank?"
			    else
				print a[i+1]
			    unknown = 0
			    exit
		       }
		 }
    END {if (unknown) print "no_value_in_license_file"}'
#--------------------------------------------------------------------------
	return 0
    }
#=======================================================================
    llsfile () { # Outputs ls -l(g)d of a file (directory) up through
                 # the group name. It takes the longer of the output of
		 # 'ls -ld' and 'ls -lgd' and outputs the front part of
		 # the string up through the 4th token. It assumes that
		 # the file (directory) exists. 
		 #
		 # Always returns a 0 status. 
		 #
		 # usage: llsfile file
		 #
        cclcmd=`ls -ld $1 | expand | wc -c`
        cclcmd=`expr $cclcmd + 0`
        cclgcmd=`ls -lgd $1 | expand | wc -c`
        cclgcmd=`expr $cclgcmd + 0`
#
        if [ $cclcmd -ge $cclgcmd ]; then
            cmd=`ls -ld $1`
        else
            cmd=`ls -lgd $1`
        fi
        echo "$cmd" | expand | awk '
#----------------------------------------------------------------------
            { n = split($0,a," ")
              rest = $0
              k = 0
              for (i = 1; i <= 4; i = i + 1) {
                 ix = index(rest, $i)
                 l = length($i)
                 rest = substr(rest,ix + l)
                 k = k + ix + l - 1
              }
              print substr($0,1,k)
            }'
#----------------------------------------------------------------------
        return 0
    }
#=======================================================================
    process_exist () { # Determines whether the process exists or not.
                       # The ps command on the mac will return 0 even
                       # when the pid is not found, so we need to treat
                       # the mac a little special by always doing the grep.
                       #
                       # Returns 0 status if exists otherwise 1.
                       #
                       # usage: process_exist pid
                       #
        ps -p $1 > /dev/null 2>&1
        if [ $? -ne 0 -o "$ARCH" = "maci" -o "$ARCH" = "maci64" ]; then
            ps $1 2>&1 | grep $1 > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                return 1
            else
                return 0
            fi
        else
            return 0
        fi
    }
#=======================================================================
    righthost () { # Determines whether the localhost is one of the
		   # servers listed on a SERVER line in the license file.
		   # 1. If the hostid field is a number then it checks
		   #    against the output of lmhostid.
		   # 2. If the hostid is not a pure number then it
		   #    check the hostname field against that returned by
		   #    uname
		   #
		   # Returns 0 status and no output if SERVER found.
		   #         0 status and output if warning.
		   #         1 status and output if error.
		   #
                   # usage: righthost
                   #

        # When the default locale is set to use some of the Japanese
        # locales the tr command doesn't like the [:upper:] and [:lower:]
        # notations.
        # Temporarily set it to C just for the tr commands.  
        # We need to do the export to handle the case where LC_ALL or one of the
        # other LC_* variables is already set in the user's environment.
        origLC_ALL="$LC_ALL"
        LC_ALL=C
        export LC_ALL

        lmfilehids=`cat $LM_FILE | fixmacendings | combine_cont_lines | \
		                   awk '$1 == "SERVER" {print $3}'`
#
# Check the hostids for numbers
#
        lmfilehostids=
        for hid in $lmfilehids
        do
            hidlower=`echo $hid | tr '[:upper:]' '[:lower:]'`
	    if [ `expr "$hidlower" : '[0-9abcdef]*$'` -ne 0 ]; then
	        lmfilehostids="$lmfilehostids $hidlower"
	    fi
	done
#
# Get the local hostid by calling lmhostid.
#
        # Remove all quotes and return one or more (space separated) hostids
        flexhostid=`$LM_ROOT/lmhostid -$ARCH -n | sed -e 's/"//g'`
        # Convert to all lower case
        localhostids=`echo "$flexhostid" | tr '[:upper:]' '[:lower:]'`
        # Reset LC_ALL
        LC_ALL="$origLC_ALL"

#
# Try against the lmhostids
#
	found=0
        if [ "$lmfilehostids" != "" ]; then
#
# Check against the localhostids
#
            for hidi in $lmfilehostids
            do
	        for hidj in $localhostids
		do
	            if [ "$hidi" = "$hidj" ]; then
	                found=1
	                break 2
		    fi
	        done
	    done 
	fi
	if [ "$found" = "1" ]; then
	    return 0
	fi
#
#
# Try against the hostname
#
	localhostname=`hostname`
        lmhostnames=`cat $LM_FILE | fixmacendings | combine_cont_lines | \
		                    awk '$1 == "SERVER" {print $2}'`
	for hn in $lmhostnames
	do
	    if [ "$hn" = "$localhostname" -o "$hn" = "this_host" ]; then
#
# hostid cannot be a number - otherwise there is an inconsistency
#
                lmhid=`echo "$hn" | cat - $LM_FILE | fixmacendings | \
			     combine_cont_lines | awk '
#-----------------------------------------------------------------------
	BEGIN { found = 0;}
	NR == 1 { hostname = $1; next }
  "SERVER" == $1 && hostname == $2 && found == 0 { print $3; found = 1; next }'`
#-----------------------------------------------------------------------
	        if [ `expr "$lmhid" : '[0-9a-fA-F]*$'` -ne 0 ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo '    Error: Your hostname matches the hostname on a SERVER line in'
echo '           your license file but the lmhostid in that line does not.'
echo '           Your local lmhostid(s) are:'
echo ' '
echo "           $localhostids"
echo ' '
echo "           Your hostname is:  `hostname`"
echo ' '
echo '           The SERVER line in question is:'
echo ' '
echo '           -----------------------------------------------'
		    echo "$hn" | cat - $LM_FILE | fixmacendings | \
			  		    combine_cont_lines | awk '
#-----------------------------------------------------------------------
	NR == 1 { hostname = $1; next }
  "SERVER" == $1 && hostname == $2  { print "          ", $0}' 
#-----------------------------------------------------------------------
echo '           -----------------------------------------------'
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	             return 1
		 else
		     found=1
		     break
	         fi
	    fi
	done
	if [ "$found" = "1" ]; then
	    return 0
	fi
#
# Check for the case when
#	locathostname = hostname.<rest of domain qualification>
#
	found=0
	for hn in $lmhostnames
	do
	    head=`echo $hn $localhostname | awk '
#-----------------------------------------------------------------------
	   { n = split($1,a,".")
	     m = split($2,b,".")
	     if (a[1] == b[1]) print a[1] }'`
#-----------------------------------------------------------------------
	    if [ "$head" != "" ]; then 
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo '    Warning: Your local hostname and a SERVER hostname start with'
echo '             the same name, but have different full names. One may'
echo '             be the fully qualified version of the other which' 
echo '             usually should work. Your local lmhostid(s) are:'
echo ' '
echo "             $localhostids"
echo ' '
echo "             Your hostname is:  `hostname`"
echo ' '
echo '             The SERVER line is:'
echo ' '
echo '             -----------------------------------------------'
		echo "$hn" | cat - $LM_FILE | combine_cont_lines | fixmacendings | \
		    awk '
#-----------------------------------------------------------------------
	NR == 1 { hostname = $1; next }
	$1 == "SERVER" && $2 == hostname { print "            ", $0 }'
#-----------------------------------------------------------------------
echo '             -----------------------------------------------'
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	         found=1
		 break
	    fi
	done

        if [ "$found" != "1" ]; then
	    # Do one more check on mac and linux.
	    # Sometimes (particularly on mac) you can have a name
	    # in the server line that is just an alias.  If we get here
	    # and we still haven't matched the names, ping the names
	    # we are comparing and see if they have the same IP address.
	    # If so consider that a match and return 0.  Otherwise, issue
	    # the normal error about hostnames not matching.
	    if [ "$ARCH" = "maci" -o "$ARCH" = "maci64" -o "$ARCH" = "glnx86" -o "$ARCH" = "glnxa64" ]; then
	        # The -c option to ping is only available on mac and linux.
		# The output from ping that we are expecting is:
		# 	PING $hostname (XXX.XXX.XXX.XXX): 56 data bytes
		# There are other lines but we look for the pattern:
		# PING.*(.*) and capture what is between the parentheses
		# which should be the IP address.
                localip=`ping -c 1 $localhostname | awk '
	   	         /PING.*\(.*\)/ {
	   		      lp = index($0,"(");
	   		      rp = index($0,")");
	   	   	      printf "%s", substr($0, lp+1, rp-lp-1);
	      	         }'`

	        for hn in $lmhostnames
	        do
	             lfip=`ping -c 1 $hn | awk '
	   	       /PING.*\(.*\)/ {
	   	    	    lp = index($0,"(");
	   		    rp = index($0,")");
	   	   	    printf "%s", substr($0, lp+1, rp-lp-1);
	      	       }'`
 		     if [ "$lfip" = "$localip" ]; then
		     	 # The name in the license file is really the same
			 # machine as reported by the hostname command.
		         return 0
		     fi
	        done
	    fi

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo '    Error: Your host does not match any SERVER line in your license'
echo '           file. Your local lmhostid(s) are:'
echo ' '
echo "           $localhostids"
echo ' '
echo "           Your hostname is:  `hostname`"
echo ' '
echo '           The SERVER line(s) are:'
echo ' '
echo '           -----------------------------------------------'
		cat $LM_FILE | combine_cont_lines | fixmacendings | \
		    awk '$1 == "SERVER" { print "          ", $0 }'
echo '           -----------------------------------------------'
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	    return 1
	fi
        return 0
    }
#=======================================================================
    rm_if_owner () { # Remove the file if you are the owner. Owner
		     # is defined as:
		     #
		     #    1. Not superuser and the username matches that 
		     #       of the file.
		     #    2. Is superuser and there is a LM_ADMIN_USER
		     #       defined.
		     #
		     # Returns 0 status if the file was removed else 1.
		     #
		     # usage: rm_if_owner file_to_rm
		     #
	file_to_rm=$1
	issuperuser
	if [ $? -eq 0 ]; then
            if [ "$LM_ADMIN_USER" = "" -o "$LM_ADMIN_USER" = "root" -o \
                 "$LM_ADMIN_USER" = "0" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo '    Error: Cannot remove file as superuser without LM_ADMIN_USER'
echo '           defined properly.'
echo ' '
echo "           LM_ADMIN_USER = $LM_ADMIN_USER"
echo ' '
echo "           rm -f $file_to_rm"
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		return 1
	    else
		rm -f $file_to_rm
		return 0
	    fi
	else
	    if [ -f $file_to_rm ]; then
	        username=`getusername`
	        username_file=`getfileowner $file_to_rm`
		# On some OS's (namely Mac), sym links created in
		# /var/tmp are owned by root.  So, before we error
		# out because the owners are different, first check if
		# the file is owned by root, then check if it is a sym link.
		# If it is then just try to remove it.
	        if [ "$username" != "$username_file" ]; then
		    if [ "$username_file" = "root" ]; then
			perms=`ls -l $file_to_rm | awk '
				{printf "%s", substr($1,0,1);}'`
		        if [ "$perms" = "l" ]; then
		            rm -f $file_to_rm 
			    if [ $? -eq 0 ]; then
			       # If the file was deleted, return.  Otherwise,
			       # continue on and display the error message.
		               return 0
			    fi
			fi
		    else
		        # Sometimes (again, namely on the Mac) you can have
			# a username greater than 8 characters.  In this case
			# the file owner will still really only be 8 characters.
			# So we need to check if the first 8 chars match, if 
			# they do, just delete the file.
		    	matchedchar=`expr $username : $username_file.*`
		        if [ $matchedchar -ge 8 ]; then
		            rm -f $file_to_rm
		            return 0
			fi
		    fi
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo '    Error: Cannot remove file. Not owner . . .'
echo ' '
echo "           rm -f $file_to_rm"
echo ' '
echo "           Your username        = $username"
echo "           File owner username  = $username_file"
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		    return 1
	        else
		    rm -f $file_to_rm
		    return 0
	        fi
	    fi
	fi
    }
#=======================================================================
    searchpath () { # Search all the directories in your PATH variable
		    # for a command and returns the list. The empty
		    # string is returned if not on the path.
                    #
                    # Returns a 0 status if on the path else 1.
		    #
                    # usage: searchpath command
                    #
	vpath=`echo $PATH | tr ":" " "`
#
	pathlist=''
	found=0
	for dir in $vpath
	do
	    if [ ! -d $dir/$1 ]; then
	        lscmd=`ls -l $dir/$1 2>/dev/null`
	        if [ "$lscmd" ]; then
		    file=`actualpath $dir/$1`
		    if [ "$file" != "" ]; then
			if [ -x $file ]; then
			    if [ "$found" = "0" ]; then
	                        pathlist=$dir/$1
			    else
	                        pathlist="$pathlist $dir/$1"
			    fi
			    found=1
			fi
		    fi
	        fi
	    fi
	done
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo "$pathlist"
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	if [ "$found" = "1" ]; then
	    return 0
	else
	    return 1
	fi
    }
#=======================================================================
    serverlines () { # Determines the number of SERVER lines called
		     # LM_NSERVERS and checks that this number is correct.
		     # The number must be 1 or 3.  LM_FILE must exist.
		     #
		     # Returns a 0 status if the correct number else 1.
		     #
		     # usage: serverlines
		     #
	LM_NSERVERS=`cat $LM_FILE | fixmacendings | awk '
#-----------------------------------------------------------------------
	BEGIN { nservers = 0 }
	$1 == "SERVER" { nservers = nservers + 1; next }
        END { print nservers }'`
#-----------------------------------------------------------------------
	if [ "$LM_NSERVERS" = "0" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo '    Error: License file, $LM_FILE, has no SERVER lines.'
echo ' '
echo "           LM_FILE = $LM_FILE"
echo ' '
echo '           If all features are locked to a hostid of DEMO then'
echo '           running license manager daemons is not required.'
echo '           Otherwise, fix $LM_FILE by adding SERVER and DAEMON'
echo '           line(s) and try again.'
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            return 1
	elif [ "$LM_NSERVERS" != "1" -a "$LM_NSERVERS" != "3" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo '    Error: License file, $LM_FILE, has '"$LM_NSERVERS"' SERVER lines.'
echo '           There must be 1 or 3.'
echo ' '
echo "           LM_FILE = $LM_FILE"
echo ' '
echo '           Fix your license file and try again.'
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	    return 1
	fi
	return 0
    }
#=======================================================================
    setlockfile () { # Sets the value of LM_LOCKFILE
	             #
	             # Always returns a 0 status. 
	             #
	             # usage: setlockfile
	             #
	LM_LOCKFILE=/var/tmp/lockMLM
	return 0
    }
#=======================================================================
#
# Determine if interactive - set environment variable INTERACTIVE
#
    interactive
    if [ $? -eq 0 ]; then
	INTERACTIVE=1; export INTERACTIVE
    fi
#
# Determine what is set in the environment.
#
    AUTOMOUNT_MAPenv="$AUTOMOUNT_MAP"

#
# Set all the variables
#
    if [ "$LM_SET_ENV" = "" ]; then
	LM_SET_ENV=1
#
# Set the defaults - LM_ROOTdefault is determined above.
#
	LM_UTIL_MODEdefault=1
    	if [ "$LM_SWITCHMODE" != "" ]; then
	    LM_UTIL_MODEdefault=0
        fi
        AUTOMOUNT_MAPdefault=''
        ARCHdefault=''
        LM_FILEdefault='$LM_ROOT/license.dat'
        LM_START_FILEdefault='$LM_ROOT/license.dat'
        LM_LOGFILEdefault='/var/tmp/lm_TMW.log'
        LM_LOGFILE_REDUNDANTdefault='/var/tmp/lm_TMW.log'
	LM_ARGS_LMGRDdefault='$arglist_lmgrd'
	LM_ADMIN_USERdefault='$username'
        LM_LMDEBUG_LOGdefault='$LM_ROOT/lmdebug.out'
	LM_DAEMON_WAITdefault='$daemon_wait'
#
        LM_RUN_DIRdefault='/var/tmp'
        LM_MARKERdefault='lm_TMW'
#
	LM_BOOT_FRAGMENTdefault=''
#
        LM_UTIL_DIRdefault=$LM_ROOTdefault/util
#
#--------------------------------------------------------------------------
#
# Source file lmopts.sh and get values for the following environment
# variables
#
#    MathWorks or Flexera script mode:
#
#	LM_UTIL_MODE		(license manager script mode)
#	LM_ROOT			(license manager root directory)
#	AUTOMOUNT_MAP		(path prefix map for automounting)
#       ARCH                    (machine architecture)
#	LM_FILE			(path of the initial license file)
#	LM_START_FILE		(path of the license file actually
#				 used at startup)
#	LM_LOGFILE		(path of the FLEXnet debug logfile. This
#				 is set to LM_LOGFILE_REDUNDANT if
#				 LM_NSERVERS = 3)
#	LM_LOGFILE_REDUNDANT    (path of the FLEXnet debug logfile for
#				 redundant servers)
#       LM_ARGS_LMGRD           (special arguments to use with lmgrd)
#       LM_ADMIN_USER           (username to start/stop license
#                                manager - CANNOT be superuser!)
#	LM_LMDEBUG_LOG		(path of the lmdebug log file) 
#       LM_DAEMON_WAIT		(time to wait for MathWorks daemon
#                                to come up)
#
#    MathWorks script mode only:
#
#	LM_RUN_DIR		(directory where the cannonical license
#				 file and links are constructed)
#	LM_MARKER		(distinquishing marker used in forming
#				 LM_START_FILE)
#
#    Architecture dependent:
#
#	LM_BOOT_FRAGMENT	(path to the file containing the
#				 boot fragment)
#
# The search order for lmopts.sh is:
#
#       .               (current directory)
#       $LM_ROOT        (license manager root directory)
#
        if [ -f lmopts.sh ]; then
            SOURCED_DIR='.'
            SOURCED_DIReval=`/bin/pwd`
            . $cpath/lmopts.sh
        elif [ -f $LM_ROOTdefault/lmopts.sh ]; then
#
# NOTE: At this point we will use the LM_ROOT determined earlier to
#       source the file. After that the value in that file if not
#       null will be used.
#
            SOURCED_DIR='$LM_ROOT'
            SOURCED_DIReval=$LM_ROOTdefault
            . $LM_ROOTdefault/lmopts.sh
        else
            SOURCED_DIR=
            LM_UTIL_DIR=$LM_UTIL_DIRdefault
#
    	    if [ -f $LM_UTIL_DIR/arch.sh ]; then
        	. $LM_UTIL_DIR/arch.sh
                if [ "$ARCH" = "unknown" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo '    Error: Could not determine the machine architecture for this'
echo '           host. If your host is a supported architecture please'
echo '           contact:'
echo ' '
echo '               MathWorks Technical Support'
echo ' '
echo '           for further assistance.'
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		    if [ "$help" != "1" ]; then
                        exit 1
		    fi
		fi
	    else
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo "    Error: The 'arch' script could not be found."
echo '           It should be in the directory:'
echo ' '
echo '               $LM_ROOT/util'
echo ' '
echo '           Normally, $LM_ROOT is  $MATLAB/etc'
echo ' '
echo '           This could be caused by improper installation.'
echo '           If you cannot resolve the problem please contact:'
echo ' '
echo '               MathWorks Technical Support'
echo ' '
echo '           for further assistance.'
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		if [ "$help" != "1" ]; then
                    exit 1
		fi
            fi
	    ARCHdefault=$ARCH
        fi
#
# Determine the final values for the following variables
#
#    MathWorks or Flexera script mode:
#
#	LM_UTIL_MODE		(license manager script mode)
#	LM_ROOT			(license manager root directory)
#	AUTOMOUNT_MAP		(Path prefix map for automounting)
#       ARCH                    (machine architecture)
#	LM_FILE			(path of the initial license file)
#	LM_START_FILE		(path of the license file actually
#				 used at startup)
#	LM_LOGFILE		(path of the FLEXnet debug log file. This
#				 is set to LM_LOGFILE_REDUNDANT if
#				 LM_NSERVERS = 3)
#	LM_LOGFILE_REDUNDANT    (path of the FLEXnet debug logfile for
#				 redundant servers)
#       LM_ARGS_LMGRD           (special arguments to use with lmgrd)
#       LM_ADMIN_USER           (username to start/stop license
#                                manager - CANNOT be superuser!)
#	LM_LMDEBUG_LOG		(path of the lmdebug log file) 
#       LM_DAEMON_WAIT		(time to wait for MathWorks daemon
#                                to come up)
#
#    MathWorks script mode only:
#
#	LM_RUN_DIR		(directory where the cannonical license
#				 file and links are constructed)
#	LM_MARKER		(distinquishing marker used in forming
#				 LM_START_FILE)
#
#    Architecture dependent:
#
#	LM_BOOT_FRAGMENT	(path to the file containing the
#				 boot fragment)
#
        argument='a '
        ofile='o '
        script='s '
	environ='e '
        ofilearg='oa'
        scriptarg='sa'
#
# Sourced a lmopts.sh file
#
        if [ "$SOURCED_DIR" != "" ]; then
	    if [ "$LM_UTIL_MODE" != "" ]; then
	        if [ "$LM_SWITCHMODE" != "" ]; then
	            LM_UTIL_MODEmode="$ofilearg"
	        else
	            LM_UTIL_MODEmode="$ofile"
	        fi
	    else
	        if [ "$LM_SWITCHMODE" != "" ]; then
	            LM_UTIL_MODEmode="$scriptarg"
	        else
	            LM_UTIL_MODEmode="$script"
		    LM_UTIL_MODE="$LM_UTIL_MODEdefault"
	        fi
	    fi
#
            if [ "$AUTOMOUNT_MAP" != "" ]; then
                if [ "$LM_ROOT" != "$LM_ROOTdefault" -a "$AUTOMOUNT_MAPenv" != "" ]; then
                    AUTOMOUNT_MAPmode="$environ"
                else
                    AUTOMOUNT_MAPmode="$ofile"
                fi
            else
                AUTOMOUNT_MAPmode="$script"
                AUTOMOUNT_MAP="$AUTOMOUNT_MAPdefault"
            fi
#
            if [ "$LM_ROOT" != "" ]; then
                LM_ROOTmode="$ofile"
            else
                LM_ROOTmode="$script"
                LM_ROOT="$LM_ROOTdefault"
            fi
            if [ "$AUTOMOUNT_MAP" != "" ]; then
                LM_ROOT=`echo $LM_ROOT $AUTOMOUNT_MAP | awk '
                  {if (substr($1,1,length($2)) == $2)
                     if (NF == 4)                               # a -> b
                         print $NF substr($1,length($2) + 1)
                     else                                       # a ->
                         print substr($1,length($2) + 1)
                     else
                         print $1}'`
            fi
#
            if [ "$ARCH" != "" ]; then
                ARCHmode="$ofile"
            else
                ARCHmode="$script"
                ARCH="$ARCHdefault"
            fi
#
	    if [ "$licensefile" != "" ]; then
	        LM_FILEmode="$argument"
	        LM_FILE="$licensefile"
            else
	        if [ "$LM_FILE" != "" ]; then
	            LM_FILEmode="$ofile"
	            LM_FILE="`eval echo $LM_FILE`"
	        else
	            LM_FILEmode="$script"
	            LM_FILE="`eval echo $LM_FILEdefault`"
	        fi
	    fi
#
            if [ "$LM_START_FILE" != "" ]; then
	        LM_START_FILEmode="$ofile"
	        LM_START_FILE="`eval echo $LM_START_FILE`"
	    else
	        LM_START_FILEmode="$script"
	        if [ "$LM_UTIL_MODE" = "1" ]; then
		    LM_START_FILEdefault='$LM_RUN_DIRdefault/$LM_MARKERdefault.dat'
	        fi
	        LM_START_FILE="`eval echo $LM_START_FILEdefault`"
	    fi
#
	    if [ "$logfile" != "" ]; then
	        LM_LOGFILEmode="$argument"
	        LM_LOGFILE="$logfile"
		LM_LOGFILE_REDUNDANT="$logfile"
            else
	        if [ "$LM_LOGFILE" != "" ]; then
	            LM_LOGFILEmode="$ofile"
	            LM_LOGFILE="`eval echo $LM_LOGFILE`"
	        else
	            LM_LOGFILEmode="$script"
	            LM_LOGFILE="`eval echo $LM_LOGFILEdefault`"
	        fi
	    fi
#
	    if [ "$LM_LOGFILE_REDUNDANT" != "" ]; then
	        LM_LOGFILE_REDUNDANTmode="$ofile"
	        LM_LOGFILE_REDUNDANT="`eval echo $LM_LOGFILE_REDUNDANT`"
	    else
	        LM_LOGFILE_REDUNDANTmode="$script"
	        LM_LOGFILE_REDUNDANT="`eval echo $LM_LOGFILE_REDUNDANTdefault`"
	    fi
#
	    if [ "$LM_ARGS_LMGRD" != "" ]; then
	        LM_ARGS_LMGRDmode="$ofile"
	        LM_ARGS_LMGRD="`eval echo $LM_ARGS_LMGRD`"
	    else 
	        LM_ARGS_LMGRDmode="$script"
	        LM_ARGS_LMGRD="`eval echo $LM_ARGS_LMGRDdefault`"
	    fi
	    if [ "$arglist_lmgrd" != "" ]; then
		if [ "$LM_ARGS_LMGRDmode" = "$ofile" ]; then
		    LM_ARGS_LMGRDmode="$ofilearg"
		else
	            LM_ARGS_LMGRDmode="$argument"
		fi
	    fi
#
	    if [ "$LM_ADMIN_USER" != "" ]; then
	        LM_ADMIN_USERmode="$ofile"
	        LM_ADMIN_USER="`eval echo $LM_ADMIN_USER`"
	    else
	        LM_ADMIN_USERmode="$script"
	        LM_ADMIN_USER="`eval echo $LM_ADMIN_USERdefault`"
	    fi
	    if [ "$username" != "" ]; then
	        LM_ADMIN_USERmode="$argument"
	    fi
#
	    if [ "$lmdebug_log" != "" ]; then
	        LM_LMDEBUG_LOGmode="$argument"
	        LM_LMDEBUG_LOG="$lmdebug_log"
            else
	        if [ "$LM_LMDEBUG_LOG" != "" ]; then
	            LM_LMDEBUG_LOGmode="$ofile"
	            LM_LMDEBUG_LOG="`eval echo $LM_LMDEBUG_LOG`"
	        else
	            LM_LMDEBUG_LOGmode="$script"
	            LM_LMDEBUG_LOG="`eval echo $LM_LMDEBUG_LOGdefault`"
	        fi
	    fi
#
            if [ "$daemon_wait" != "" ]; then
                LM_DAEMON_WAITmode="$argument"
                LM_DAEMON_WAIT="$daemon_wait"
            elif [ "$daemon_wait_init" != "" ]; then
                LM_DAEMON_WAITmode="$script"
                LM_DAEMON_WAIT="$daemon_wait_init"
            else
                if [ "$LM_DAEMON_WAIT" != "" ]; then
                    LM_DAEMON_WAITmode="$ofile"
                    LM_DAEMON_WAIT="`eval echo $LM_DAEMON_WAIT`"
                else
                    LM_DAEMON_WAITmode="$script"
                    LM_DAEMON_WAIT="`eval echo $LM_DAEMON_WAITdefault`"
                fi
            fi
#
	    if [ "$LM_UTIL_MODE" = "1" ]; then
		if [ "$LM_RUN_DIR" != "" ]; then
	            LM_RUN_DIRmode="$ofile"
	            LM_RUN_DIR="`eval echo $LM_RUN_DIR`"
	        else
	            LM_RUN_DIRmode="$script"
	            LM_RUN_DIR="`eval echo $LM_RUN_DIRdefault`"
	        fi
#
		if [ "$LM_MARKER" != "" ]; then
	            LM_MARKERmode="$ofile"
	            LM_MARKER="`eval echo $LM_MARKER`"
	        else
	            LM_MARKERmode="$script"
	            LM_MARKER="`eval echo $LM_MARKERdefault`"
	        fi
	    fi
#
	    if [ "$LM_BOOT_FRAGMENT" != "" ]; then
	        LM_BOOT_FRAGMENTmode="$ofile"
	        LM_BOOT_FRAGMENT="`eval echo $LM_BOOT_FRAGMENT`"
	    else
	        LM_BOOT_FRAGMENTmode="$script"
	        LM_BOOT_FRAGMENT="`eval echo $LM_BOOT_FRAGMENTdefault`"
	    fi
        else
	    if [ "$LM_SWITCHMODE" != "" ]; then
	        LM_UTIL_MODEmode="$scriptarg"
	    else
	        LM_UTIL_MODEmode="$script"
	    fi
	    LM_UTIL_MODE="$LM_UTIL_MODEdefault"
#
            if [ "$AUTOMOUNT_MAPenv" != "" ]; then
                AUTOMOUNT_MAPmode="$environ"
                AUTOMOUNT_MAP="$AUTOMOUNT_MAPenv"
            else
                AUTOMOUNT_MAPmode="$script"
                AUTOMOUNT_MAP="$AUTOMOUNT_MAPdefault"
            fi
#
            LM_ROOTmode="$script"
            if [ "$AUTOMOUNT_MAP" != "" ]; then
                LM_ROOT=`echo $LM_ROOTdefault $AUTOMOUNT_MAP | awk '
                    {if (substr($1,1,length($2)) == $2)
                         if (NF == 4)                               # a -> b
                             print $NF substr($1,length($2) + 1)
                         else                                       # a ->
                             print substr($1,length($2) + 1)
                         else
                             print $1}'`
            else
                LM_ROOT="$LM_ROOTdefault"
            fi
#
            ARCHmode="$script"
            ARCH="$ARCHdefault"
#
	    if [ "$licensefile" != "" ]; then
	        LM_FILEmode="$argument"
	        LM_FILE="$licensefile"
            else
	        LM_FILEmode="$script"
	        LM_FILE="`eval echo $LM_FILEdefault`"
	    fi
#
	    LM_START_FILEmode="$script"
	    if [ "$LM_UTIL_MODE" = "1" ]; then
	        LM_START_FILEdefault='$LM_RUN_DIRdefault/$LM_MARKERdefault.dat'
	    fi
	    LM_START_FILE="`eval echo $LM_START_FILEdefault`"
#
	    if [ "$logfile" != "" ]; then
	        LM_LOGFILEmode="$argument"
	        LM_LOGFILE="$logfile"
	        LM_LOGFILE_REDUNDANT="$logfile"
            else
	        LM_LOGFILEmode="$script"
	        LM_LOGFILE="`eval echo $LM_LOGFILEdefault`"
	    fi
#
	    if [ "$LM_LOGFILE_REDUNDANT" != "" ]; then
                LM_LOGFILE_REDUNDANTmode="$argument"
	        LM_LOGFILE_REDUNDANT="$logfile"
	    else
                LM_LOGFILE_REDUNDANTmode="$script"
	        LM_LOGFILE_REDUNDANT="`eval echo $LM_LOGFILE_REDUNDANTdefault`"
	    fi
#
	    if [ "$arglist_lmgrd" != "" ]; then
	        LM_ARGS_LMGRDmode="$argument"
	    else
	        LM_ARGS_LMGRDmode="$script"
	    fi
	    LM_ARGS_LMGRD="`eval echo $LM_ARGS_LMGRDdefault`"
#
	    if [ "$username" != "" ]; then
	        LM_ADMIN_USERmode="$argument"
	    else
	        LM_ADMIN_USERmode="$script"
	    fi
	    LM_ADMIN_USER="`eval echo $LM_ADMIN_USERdefault`"
#
	    if [ "$lmdebug_log" != "" ]; then
	        LM_LMDEBUG_LOGmode="$argument"
	        LM_LMDEBUG_LOG="$lmdebug_log"
            else
	        LM_LMDEBUG_LOGmode="$script"
	        LM_LMDEBUG_LOG="`eval echo $LM_LMDEBUG_LOGdefault`"
	    fi
#
            if [ "$daemon_wait" != "" ]; then
                LM_DAEMON_WAITmode="$argument"
                LM_DAEMON_WAIT="$daemon_wait"
            elif [ "$daemon_wait_init" != "" ]; then
                LM_DAEMON_WAITmode="$script"
                LM_DAEMON_WAIT="$daemon_wait_init"
            else
                LM_DAEMON_WAITmode="$script"
                LM_DAEMON_WAIT="`eval echo $LM_DAEMON_WAITdefault`"
            fi
#
#
	    if [ "$LM_UTIL_MODE" = "1" ]; then
	        LM_RUN_DIRmode="$script"
	        LM_RUN_DIR="`eval echo $LM_RUN_DIRdefault`"
#
	        LM_MARKERmode="$script"
	        LM_MARKER="`eval echo $LM_MARKERdefault`"
	    fi
#
            LM_BOOT_FRAGMENTmode="$script"
	    LM_BOOT_FRAGMENT="`eval echo $LM_BOOT_FRAGMENTdefault`"
        fi
#
        if [ "$verbose" = "1" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo "               License Manager Configuration Information"
echo "               -----------------------------------------"
	    if [ "$SOURCED_DIR" != "" ]; then
echo "->      (lmopts.sh) sourced from directory (DIR = $SOURCED_DIR)"
            if [ "$AUTOMOUNT_MAP" != "" ]; then
                SOURCED_DIReval=`echo $SOURCED_DIReval $AUTOMOUNT_MAP | awk '
                  {if (substr($1,1,length($2)) == $2)
                     if (NF == 4)                               # a -> b
                         print $NF substr($1,length($2) + 1)
                     else                                       # a ->
                         print substr($1,length($2) + 1)
                     else
                         print $1}'`
            fi
echo "->      DIR = $SOURCED_DIReval"
	    else
echo "->      (lmopts.sh) not found."
	    fi
echo '------------------------------------------------------------------------'
echo '        a = argument e = environment o = options_file  s = script'
echo '------------------------------------------------------------------------'
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            if [ "$LM_UTIL_MODE" = "1" ]; then
echo "->  $LM_UTIL_MODEmode  LM_UTIL_MODE         = 1 (MathWorks)"
            else
echo "->  $LM_UTIL_MODEmode  LM_UTIL_MODE         = 0 (Flexera)"
            fi
echo "->  $LM_ROOTmode  LM_ROOT              = $LM_ROOT"
echo "->  $AUTOMOUNT_MAPmode  AUTOMOUNT_MAP        = $AUTOMOUNT_MAP"
echo "->  $ARCHmode  ARCH                 = $ARCH"
echo "->  $LM_FILEmode  LM_FILE              = $LM_FILE"
echo "->  $LM_START_FILEmode  LM_START_FILE        = $LM_START_FILE"
echo "->  $LM_LOGFILEmode  LM_LOGFILE           = $LM_LOGFILE"
echo "->  $LM_LOGFILE_REDUNDANTmode  LM_LOGFILE_REDUNDANT = $LM_LOGFILE_REDUNDANT"
echo "->  $LM_ARGS_LMGRDmode  LM_ARGS_LMGRD        = $LM_ARGS_LMGRD"
echo "->  $LM_ADMIN_USERmode  LM_ADMIN_USER        = $LM_ADMIN_USER"
echo "->  $LM_LMDEBUG_LOGmode  LM_LMDEBUG_LOG       = $LM_LMDEBUG_LOG"
echo "->  $LM_DAEMON_WAITmode  LM_DAEMON_WAIT       = $LM_DAEMON_WAIT"
            if [ "$LM_UTIL_MODE" = "1" ]; then
echo "->  $LM_RUN_DIRmode  LM_RUN_DIR           = $LM_RUN_DIR"
echo "->  $LM_MARKERmode  LM_MARKER            = $LM_MARKER"
            fi
echo "->  $LM_BOOT_FRAGMENTmode  LM_BOOT_FRAGMENT     = $LM_BOOT_FRAGMENT"
echo "->  e   PATH                 = $PATH"
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        fi
#
	if [ "$help" != "1" ]; then
	    setlockfile
#
	    check_binaries
	    if [ $? -ne 0 ]; then
		exit 1
	    fi
#
	    check_portathost
#
	    LM_NSERVERS=0
#
	    if [ "$ck_licensefile" = "1" ]; then
		check_licensefile
		if [ $? -ne 0 ]; then
		    exit 1
		fi
	    fi
#
	    if [ "$ck_writelogfile" = "1" ]; then
		check_writelogfile
		if [ $? -ne 0 ]; then
		    exit 1
		fi
	    fi
#
# Export the variables
#
	    export LM_SET_ENV
#
            export LM_UTIL_MODE
            export LM_ROOT
            export AUTOMOUNT_MAP
	    export ARCH
            export LM_FILE
            export LM_START_FILE
            export LM_LOGFILE
            export LM_LOGFILE_REDUNDANT
	    export LM_ARGS_LMGRD
	    export LM_ADMIN_USER
	    export LM_LMDEBUG_LOG
	    export LM_DAEMON_WAIT
#
            export LM_RUN_DIR
            export LM_MARKER
#
	    export LM_BOOT_FRAGMENT
#
	    export LM_NSERVERS
	    export LM_PORTATHOST
#
	    export LM_LOCKFILE
        fi
    fi
