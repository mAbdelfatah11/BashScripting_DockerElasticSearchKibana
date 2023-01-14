#/bin/bash


# Variables
#################

es_user=$1
es_pass=$2
users_file="/usr/share/elasticsearch/plugins/opendistro_security/securityconfig/internal_users.yml"
hash_tool="/usr/share/elasticsearch/plugins/opendistro_security/tools/hash.sh"
espass_hash=$(/bin/sh ${hash_tool} -p ${es_pass})

echo $es_user
echo $es_pass
echo ${espass_hash}


# Logic
#################
    users_marker="#user ${es_pass} added to ES admins"

    uf=(
        "${users_file}"
    )
    for users_file in "${uf[@]}"; do
        if [ -f "${users_file}" ]; then
            if grep -Fxq "$users_marker" "${users_file}"; then
                echo -e "\nUsers file Already configured Before with User: ${es_user}\n"

            else
		    cat <<EOT >> /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/internal_users.yml
#user ${es_user} added to ES admins
${es_user}:
  hash: ${espass_hash}
  reserved: true
  backend_roles:
  - "admin"
  description: "Main admin user"
EOT
		wait
		cd /usr/share/elasticsearch/plugins/opendistro_security/tools
	
		security_update="./securityadmin.sh -cd ../securityconfig/ -icl -nhnv \
			-cacert ../../../config/root-ca.pem \
			-cert ../../../config/kirk.pem \
			-key ../../../config/kirk-key.pem \
			--accept-red-cluster"
		eval ${security_update}
            fi
        fi

done

