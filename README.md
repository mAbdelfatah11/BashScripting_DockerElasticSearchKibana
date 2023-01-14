# Bash Scripting Approach for Docker Services, ElasticSearch & Kibana Deployment

Before starting: 
- ship scripts code to the client machine.
- Prepare all the aws required credentials which are, IAM user with limited ECR,S3 & codecommit access.

Kindly Follow the steps in order:

#### Create Dedicated user - security wise:
Execute the First bash script called: createuser.sh

	>$ sudo su && bash createuser.sh
  
it should create a new user with sudo privileges to manage all deployment instead of root user which might lead to a security concern from clients.

#### Setup a Stable Environment for Python Compatible Packages

Execute the Second Bash script called: python-compile-source.sh

	>$(WB-Services) >$  bash python-compile-source.sh 3.8.10        
  (_Note: I'm using WB-Services user now_)

- The script should create a dedicated python environment compatible with Encryption application packages. 
- The above passed parameter “3.8.10”: indicates the most suitable version of python which was recommended by the AI-team for Environment Encryption and Deployment.

Note: the most important thing about this script is, “this version of python may be changed later based on request from ai-team, so you just need to replace the current version with the new one, and re-execute the script to create a new environment, which will not force any packages dependency issue with the old one.

#### Deployment Prerequisites Packages

Execute the third Bash script called: Deployment-Prerequisits.sh

	>$(WB-Services) >$  bash  deployment-prerequisits.sh 3.8
  
  (Note: the passed parameter “3.8”: refers to the current used python version.)
  
It should do the following:
- updating packages
- install docker & docker-compose
- install AWS CLI
- Interactive Authentication to CLI & AWS APIs
- Install  git-remote-codecommit Utility, which should be used for Codecomit authentication without a dedicated git credentials & with current iam credentials.
- Interactive Authentication to CodeCommit & AWS APIs. 
- Install Encryption Repository, that required for docker mounted volumes encryption before deployment.

Important Note: while it asks you for aws cli credentials, pass in the IAM credentials for user you have already prepared as a pre-requesite.

#### Deployment for Docker services & Kibana with ELasticSearch

Execute the fourth script called: services-deployment.sh

	>$(WB-Services) >$  bash  wb-services-deployment.sh 3.8
  
  (Note: the passed parameter “3.8”: refers to the current used python version.)

It should do the following:
- Create the required directories and sub-dires system for deployment.
- Install the required environment Files “.env” from S3, that files required by Docker services as a volume mounts.
- ElasticSearch & kibana docker deployment “recurring deployment based on state”
- Automated Configuration for ElasticSearch with an internal user for qna.
- Automated Encryption & Decryption of the Environment .env files for each service based on the state.
- Deployment for Docker services.
