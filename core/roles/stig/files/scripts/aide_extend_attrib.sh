# Function to install packages on RHEL, Fedora, Debian, and possibly other systems.
#
# Example Call(s):
#
#     package_install aide
#
function package_install {

# Load function arguments into local variables
local package="$1"

# Check sanity of the input
if [ $# -ne "1" ]
then
  echo "Usage: package_install 'package_name'"
  echo "Aborting."
  exit 1
fi

if which dnf ; then
  if ! rpm -q --quiet "$package"; then
    dnf install -y "$package"
  fi
elif which yum ; then
  if ! rpm -q --quiet "$package"; then
    yum install -y "$package"
  fi
elif which apt-get ; then
  apt-get install -y "$package"
else
  echo "Failed to detect available packaging system, tried dnf, yum and apt-get!"
  echo "Aborting."
  exit 1
fi

}

package_install aide

aide_conf="/etc/aide.conf"

groups=$(LC_ALL=C grep "^[A-Z]\+" $aide_conf | grep -v "^ALLXTRAHASHES" | cut -f1 -d '=' | tr -d ' ' | sort -u)

for group in $groups
do
	config=$(grep "^$group\s*=" $aide_conf | cut -f2 -d '=' | tr -d ' ')

	if ! [[ $config = *xattrs* ]]
	then
		if [[ -z $config ]]
		then
			config="xattrs"
		else
			config=$config"+xattrs"
		fi
	fi
	sed -i "s/^$group\s*=.*/$group = $config/g" $aide_conf
done
