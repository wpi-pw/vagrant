#!/usr/bin/env bash
#
# vagrant_up provisioning file
#
# Author: Dima Minka
#
# File version 1.1.2

# Define colors
RED='\033[0;31m' # error
GRN='\033[0;32m' # success
BLU='\033[0;34m' # task
BRN='\033[0;33m' # headline
NC='\033[0m' # no color

# Define custom config if exist
if [[ -f wpi-custom.yml ]]; then
	wpi_config="/home/vagrant/config/wpi-custom.yml"
else
  wpi_config="/home/vagrant/config/wpi-default.yml"
fi

# YAML parser function
parse_yaml() {
    local yaml_file=$1
    local prefix=$2
    local s
    local w
    local fs

    s='[[:space:]]*'
    w='[a-zA-Z0-9_.-]*'
    fs="$(echo @|tr @ '\034')"

    (
        sed -e '/- [^\“]'"[^\']"'.*: /s|\([ ]*\)- \([[:space:]]*\)|\1-\'$'\n''  \1\2|g' |

        sed -ne '/^--/s|--||g; s|\"|\\\"|g; s/[[:space:]]*$//g;' \
            -e "/#.*[\"\']/!s| #.*||g; /^#/s|#.*||g;" \
            -e "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
            -e "s|^\($s\)\($w\)${s}[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" |

        awk -F"$fs" '{
            indent = length($1)/2;
            if (length($2) == 0) { conj[indent]="+";} else {conj[indent]="";}
            vname[indent] = $2;
            for (i in vname) {if (i > indent) {delete vname[i]}}
                if (length($3) > 0) {
                    vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
                    printf("%s%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, conj[indent-1],$3);
                }
            }' |

        sed -e 's/_=/+=/g' |

        awk 'BEGIN {
                FS="=";
                OFS="="
            }
            /(-|\.).*=/ {
                gsub("-|\\.", "_", $1)
            }
            { print }'
    ) < "$yaml_file"
}

# root user change
noroot() {
  sudo -EH -u "vagrant" "$@";
}

# Read config
eval $(parse_yaml $wpi_config "conf_")

if [ "$conf_vm_box" == "wpi/box" ]; then
  # Basic provison for new box
  echo "=============================="
  echo "You can replace $conf_wpi_user with your username & $conf_wpi_email by your email in wpi-config.yml"
  echo "=============================="
  sudo chown vagrant:vagrant /home/vagrant/.[^.]*
  sudo echo -e "source ~/.bashrc\n" >> /home/vagrant/.bash_profile 2>/dev/null
  sudo echo -e "[user]\n\tname = $conf_wpi_user\n\temail = $conf_wpi_email" > /home/vagrant/.gitconfig

  echo "=============================="
  echo "Copy gitconfig and bash_profile to www-data directory"
  echo "=============================="
  sudo cp /home/vagrant/{.gitconfig,.bash_profile} /home/vagrant/apps
  sudo chown www-data:www-data /var/www/.[^.]*

  echo "=============================="
  echo "copy keys from vagrant directory to www-data and root"
  echo "=============================="
  ssh-keyscan -H bitbucket.org >> /home/vagrant/.ssh/known_hosts 2>/dev/null
  ssh-keyscan -H github.com >> /home/vagrant/.ssh/known_hosts 2>/dev/null
  sudo cp -r /home/vagrant/.ssh /home/vagrant/apps/.ssh
  sudo chown -R www-data:www-data /home/vagrant/apps/.ssh

  echo "=============================="
  echo "move files to vagrant apps and make the symlink"
  echo "=============================="
  sudo mv /var/www/{.,}* /home/vagrant/apps 2>/dev/null
  sudo mv /var/www /var/www-disabled 2>/dev/null
  sudo ln -s /home/vagrant/apps /var/www
fi
