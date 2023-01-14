#!/bin/bash


##Don't FORGET to run this script using $> bash [script-name] if u faced any issues.

        function install_conda {

                echo "start updating repository index...."
		sleep 2
                sudo apt update
		wait

		echo
                sleep 3

		echo "conda installtion starting...."
		echo
                sleep 2

                anaconda_version=2021.11
                anaconda_file="Anaconda3-${anaconda_version}-Linux-x86_64.sh"
                cd
                rm -f ${anaconda_file}*
                rm -rf anaconda3/
                wget https://repo.anaconda.com/archive/${anaconda_file}
                bash ${anaconda_file} -b
                echo "y" | conda update --all

                rm ${anaconda_file}

                unset anaconda_version anaconda_file

                echo "conda installation has just completed successfully"       

        }


	function activate_conda {
                echo "conda already installed and in a version"
		echo
		#sleep 2
                echo
		PS3="Please choose wheither to create a new env, activate existing one or quit : "
                #options=("create" "activate" "Quit")
                select opt in create activate quit;
                do
                        case $opt in
                                "create")
                                        read -p "pass in the name for the new environment" env_name
                                        read -p "pass in the required python version" py_version
					## the following two command should only be run only if the conda already installed.
					#conda create --name $env_name python=$py_version
                                        #conda activate $env_name
					which conda	# for test 
					echo $?			# return 1

					#sudo apt update
					#break #comment here to re-Prompt the choices again.
                                        ;;

                                "activate")
                                        read -p "pass in the name for environment to be activated" env_name
                                        conda activate $env_name
                                        ;;

                                "quit")
                                        break;;
                                *)
                                        echo "invalid option $REPLY"
                                        break;;
                        esac
                done

	
	
	
	}

	function conda {

		echo "Please wait while checking if conda is already installed or not....."
		#sleep 4
		var=$(which conda)	# equal "which conda" without var , but make use of var to hide output.
		if [[ $? = 1 ]];
		then
                	echo "conda is not here,  Preparing for installation...."
			#sleep 3
			install_conda
		else
			echo "Conda already installed"
			activate_conda
		fi
	}
conda
