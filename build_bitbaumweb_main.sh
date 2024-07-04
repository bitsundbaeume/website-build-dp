#!/bin/bash

#cd $HOME

BRANCH=main
DOMAIN=main.bits-und-baeume.org
USER=bitsundbaeume
WEBROOTSDIR=/var/www/$USER/www
REPO=/var/www/$USER/repositories/bubweb-$BRANCH
LOCKDIR=/var/www/$USER/website_build_lock
LOGDIR=/var/www/$USER/website_build_log

CURRENT=bubweb-$BRANCH-current
NEW=bubweb-$BRANCH-new

LOGFILE=bitbaumweb_build_$BRANCH.log
TIMEOUT=600 # in seconds
PATIENCE=10 # seconds to wait before recheck if other build process has finished


echo "$(date) $BRANCH Build Script triggered" | tee -a $LOGDIR/$LOGFILE

cd $REPO
git fetch
git reset origin/$BRANCH --hard

# Check for concurrent build process
counter=0
while test -f $LOCKDIR/build_process_running.lock
do
        timespent=$(expr $counter \* $PATIENCE)
        echo "$(date) $BRANCH spent $timespent seconds waiting. Now waiting another $PATIENCE seconds for other BUILD to finish." | tee -a $LOGDIR/$LOGFILE
        if [ "$timespent" -gt "$TIMEOUT" ]; then
                echo "$(date) $BRANCH TIME OUT – GIVING UP." | tee -a $LOGDIR/$LOGFILE
                exit
        fi
        sleep $PATIENCE
        ((counter++))
done


# Get Lock
echo "$(date) $BRANCH build process is running" > $LOCKDIR/build_process_running.lock


echo "RUNNING npm install"
echo "==================="
echo ""
echo -n "$(date) $BRANCH Running npm install..." | tee -a $LOGDIR/$LOGFILE
if /usr/bin/npm install; then
        echo "succeeded" | tee -a $LOGDIR/$LOGFILE
else
        echo "failed" | tee -a $LOGDIR/$LOGFILE
fi

echo "RUNNING npm run prepare"
echo "======================="
echo ""
echo -n "$(date) $BRANCH Running npm run prepare ..." | tee -a $LOGDIR/$LOGFILE
if /usr/bin/npm run prepare; then
        echo "succeeded" | tee -a $LOGDIR/$LOGFILE
else
        echo "failed" | tee -a $LOGDIR/$LOGFILE
fi


echo "RUNNING npm build"
echo "================="
echo ""
echo -n "$(date) $BRANCH Running npm run build ..." | tee -a $LOGDIR/$LOGFILE
if /usr/bin/npm run build; then
        echo "succeeded" | tee -a $LOGDIR/$LOGFILE
else
        echo "failed" | tee -a $LOGDIR/$LOGFILE
fi

if test -f $REPO/_site/index.html; then
	cd $WEBROOTSDIR
	mkdir $NEW 
	cp -a $REPO/_site/. $NEW
	ln -s $NEW $DOMAIN
	rm -r $CURRENT
	mv $NEW $CURRENT
	rm $DOMAIN
	ln -s $CURRENT $DOMAIN
	
	if test -f $DOMAIN/index.html; then
		echo "$(date) $BRANCH – Update was published (index.html exists)." | tee -a $LOGDIR/$LOGFILE
	else
		echo "$(date) $BRANCH – ERROR index.html not in $DOMAIN ." | tee -a $LOGDIR/$LOGFILE
	fi

else
	echo "$(date) $BRANCH – UPDATE WAS NOT PUBLISHED BECAUSE index.html DIDN'T EXIST." | tee -a $LOGDIR/$LOGFILE
fi

echo "$(date) $BRANCH Build Script ended." | tee -a $LOGDIR/$LOGFILE

rm $LOCKDIR/build_process_running.lock
