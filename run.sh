#!/usr/bin/env sh

if [ "$1check" = "check" ]; then
	echo "debes especificar un proyecto (bitbucket.org/acbapis/{proyecto}"
	exit 1
fi

cd $GOPATH/src/$1
if [ "$2check" = "check" ]; then
	make all
else
	make $2
fi
