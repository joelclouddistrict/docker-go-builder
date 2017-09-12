#!/usr/bin/env sh

if [ "$1check" = "check" ]; then
	echo "debes especificar un proyecto (bitbucket.org/acbapis/{proyecto}"
	exit 1
fi

if [ ! -d $GOPATH/src/bitbucket.org/acbapis/acbapis ]; then
	echo "Getting proto definitions from BB"
	git clone git@bitbucket.org:acbapis/acbaspis.git
fi

if [ $? != 0 ]; then
	echo "Asegúrate de haber añadidos los volúmenes:"
	echo " bitbucket.org/acbapis/acbapis"
	echo " o de tener montada la clave SSH /root/.ssh/docker-apis"
	exit
fi

cd $GOPATH/src/$1
make linux && make docker
