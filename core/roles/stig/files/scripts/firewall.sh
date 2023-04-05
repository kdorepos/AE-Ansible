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

package_install firewalld

firewalld_sshd_zone="drop"

# This assumes that firewalld_sshd_zone is one of the pre-defined zones
if [ ! -f /etc/firewalld/zones/${firewalld_sshd_zone}.xml ]; then
    cp /usr/lib/firewalld/zones/${firewalld_sshd_zone}.xml /etc/firewalld/zones/${firewalld_sshd_zone}.xml
fi
if ! grep -q 'service name="ssh"' /etc/firewalld/zones/${firewalld_sshd_zone}.xml; then
    sed -i '/<\/description>/a \
  <service name="ssh"/>' /etc/firewalld/zones/${firewalld_sshd_zone}.xml
fi

# Check if any eth interface is bounded to the zone with SSH service enabled
nic_bound=false
eth_interface_list=$(ip link show up | cut -d ' ' -f2 | cut -d ':' -s -f1 | grep -E '^(en|eth)')
for interface in $eth_interface_list; do
    if grep -q "ZONE=$firewalld_sshd_zone" /etc/sysconfig/network-scripts/ifcfg-$interface; then
        nic_bound=true
        break;
    fi
done

if [ $nic_bound = false ];then
    # Add first NIC to SSH enabled zone

    if ! firewall-cmd --state -q; then
# Function to replace configuration setting in config file or add the configuration setting if
# it does not exist.
#
# Expects arguments:
#
# config_file:		Configuration file that will be modified
# key:			Configuration option to change
# value:		Value of the configuration option to change
# cce:			The CCE identifier or '@CCENUM@' if no CCE identifier exists
# format:		The printf-like format string that will be given stripped key and value as arguments,
#			so e.g. '%s=%s' will result in key=value subsitution (i.e. without spaces around =)
#
# Optional arugments:
#
# format:		Optional argument to specify the format of how key/value should be
# 			modified/appended in the configuration file. The default is key = value.
#
# Example Call(s):
#
#     With default format of 'key = value':
#     replace_or_append '/etc/sysctl.conf' '^kernel.randomize_va_space' '2' '@CCENUM@'
#
#     With custom key/value format:
#     replace_or_append '/etc/sysconfig/selinux' '^SELINUX=' 'disabled' '@CCENUM@' '%s=%s'
#
#     With a variable:
#     replace_or_append '/etc/sysconfig/selinux' '^SELINUX=' $var_selinux_state '@CCENUM@' '%s=%s'
#
function replace_or_append {
  local default_format='%s = %s' case_insensitive_mode=yes sed_case_insensitive_option='' grep_case_insensitive_option=''
  local config_file=$1
  local key=$2
  local value=$3
  local cce=$4
  local format=$5

  if [ "$case_insensitive_mode" = yes ]; then
    sed_case_insensitive_option="i"
    grep_case_insensitive_option="-i"
  fi
  [ -n "$format" ] || format="$default_format"
  # Check sanity of the input
  [ $# -ge "3" ] || { echo "Usage: replace_or_append <config_file_location> <key_to_search> <new_value> [<CCE number or literal '@CCENUM@' if unknown>] [printf-like format, default is '$default_format']" >&2; exit 1; }

  # Test if the config_file is a symbolic link. If so, use --follow-symlinks with sed.
  # Otherwise, regular sed command will do.
  sed_command=('sed' '-i')
  if test -L "$config_file"; then
    sed_command+=('--follow-symlinks')
  fi

  # Test that the cce arg is not empty or does not equal @CCENUM@.
  # If @CCENUM@ exists, it means that there is no CCE assigned.
  if [ -n "$cce" ] && [ "$cce" != '@CCENUM@' ]; then
    cce="CCE-${cce}"
  else
    cce="CCE"
  fi

  # Strip any search characters in the key arg so that the key can be replaced without
  # adding any search characters to the config file.
  stripped_key=$(sed 's/[\^=\$,;+]*//g' <<< "$key")

  # shellcheck disable=SC2059
  printf -v formatted_output "$format" "$stripped_key" "$value"

  # If the key exists, change it. Otherwise, add it to the config_file.
  # We search for the key string followed by a word boundary (matched by \>),
  # so if we search for 'setting', 'setting2' won't match.
  if LC_ALL=C grep -q -m 1 $grep_case_insensitive_option -e "${key}\\>" "$config_file"; then
    "${sed_command[@]}" "s/${key}\\>.*/$formatted_output/g$sed_case_insensitive_option" "$config_file"
  else
    # \n is precaution for case where file ends without trailing newline
    printf '\n# Per %s: Set %s in %s\n' "$cce" "$formatted_output" "$config_file" >> "$config_file"
    printf '%s\n' "$formatted_output" >> "$config_file"
  fi
}

        replace_or_append "/etc/sysconfig/network-scripts/ifcfg-${eth_interface_list[0]}" '^ZONE=' "$firewalld_sshd_zone" 'CCE-80447-6' '%s=%s'
    else
        # If firewalld service is running, we need to do this step with firewall-cmd
        # Otherwise firewalld will comunicate with NetworkManage and will revert assigned zone
        # of NetworkManager managed interfaces upon reload
        firewall-cmd --zone=$firewalld_sshd_zone --add-interface=${eth_interface_list[0]}
        firewall-cmd --reload
    fi
fi