#!/bin/bash

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "This script modifies the kubeconfig secret associated to a specific TKG Workload cluster in the management cluster, replacing the sever URL by the one specified as an argument."
   echo "This script requires the context to be set up to point a Management Cluster!."
   echo
   echo "Syntax: modifyKubeconfigSecret.sh -c <CLUSTER NAME> -f <FQDN> [-h]"
   echo "options:"
   echo " -c     TKG Cluster name. This parameter is mandatory!"
   echo " -f     New FQDN to be used for the Workload cluster API server. This parameter is mandatory!"
   echo " -n     Namespace. This parameter can be set to work on a specific namespace. For example, management cluster objects are stored in the tkg-system namespace. Workload cluster objects are stored by default in the default namespace, and this otpion is not needed."
   echo " -h     Print this Help."
   echo
}

############################################################
# Main program                                             #
############################################################

# Get the options
while getopts "c:f:n:h" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      c) # Enter a cluster name
	 CLUSTER_NAME=$OPTARG;;
      f) # Enter a FQDN
         FQDN=$OPTARG;;	      
      n) # Namespace
	 NAMESPACE=$OPTARG;;
     \?) # Invalid option
         Help
         exit 1;;
   esac
done

shift "$(( OPTIND - 1 ))"

if [ -z "$CLUSTER_NAME" ] || [ -z "$FQDN" ]; then
        echo 'Missing -c or -f' >&2
	Help
        exit 1
fi

if [ -z "$NAMESPACE" ]; then
	NAMESPACE_OPTS=""
else
	NAMESPACE_OPTS="-n $NAMESPACE"
fi

kubectl get secret $CLUSTER_NAME-kubeconfig -o jsonpath='{.data.value}' $NAMESPACE_OPTS | base64 -d > kubeconfig-secret.yaml 

echo "Checking current value:"
cat kubeconfig-secret.yaml | yq '.clusters[0].cluster.server'

yq -i ".clusters[0].cluster.server = \"https://$FQDN:6443\"" kubeconfig-secret.yaml

SECRET_DATA_ENCODED=$(cat kubeconfig-secret.yaml | base64 -w 0)

rm kubeconfig-secret.yaml

kubectl patch secret $CLUSTER_NAME-kubeconfig $NAMESPACE_OPTS --type merge -p "{\"data\":{\"value\": \"$SECRET_DATA_ENCODED\"}}"

echo "Checking modified value:"
kubectl get secret  $CLUSTER_NAME-kubeconfig $NAMESPACE_OPTS -o jsonpath='{.data.value}' | base64 -d | yq '.clusters[0].cluster.server'

exit 0
