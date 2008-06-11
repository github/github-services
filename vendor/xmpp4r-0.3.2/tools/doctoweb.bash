#!/bin/bash

if [ -z $CVSDIR ]; then
	CVSDIR=$HOME/dev/xmpp4r-web
fi

TARGET=$CVSDIR/rdoc

echo "Copying rdoc documentation to $TARGET."

if [ ! -d $TARGET ]; then
	echo "$TARGET doesn't exist, exiting."
	exit 1
fi
rsync -a rdoc/ $TARGET/

echo "###########################################################"
echo "CVS status :"
cd $TARGET
cvs -q up
echo "CVS Adding files."
while [ $(cvs -q up | grep "^? " | wc -l) -gt 0 ]; do
	cvs add $(cvs -q up | grep "^? " | awk '{print $2}')
done
echo "###########################################################"
echo "CVS status after adding missing files:"
cvs -q up
echo "Commit changes now with"
echo "# (cd $TARGET && cvs commit -m \"rdoc update\")"
exit 0
