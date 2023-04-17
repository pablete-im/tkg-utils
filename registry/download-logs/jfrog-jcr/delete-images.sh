#!/bin/bash

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "This script deletes the JFrog Artifactory artifacts specified in a file that is passed as an argument. To do so, a user token shall be provided in order to authenticate the different requests."
   echo "This script also requires the JFrog API base URL to generate a request to purge the trash can after deleting the artifacts if desired."
   echo
   echo "Syntax: delete-images.sh -i <INPUT FILE> -t <USER TOKEN> [-p] [-u <API BASE URL>] [-h]"
   echo "options:"
   echo " -i     Input file with JFrog Artifactory image artifact URLS. These URLs must be arranged in separate lines."
   echo " -t     User name and token encoded in Base64 in the following format: <USER NAME>:<TOKEN>. This Base64 string can be generated by executing the following command: echo -n 'user:token' | base64 ."
   echo " -p     This flag indicates that the trash can needs to be emptied after the artifacts have been deleted. If this flag is specified, the API BASE URL shall also be provided by using the -u option."
   echo " -u     API base URL used to empty the trash can. This argument is to be provided when the -p flag is specified."
   echo " -h     Print this Help."
   echo
}

############################################################
# Main program                                             #
############################################################

# Get the options
while getopts "i:t:pu:h" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      i) # Input File with Artifact URLs
	      INPUT_FILE=$OPTARG;;
      t) # Enter a BASE64 encoded string composed by <username>:<api_token> 
         USER_AUTH_TOKEN=$OPTARG;;	      
      p) # Flag that indicates if trash can is to be emptied
	      EMPTY_TRASHCAN=true;;
      u) # Artifactory API base URL
	      API_BASE_URL=$OPTARG;;
     \?) # Invalid option
         Help
         exit 1;;
   esac
done

shift "$(( OPTIND - 1 ))"

if [ -z "$INPUT_FILE" ] || [ -z "$USER_AUTH_TOKEN" ]; then
   echo 'Missing -i or -t' >&2
	Help
   exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "$INPUT_FILE does not exist!"
    exit 2
fi

if [ -z "$EMPTY_TRASHCAN" ] ; then
   EMPTY_TRASHCAN=false
else
   if [ -z "$API_BASE_URL" ] ; then
      echo 'Missing -u when -p has been specified' >&2
      Help
      exit 3
   fi
fi

while IFS= read -r line
do
if grep -q "#TOBESKIPPED" <<< "$line"; then
  echo Skipping image: $line

else
  echo Deleting: $line
  curl -I --location --request DELETE "$line" \
       --header "Authorization: Basic $TOKEN"
fi
  
done < "$INPUT_FILE"

if $EMPTY_TRASHCAN; then
   echo Emptying Artifactory Trash Can: $line
   curl -I --location --request POST "${API_BASE_URL}/trash/empty" \
        --header "Authorization: Basic $TOKEN"
fi

exit 0