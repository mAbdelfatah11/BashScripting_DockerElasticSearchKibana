#!/bin/bash

echo -e "\nScript to automate services startup"
echo "===================================="

echo "\nCleaning up previous docker environments"
dcleanup(){
	docker rm -v $(docker ps --filter status=exited -q 2>/dev/null) 2>/dev/null
	#docker rmi $(docker images --filter dangling=true -q 2>/dev/null) 2>/dev/null		#should be after containers startup
}

#
#usefull while running script multiple times for testing.
#
del_stopped(){
	local cont=$1
	local state=$(docker inspect $cont --format "{{.State.Running}}"  2>/dev/null)

	if [[ "$state" == "false" ]];
	then 
		docker rm -v $cont 2>/dev/null
	else
		"$cont already in running state"
	fi
}


echo "start openseach services"
openSearch(){
        cd $HOME/env/opendistro_es/ && docker-compose down && docker-compose up -d
}


echo "start qna service"
qna(){
	echo "ensure cleanup"
        del_stopped qna 
        echo "start service"
        docker run -dp 8081:8081 --name qna -v $HOME/env/qna/.env:/qna/.env -v $HOME/env/qna/logs:/qna/logs 074697765782.dkr.ecr.us-east-1.amazonaws.com/qna:on-prem
}


ar_sent(){
        del_stopped ar-sentiment
        docker run -dp 8084:8084 --name ar-sentiment -v $HOME/env/ar-sentiment/.env:/ar-multi-sentiment-analysis/.env -v $HOME/env/ar-sentiment/logs:/ar-multi-sentiment-analysis/logs 074697765782.dkr.ecr.us-east-1.amazonaws.com/ar-sentiment:on-prem

}

en_sent(){
	del_stopped en-sentiment
	docker run -dp 8081:8081 --name qna -v $HOME/env/qna/.env:/qna/.env -v $HOME/env/qna/logs:/qna/logs -v /run/udev:/run/udev:ro --privileged --pid=host 074697765782.dkr.ecr.us-east-1.amazonaws.com/qna:on-prem
}


openSearch
qna 
ar_sent
en_sent
