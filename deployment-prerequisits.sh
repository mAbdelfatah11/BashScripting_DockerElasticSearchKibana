#!/bin/bash

# Variables
#####################################
py_v=$1
docker_exec=$(command -v docker)
awscli_exec=$(command -v aws)
awscli_iamcred=$(aws configure --profile default list | grep -x "could not be found")
git_remote_codecommit_pkg=$(command -v git-remote-codecommit)
env_dir="$HOME/env"


# functions
#####################################

function docker_dcompose() {

    echo -e "\nInstalling DOCKER-DOCKERCOMPOSE"
    echo -e "-----------------------------------------"

	#check if docker exists and executable
	if [[ ${docker_exec} ]]; then echo -e "\nDocker version Already Satisfied!!\n"; sleep 1;	
	#=if [[ -x $(command -v docker) ]]; will check if docker has executable, then check if execution ability using -x
	else
		sleep 2
		sudo apt-get update
		deps="sudo apt-get install -y \
			ca-certificates \
			curl \
			gnupg \
			lsb-release"
		eval $deps
		#add docker’s official GPG key
		sudo mkdir -p /etc/apt/keyrings
		gpgkey="curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
		eval $gpgkey	
        
		echo -e "\nSetting up docker stable repository.\n"
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	
		sudo chmod a+r /etc/apt/keyrings/docker.gpg
		
		echo -e "\nupdating the packages...\n"
		sleep 2
		sudo apt-get update -y

		#checks installation from the Docker repo instead of the default Ubuntu repo:
		sudo apt-cache policy docker-ce -y

		#installing dcoker through docker-ce
	        dockr="sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin"
		eval $dockr
		echo -e "\nInstalling docker-compose\n"
		sleep 2
		sudo apt install docker-compose -y
       
		#adds your username to the docker group
		sudo usermod -aG docker ${USER}
       		#check
		if [[ ${docker_exec} ]]; then
		       	echo -e "\ndocker successfully installed===============================\n"; 
		       	sleep 1
	       	fi
	fi
}


##Install aws-cli

function aws_cli() {
	echo -e "\nInstalling AWS-CLI"
        echo -e "-----------------------------------------"
	sleep 1
	echo -e "\nchecking aws installation...\n"
	if [[ ${awscli_exec} ]];
	then
		echo -e "\nAws-Cli Version Already Satisfied!!\n"
	else
		echo "installing aws-cli ......."
		sudo apt-get update -y
		sudo apt-get install awscli -y
		if [[ ${awscli_exec} ]]; then
		       	echo -e "\nSuccessfully Installed AWS-cli with version: ${awscli_exec} \n=================\n";
	       	fi
	fi
}


##Authenticate to AWS 

function aws_cli_auth() {

        echo -e "\nAWS-IAM-AUTHENTICATION"
        echo -e "-----------------------------------------"
        sleep 1
	chk_awscli_credentials=$(grep -i "default" ~/.aws/credentials)
	if [[ $? != 0 ]]; then 
		echo "Pass in the required Credentials to create or update the IAM-Profile > ";
	  sleep 1
	  read -p "Pass your aws_access_key_id: " AWS_ACCESS_KEY_ID
	  read -p "Pass your aws_secret_access_key: " AWS_ACCESS_KEY_SECRET
	  read -p "Pass your default.region: " AWS_REGION
	  
	  if [ -n "$AWS_ACCESS_KEY_ID" -a -n "$AWS_ACCESS_KEY_SECRET" -a -n "$AWS_REGION" ];
	  then
	  	aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
          	aws configure set aws_secret_access_key "$AWS_ACCESS_KEY_SECRET"
           	aws configure set default.region "$AWS_REGION"
          	#aws configure set region $AWS_REGION --profile onprem
          	#aws configure set default.ca_bundle /path/to/ca-bundle.pem
          	#aws configure set profile.testing2.region eu-west-1
		wait
		sleep 1
		if [[ $1 ]]; then echo -e "\nCongrats, you have just connected IAM user to AWS APIs\n"; fi

	  else
		  echo -e "\nOne or all variables is empty, Have you run this script before ?..\n"
		  echo -e "\n===================================================================\n"
	  fi
  	else 
		echo -e "\nDefault IAM profile already staisfied, Proceeding with current IAM user Credentials..!\n"

	fi
}



function git_remote_codecommit() {

	echo -e "\nCodeCommit-AUTHENTICATION"
        echo -e "-----------------------------------------"
        sleep 2
                #git-remote-codecommit: codecommit authentication using current IAM user instead of using dedicated  git credentials.
                #ref: https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-git-remote-codecommit.html
   		echo -e "\nChecking [git-remote-codecommit] if installed...\n"
   		if [[ $1 ]]; then echo -e "\ngit-remote-codecommit Already Satisfied!!!\n"; 
			sleep 2;
		else
           		echo -e "\nInstalling Package!!!"
			echo -e "\nCreating an Isolated Environment for Encryption"
			cd ${env_dir}
			python$2 -m venv env-py$2
			source env-py$2

			sudo apt install git
           		sudo pip$2 install git-remote-codecommit
           		#Check
           		if [[ $1 ]]; then echo -e "\nSuccessfully Authenticated, git-remote-codecommit Version Satisfied!!!!\n"; fi
   fi
}

function install_encrRepo_codecommit() {

	echo -e "\nInstalling Encryption Repository.."
        echo -e "-----------------------------------------"
        sleep 2
		#don't use sudo here as we have no aws credntials for root
		if [[ ! -d ${1} ]]; then mkdir -p ${1}; fi
                read -p "Please enter Encryption Repository Name in codecommit [current: widebot.AI.encryption-script ] > " encr_repo
		if [[ -d ${1}/${encr_repo} ]]; then 
			echo "Encryption Repositry Already Cloned Before!!"; 
		else
		    if [[ -x ${2} ]]; then
                	cd ${1}
                	git clone codecommit::us-east-1://$encr_repo $encr_repo
                	cd $encr_repo
                	sudo pip$3 install -r requirements.txt
			if [[ -d ${1}/${encr_repo} ]]; then echo "Encryption Repositry has been Cloned Successfully !!"; fi 
		    fi
		fi
	}





#####################################

docker_dcompose
aws_cli 
aws_cli_auth 
git_remote_codecommit ${git_remote_codecommit_pkg} ${py_v}
install_encrRepo_codecommit ${env_dir} ${git_remote_codecommit_pkg} ${py_v}
