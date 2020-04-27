#!/bin/bash

# By Georgiy Sitnikov.
#
# AS-IS without any warranty
#
# To added to Nextcloud please execute:
# sudo -u www-data php /var/www/nextcloud/occ talk:command:add pass pass "/usr/local/bin/nextcloud-bot-pass.sh {ARGUMENTS}" 1 3
#
# More info under https://nextcloud-talk.readthedocs.io/en/latest/commands/

length=16

while test $# -gt 0; do
	case "$1" in
		--help)
			echo "/pass - A Nextcloud Talk chat wrapper random pass generation"
			echo " "
			echo "Simple execution: /pass"
			echo "Complex execution to get 8 characters pass: /pass 8"
			echo "Default password length is $length"
			exit 0
			;;
		*)
	break
	;;
esac
done

if [ ! -z "$1" ]; then
	length="$1"

	# check if it is a number
	# https://stackoverflow.com/questions/806906/how-do-i-test-if-a-variable-is-a-number-in-bash
	re='^[0-9]+$'
	if ! [[ $length =~ $re ]] ; then
		echo "Not a number :(" >&2
		exit 1
	fi
fi

# Use urandom if presented
if [ -r "/dev/urandom" ]; then
	echo "Generated with Urandom"
	< /dev/urandom tr -dc A-Za-z0-9 | head -c"$length"
	echo
	exit 0
fi

# Use openssl if presneted
if [ -x "/usr/bin/openssl" ]; then
	echo "Generated with OpenSSL"
	/usr/bin/openssl rand -base64 "$length" | head -c"$length"
	echo
	exit 0
fi

# User bash Random if nothing from above presented
# https://stackoverflow.com/questions/26665389/random-password-generator-bash

echo "Generated with Bash random"
choose() { echo ${1:RANDOM%${#1}:1} $RANDOM; }

{
    choose '!@#$%^\&'
    choose '0123456789'
    choose 'abcdefghijklmnopqrstuvwxyz'
    choose 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    for i in $( seq 1 "$length" )
#    for i in $( seq 1 $(( 4 + RANDOM % 8 )) )
    do
        choose '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    done

} | sort -R | awk '{printf "%s",$1}' | head -c"$length"

echo

exit 0