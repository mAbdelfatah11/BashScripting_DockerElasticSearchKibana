#!/bin/bash


# Variables
#####################################

py=$1
script_wdir="$(pwd)"
es_dir="$HOME/env/opendistro_es"
qna_dir="$HOME/env/qna"
ar_sent_dir="$HOME/env/ar_sent"
en_sent_dir="$HOME/env/en_sent"
es_cont="odfe-node1"
es_auth_file="es_auth.sh"
#disk_serial=$(sudo lsblk --nodeps -o name,serial | tail -1 | awk -F " " '{print $2}')
disk_serial="5916P1XFT"
encr_repo="$HOME/env/widebot.AI.encryption-script"
qna_svc="qna"
ar_sent_svc="ar-sentiment"
en_sent_svc="en-sentiment"


# Functions
#####################################

function prereq_files(){

     echo -e "\nInstalling Required Files"
     echo -e "-----------------------------------------"
       #Create required dires
        if [[ ! -d "$1 || $2 || $3 || $4" ]]; then mkdir -p $1 $2 $3 $4;  fi
       #ES Compose file
        if [[ ! -f "$1/docker-compose.yml" ]]; then echo "";
                read -p "Pass in the ElasticSearch Compose file location [Current: s3://widebot-ai/qna/qna-deployment/docker-compose.yml] > " compose_file
                aws s3 cp $compose_file $1
        fi

       #Qna_Sentiment .env files
       s3_resources=(
	        "${qna_dir}/.env"
	        #"${qna_dir}/docker-compose.yml"
	        #"${ar_sent_dir}/docker-compose.yml"
        	"${ar_sent_dir}/.env"
        	"${en_sent_dir}/.env"

	       )
	       for s3_file in "${s3_resources[@]}"; 
	       do
		       if [[ ! -f $s3_file ]]; 
		       then
			       echo -e "\nInstalling .env file for $s3_file \n--------------------- ";
			       read -p "Pass in file URI in S3 [ ex: s3://widebot-ai/{object-location} ] > " loaded_file;
			       save_dir=$(echo ${s3_file} | cut -d "/" -f 1-5)
              	       	       aws s3 cp $loaded_file ${save_dir}  --region us-east-1
		       else
			       echo "Prerequesites file: ${s3_file} has been already installed...!"
		       fi
	       done
       }


function deploy_es(){

        echo -e "\nDeploying ElasticSearch & Kibana"
        echo -e "-----------------------------------------"
       #deploy
        chk_docker=$(docker ps | grep -m 1 ${es_cont})
        if [[ ! $chk_docker ]]; then

                #anticipate exit:78 failure due to heap issue
                sudo sysctl -w "vm.max_map_count=262144"
                sudo chmod og+w /etc/sysctl.conf
	#	disk_serial=$(sudo lsblk --nodeps -o name,serial | tail -1 | awk -F " " '{print $2}')
                echo 'vm.max_map_count=262144' >> /etc/sysctl.conf
                cd ${es_dir}
                sudo docker-compose down;
                sudo docker-compose up -d;
                echo -e "\nWaiting for ELasticSearch to be Initiated in 20 sec..."; sleep 20;
        fi
        #return to the script work dir
         cd $script_wdir

        chk_es_running=$(docker inspect ${es_cont} --format "{{.State.Running}}"  2>/dev/null)
        if [[ $chk_es_running == "true" ]]; then
                echo -e "\nElasticSearch has been initialted successfully\n";
                sleep 2
               #Setting up .env file: serial key+ES-user        
                Qna_Sent_envfiles
        else
                echo -e "\nFor some reason, ElasticSearch hasn't been initiated"
                exit 1
                #watch -g "docker ps"
        fi
}





function Qna_Sent_envfiles(){

                echo -e "\nConfiguring .env files, Applying Encryption...!"
                echo -e "-----------------------------------------"
                sleep 2
                echo -e "Creating a New user with hashed Password in ElasticSearch...\n"
    #array of files
    ef=(
        "${qna_dir}/.env"
        "${ar_sent_dir}/.env"
        "${en_sent_dir}/.env"
    )
	echo -e "\nList of Qna and Sentiment Environment files to be synced and encrypted\n"
	for item in "${ef[@]}"
	do
    		echo $item
	done
	sleep 2
    for env_file in "${ef[@]}"; do
	 if_decrypted=$(file ${env_file} | grep -i "ASCII")
	 if [[ -f ${env_file} && "${if_decrypted}" ]];
	    then
		    if [[ ${env_file} == "${qna_dir}/.env" ]];
		    then
			    echo "------------------------------------------"
			    echo -e "Configuring QnA .env for ElasticSearch user and Call Encryption!!!!!!!!\n"
			    sleep 2
			    echo -e "Current env file: ${env_file}\n"
			    qna_env_config
		    fi
		    if [[ ${env_file} == "${ar_sent_dir}/.env" ]] || [[ ${env_file} == "${en_sent_dir}/.env" ]];
		    then
			    echo "------------------------------------------"
			    echo -e "Configuring Sentiment .env for Disk Serial and Call Encryption!!!!!!!!!\n"
			    sleep 2
			    echo -e "Current env file: ${env_file} is QnA\n"
			    sent_env_config "${env_file}" "${disk_serial}"
		    fi
	 fi
	 if [[ -f ${env_file} && -z "${if_decrypted}" ]];
	 then
		 if [[ ${env_file} == "${qna_dir}/.env" ]];
		 then
			 echo
			 echo "----------------------------------------------------" 
                         echo "The Qna .env file: ${env_file} Already Encrypted,.."
			 echo "[Note:] If you need to add a new ElasticSearch User in .env file, you have to Decrypt it,.."
			 echo -n "Pass [y] for Decryption or [n] for proceeding directly in QnA Deployment > "
			 read decr ;
                         if [[ ${decr} == "n" ]]; then 
				        echo -e "\nQnA Deployment\n-------------------------"
                                        QnA_deployment
			 else
			    	 echo "------------------------------------------"
                                 echo -e "Decrypting ${env_file}......!\n";
				 envfiles_decryption 
                                 echo -e "\nreConfiguring QnA .env & ElasticSearch with a new ES user\n";  
				 sleep 2
				 qna_env_config
			 fi
		 fi
		 if [[ ${env_file} == "${ar_sent_dir}/.env" ]] || [[ ${env_file} == "${en_sent_dir}/.env" ]];
			 then
				 echo "---------------------------------------------------------"
				 echo "The Sentiment .env file: ${env_file} Already Encrypted,.."
				 echo -n "[Note] if you just need to Decrypt, Pass [y] for Decryption or [n] for proceeding in Deployment > ";
				 read decr ;
				 if [[ $decr == "n" ]]; then

					 if [[ ${env_file} == "${ar_sent_dir}/.env" ]]; then

					 	 echo -e "\nArabic Sentiment Deployment\n----------------------"; Ar_Sent_deploy;
					 else
					 	 echo -e "\nEnglish Sentiment Deployment\n----------------------"; En_Sent_deploy;
					 fi

				 else
                                	 echo -e "\nDecrypting ${env_file}....\n"; envfiles_decryption ;

				 fi
		 fi
	 fi
	
 done


}


qna_env_config() {

                                read -p "pass in the ElasticSearch new username > " es_user
                                qnamarker="#qna-envfile-Configured-with-the-Following-ES-user:${es_user}"
                                #Checking if the same user already added or not
                                if grep -Fxq "${qnamarker}" "${env_file}"; then
                                        echo -e "\nFile: ${env_file} already configured and synced with the same requested User: ${es_user}"
                                        echo -e "\nEncrypting ${env_file} ......!"
                                        envfiles_Encryption
					echo -e "\nQnA Deployment\n-------------------------"
					QnA_deployment
                                else
					#read user password
                                	read -p "pass in the user Password [Note: Numbers Not allowed, just chars ] > " es_pass
                                        #Executing es_auth script to Add ES username and password to ES internal users file.
                                        sudo docker exec "${es_cont}" bash -c "rm /tmp/es_auth*" >> es_auth_ScriptOutput.txt
                                        sudo docker cp $(pwd)/${es_auth_file} ${es_cont}:/tmp/
                                        sudo docker exec "${es_cont}" bash -c ". /tmp/${es_auth_file} ${es_user} ${es_pass}" >> es_auth_ScriptOutput.txt
                                        #Syncying qna .env file with the new user Credentials.
					es_line="'https://${es_user}:${es_pass}@172.17.0.1:9200'"
                                        sudo sed -i "/^#qna-envfile.*$/d" ${env_file}
                                        sudo sed -i "/^ES_CONNECTION.*$/d" ${env_file}
					echo -e "$qnamarker\nES_CONNECTION_LINE=${es_line}" >> ${env_file}
                                        sudo sed -i "s/^DISK_SERIAL.*$/DISK_SERIAL=${disk_serial}/g" ${env_file}

                                        #Encrypting the QnA .env File
                                        if grep -Fxq "${qnamarker}" "${env_file}"; then
                                                echo -e "\nQna .env file has just synced with ES user: ${es_user}, >"
                                                grep -i "ES_CONNECTION_LINE" ${env_file}
                                                echo -e "\nEncrypting ${env_file} ....!"
						sleep 2
						envfiles_Encryption
						echo -e "\nQnA Deployment\n-------------------------"
						QnA_deployment

                                        else
                                                echo -e "\nCould not Encrypt the QnA .env file: ${env_file}, check if the ES user Credentials added correctly in the previous step or not"
                                        fi

                                fi

					}


sent_env_config() {

        sentmarker="#envfile-added-with-serial-${disk_serial}"
	if grep -i "${sentmarker}" "$1"; then
             echo -e "\nFile: ${1} already configured with disk serial"
             echo -e "\nEncrypting ${1} ....!"
	     envfiles_Encryption
	     echo -e "\nSentiment Deployment\n-------------------------"
	     if [[ ${env_file} == "${ar_sent_dir}/.env" ]]; then
		     echo -e "\nArabic Sentiment Deployment\n----------------------"; Ar_Sent_deploy;
	     else
		     echo -e "\nEnglish Sentiment Deployment\n----------------------"; En_Sent_deploy;
	     fi
	else
                #Adding serial key to sentiment .env files.
		sudo sed -i "s/^DISK_SERIAL.*$/${sentmarker}\nDISK_SERIAL=$2/g" $1
		if grep -i "${sentmarker}" "$1"; then
                      	echo -e "\nDisk serial was not configured on:${1}, then added successfully"
			sleep 1
                        echo -e "\nEncrypting ${1} .....!"
			envfiles_Encryption
	     		echo -e "\nSentiment Deployment\n-------------------------"
			if [[ ${env_file} == "${ar_sent_dir}/.env" ]]; then
                     		echo -e "\nArabic Sentiment Deployment\n----------------------"; Ar_Sent_deploy;
             		else
                     		echo -e "\nEnglish Sentiment Deployment\n----------------------"; En_Sent_deploy;
			fi
		fi

	fi

				}


function envfiles_Encryption() {
	
	sleep 2
        if [[ ! -d ${encr_repo} ]]; then
                echo "Tryed to Encrypt .env file: ${env_file},But Encryption Respository was Not found, Have you run the previous deployment script?!"
        else
                echo  "Pass in the Encryption key.."
                python${py} ${encr_repo}/main.py encrypt ${env_file} --prompt
		sleep 2
                echo -e "\n${env_file}  has been encrypted....!"


        fi
}

function envfiles_decryption() {
	
	sleep 2
        if [[ ! -d ${encr_repo} ]]; then
                echo "Trying to Encrypt .env files,But Encryption Respository Not found, Have you run the previous deployment script?!"
        else
                echo  "Pass in the Decryption key.."
                python${py} ${encr_repo}/main.py decrypt ${env_file} --prompt
		sleep 2
                echo -e "\n${env_file}  has been Decrypted....!"


        fi
}


function ecr_repo_auth() {

        echo -e "\nECR-AUTHENTICATION"
        echo -e "-----------------------------------------"
        sleep 1

        echo -e "\nAuthenticating to AWS ECR repository...\n"
        read -p "Pass in the Repository_Name you want to authenticate [EX.: 074697765782.dkr.ecr.us-east-1.amazonaws.com/qna]: " ECR_REPO
        read -p "Pass in the Image_Tag or version you want to pull from the above Repository_Name [EX.: on-prem]: " IMG_TAG
        read -p "Please Pass in your default.region: " AWS_REGION

        if [ -n $ECR_REPO -a -n $IMG_TAG -a -n $AWS_REGION ];
        then
                echo -e "\nChecking the Availability of the requested Image with Current ECR token......\n"
                sleep 2
                docker pull $ECR_REPO:$IMG_TAG
                RESULT=$?
                if [[ $RESULT == 0 ]];
                then
                        echo -e "\nDocker image pulled successfully using existing ECR authentication token\n----------------"
                else
                        echo -e "\nExisting ECR authentication token not valid, Fetching a new token...\n"

                        docker login -u AWS -p $(aws ecr get-login-password --region $AWS_REGION) $ECR_REPO
                        echo -e "\nPulling Image tag...\n"
                        docker pull $ECR_REPO:$IMG_TAG
                fi
        fi
}

function QnA_deployment() {
	sleep 2
	chk_qna_img=$(docker image ls | grep -m 1 ${qna_svc})
        if [[ ! $chk_qna_img ]]; then

		ecr_repo_auth
		wait
	fi
		#cd ${qna_dir}
		echo -e "\nQnA Docker Deployment"
		docker rm -vf ${qna_svc}
		docker run -dp 8081:8081 --name ${qna_svc} \
			-v ${qna_dir}/.env:/qna/.env \
			-v ${qna_dir}/logs/:/qna/logs \
			-v /run/udev:/run/udev:ro \
			--privileged --pid=host 074697765782.dkr.ecr.us-east-1.amazonaws.com/qna:on-prem
	
	#docker-compose down
	#docker-compose up -d
}


function Ar_Sent_deploy() {
        sleep 2
        chk_arsent_img=$(docker image ls | grep -m 1 ${ar_sent_svc})
        if [[ ! $chk_arsent_img ]];
        then
                ecr_repo_auth
        fi

        #cd ${ar_sent_dir}
        docker rm -vf ${ar_sent_svc} 
        docker run -dp 8084:8084 --name ${ar_sent_svc} \
                -v ${ar_sent_dir}/.env:/ar-multi-sentiment-analysis/.env \
                -v ${ar_sent_dir}/logs/:/ar-multi-sentiment-analysis/logs \
                074697765782.dkr.ecr.us-east-1.amazonaws.com/ar-sentiment:on-prem


}


function En_Sent_deploy() {
	sleep 2
        chk_ensent_img=$(docker image ls | grep -m 1 ${en_sent_svc})
        if [[ ! $chk_ensent_img ]]; then

                ecr_repo_auth
                wait
        fi

	#cd ${ar_sent_dir}
	docker rm -vf ${en_sent_svc}

        docker run -dp 8085:8085 --name ${en_sent_svc} \
                -v ${en_sent_dir}/.env:/en-multi-sentiment-analysis/.env \
                -v ${en_sent_dir}/logs/:/en-multi-sentiment-analysis/logs \
		074697765782.dkr.ecr.us-east-1.amazonaws.com/en-sentiment:on-prem

}

prereq_files ${es_dir} ${qna_dir} ${ar_sent_dir} ${en_sent_dir}
deploy_es 
Qna_Sent_envfiles
#ecr_repo_auth
