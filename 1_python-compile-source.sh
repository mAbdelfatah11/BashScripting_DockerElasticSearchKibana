#! /bin/bash

######################################
# Python Install - compile from source with SSL module, pip TLS/ SSL
######################################


# variables
#####################################
version=$1
#https://www.python.org/ftp/python/
source_url="https://www.python.org/ftp/python/${version}/Python-${version}.tgz"
source_dir="/usr/local/python-source" 
openssl_dir="/usr"  


#Array of prerequesites
package_list=(
      #automake               
    build-essential               
    checkinstall                        
    zlib1g-dev                        
    libncurses5-dev         
    libgdbm-dev                         
    libnss3-dev                        
    libssl-dev                          
    libreadline-dev                    
    libffi-dev                          
    libsqlite3-dev                      
    libbz2-dev    
    
)

# functions
#####################################
function package_install(){
    
    if  [[ $1 ]]; then eval "declare -A PACKAGE_LIST="${1#*=}; fi

    echo -e "\nDEPENDENCIES"
    echo -e "-----------------------------------------"
    
    for package in "${PACKAGE_LIST[@]}"; do 
        if [[ $package != "" ]]; then
        
            verify=$(dpkg -s $package)
            if [[ ${verify} =~ (Status: install ok) ]]; then
                echo -e "${package} is installed"

            else
                sudo apt install ${package} -y

            fi

            unset package
            unset verify

        fi

    done
}

function python_version() {

    if  [[ $1 ]]; then VERSION=$1; fi    

    #echo -e "\nchecking python installation"
    #echo -e "-----------------------------------------"
    
    # first digit, example: 3
    # for 'python3' or future 'python4'
    # will give you the current version of python that is set
    v=$(echo $VERSION | sed -r 's/^[^0-9]*([0-9]+).*$/\1/')
    
    # first 2 digits, example: 3.7
    # to check for a specific version of python or pip - might not be the same current version that is set
    # like the version you have just compiled but not yet set
    # to avoid bash errors we'll run the version check after we have compiled
    vv=$(echo $VERSION | sed -r 's/^[^0-9]*([0-9].[0-9]).*$/\1/')
    #last 3 digits not using this
    #vvv=$(echo $current_version | sed -nre 's/^[^0-9]*(([0-9]+\.)*[0-9]+).*/\1/p')
    
    # full string of version check
    # safe to run this now without bash errors since Debian/ Ubuntu comes pre-installed with python
    current_python_version=$(python${v} -V)
    current_pip_version=$(pip${v} -V)
    
    # installed versions
    # return a list of all installed versions of python
    all_python_versions=$(ls /usr/local/lib | grep python)
    all_pip_versions=$(whereis pip${v})
    
}

function python_source_download (){
    
    # list of releases
    
    if  [[ $1 ]]; then VERSION=$1; fi    
    if  [[ $2 ]]; then SOURCE_URL=$2; fi    
    if  [[ $3 ]]; then SOURCE_DIR=$3; fi    

    echo -e "\nDOWNLOAD SOURCE"
    echo -e "-----------------------------------------"
    python_version ${VERSION}
    # before starting install, print to the terminal what current versions are installed 
    if [[ $current_python_version ]]; then echo -e "current python version is set to: ${current_python_version}"; fi
    if [[ $current_pip_version ]]; then echo -e "current pip3 version is set to: ${current_pip_version}"; fi
    if [[ $all_python_versions ]]; then echo -e "all python versions installed:" ${all_python_versions}; fi
    if [[ $all_pip_versions ]]; then echo -e "all pip3 versions installed:" ${all_pip_versions}; fi
    
    if [[ "${current_python_version}" != "${VERSION}" ]]; then
        
        source_file=$(echo ${SOURCE_URL##*/})

        if [ ! -d ${SOURCE_DIR} ]; then
            sudo mkdir ${SOURCE_DIR}
        fi
        
        if [ ! -f "/tmp/${source_file}" ]; then
            wget -P /tmp "${SOURCE_URL}"
        fi
        
        unpacked_dir="${source_file%.*}" 
        target_dir="${SOURCE_DIR}/${unpacked_dir}"
        if [ -d ${SOURCE_DIR} ] && [ ! -d "${target_dir}" ]; then
            sudo tar -xzvf "/tmp/${source_file}" -C "${SOURCE_DIR}"

        fi
        
        if [ -d "${target_dir}" ]; then
            echo -e "source location: ${target_dir}"
        fi

    else 
        echo -e "already installed: ${VERSION}" 

    fi

}

function python_openssl() {

    if  [[ $1 ]]; then OPENSSL_DIR=$1; fi    
    if  [[ $2 ]] && [ $2 != "" ]; then TARGET_DIR=$2; fi    
    
    echo -e "\nPYTHON OPENSSL (modify file setup file)"
    echo -e "-----------------------------------------"
    
    # adding a commented marker upon changing the file makes it easier to look for an ID informing it was already changed
    mymarker="#enabled-my-custom-ssl-${OPENSSL_DIR}"
    
    # 'Setup.dist' creates Setup
    sf=(
        "${target_dir}/Modules/Setup.dist"
        #"${target_dir}/Modules/Setup"
    )
    
    for setup_file in "${sf[@]}"; do 
        if [ -f "${setup_file}" ]; then
            if grep -Fxq "$mymarker" "${setup_file}"; then
                echo -e "file already configured: ${setup_file}"
                
            else
                myopenssl_dir=${OPENSSL_DIR}
                sudo sed -i 's@#_socket socketmodule.c@_socket socketmodule.c@g' ${setup_file}              
                sudo sed -i "s@#SSL=/usr/local/ssl@${mymarker}\nSSL=${myopenssl_dir}@g" ${setup_file}              
                sudo sed -i 's@#_ssl _ssl.c \\@_ssl _ssl.c \\@g' ${setup_file}              
                sudo sed -i 's@#\t-DUSE_SSL -I$(SSL)/include -I$(SSL)/include/openssl \\@\t-DUSE_SSL -I$(SSL)/include -I$(SSL)/include/openssl \\@g' ${setup_file}              
                sudo sed -i 's@#\t-L$(SSL)/lib -lssl -lcrypto@\t-L$(SSL)/lib -lssl -lcrypto@g' ${setup_file}              

                echo -e "updated: ${setup_file}"
                
            fi
        
        fi
    done

}

function python_configure() {

    if  [[ $1 ]]; then VERSION=$1; fi    
    if  [[ $2 ]] && [ $2 != "" ]; then TARGET_DIR=$2; fi    
    if  [[ $3 ]]; then OPENSSL_DIR=$3; fi    
    
    echo -e "\nPYTHON CONFIGURE (Makefile)"
    echo -e "-----------------------------------------"
    python_version ${VERSION}
    
    if [ ! -f "${TARGET_DIR}/Makefile" ]; then
        cd ${TARGET_DIR}
        
        if [[ $OPENSSL_DIR ]]; then
            # with explicit path to your installation of ssl
            python_openssl "${OPENSSL_DIR}" "${TARGET_DIR}" # and modification of /Modules/Setup.dist
            sudo ./configure --enable-optimizations --with-openssl="${OPENSSL_DIR}"
        
        else
            sudo ./configure --enable-optimizations 

        fi

    else
        echo -e "openssl directory: ${OPENSSL_DIR}"
        echo -e "already exists: ${TARGET_DIR}/Makefile"

    fi
    
}

function python_build() {

    if  [[ $1 ]]; then VERSION=$1; fi    
    if  [[ $2 ]] && [ $2 != "" ]; then TARGET_DIR=$2; fi    
    
    echo -e "\nPYTHON BUILD (install)"
    echo -e "-----------------------------------------"
    python_version ${VERSION}
   
    get_ver="python${vv} -V"
    if output=$($get_ver); then
        echo -e "already installed: ${VERSION}"
        whereis python${VERSION} 
    else
        if [ -f "${TARGET_DIR}/Makefile" ]; then
            cd ${TARGET_DIR}
            
            cores=$(grep -c ^processor /proc/cpuinfo)
            sudo make -j $cores altinstall 

        fi
    
    fi
    
}

#####################################

echo -e "\nValidating Current working Environment for stable Python package version...\n"
current_pyv=$(python3 --version)
current_pyv=$(echo $current_pyv | sed -r 's/^[^0-9]*([0-9].[0-9]).*$/\1/')
if [[ ${current_pyv} == ${version} ]]; 
then
	echo -e "\nCurrent Environment is ready for Deployment with Python version: ${current_pyv} \n"
else
	package_install "$(declare -p package_list)"
	python_source_download "${version}" "${source_url}" "${source_dir}"
	#python_configure "${version}" "${target_dir}"                      # without explicit ssl
	python_configure "${version}" "${target_dir}" "${openssl_dir}"      # with explicit ssl
	python_build "${version}" "${target_dir}"
fi





