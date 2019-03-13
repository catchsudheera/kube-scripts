#!/bin/bash
# author : Sudheera Palihakkara <catchsudheera@gmail.com>
# version : 1.1

if [ "$1" == "-h" ]; then
	echo "Usage : `basename $0` [OPTION] POD_NAME_REGEX => for pod operation"
	echo ""
	echo "Supported options"		
	echo "  -sw   :   switch kube context before pod operation" 	
	echo ""
	echo "e.g -:"
	echo " ./kubeman.sh pri"
	echo "Will give you the following output to select pod"
	echo ""
	echo " [0]---my-pricing-adapter-5fd879487zq"
	echo " [1]---simple-priority-scheduler-7fbc9f8f95-7cr7j"
	echo " [2]---new-primitive-engine-7fbc9f8f95-k58m2"
	echo " [3]---final-prize-processor-7fbc9f8f95-zh8gj"
	echo " "
	echo " Enter the number to select pod"
	echo "" 
  exit 0
fi

if [[ $# -eq 0 ]] ; then
    echo 'Invalid number of arguments. Run with "-h" option for help'
    exit 0
fi

re='^[0-9]+$'
inputRegex=$1

if [ "$1" == "-sw" ]; then
	IFS=', ' read -r -a ctxs <<< `kubectl config view -o jsonpath='{$.contexts[*].name}'`
	echo ""
		for (( i=0; i<${#ctxs[@]}; i++ )); do echo "[$i] - "${ctxs[i]}; done
	echo ""
	echo "Enter the context number to switch : "
	while [[ true ]]; do
		read ctxNumber
		if ! [[ $ctxNumber =~ $re ]] ; then
		   echo "error: Not a number"
		   continue
		fi
		if [ $ctxNumber -ge "${#ctxs[@]}" ] ; then
		   echo "error: Index out of range"
		   echo ""
		   continue
		fi
		break
	done

	kubectl config use-context ${ctxs[$ctxNumber]}
	if [[ $# -eq 1 ]] ; then
		exit 0
	fi

	if [[ $# -eq 2 ]] ; then
		inputRegex=$2
	fi
fi

echo ""
echo "Finding pods matching regex \"$inputRegex\" in context : `kubectl config current-context`"
numbers=( $(kubectl get pods | grep $inputRegex | grep Running| awk  {'print $1'}) )

if [ "${#numbers}" -eq 0 ]; then
    echo "No pods matching regex : $inputRegex"
    exit 1
elif [ "${#numbers[@]}" -eq 1 ]; then
	selectedIdx=0
else
	for (( i=0; i<${#numbers[@]}; i++ )); do echo "[$i] - "${numbers[i]}; done
	echo ""
	while [[ true ]]; do
		echo "Enter the number to select pod"
		read selectedIdx
		if ! [[ $selectedIdx =~ $re ]] ; then
		   echo "error: Not a number"
		   continue
		fi
		if [ $selectedIdx -ge "${#numbers[@]}" ] ; then
		   echo "error: Index out of range"
		   echo ""
		   continue
		fi

		break
	done
fi

selectedName=${numbers[$selectedIdx]}
echo "selected" $selectedIdx $selectedName
echo ""
echo "Delete pod $selectedName y/n ?"
read input_variable
if [ "$input_variable" = "y" ]; then
	echo "deleting pod : $selectedName" 
	kubectl delete pod/$selectedName
	sleep 4

	while [[ true ]]; do
		newList=( $(kubectl get pods | grep $inputRegex | grep Running| awk  {'print $1'}) )
		for (( i=0; i<${#newList[@]}; i++ )); do echo "[$i] - "${newList[i]}; done
		echo ""
		echo "Enter the pod number to view logs, press enter to refresh"
		read newIdx
		if ! [[ $newIdx =~ $re ]] ; then
		   continue
		fi
		if [ $newIdx -ge "${#newList[@]}" ] ; then
		   continue
		fi

		newName=`echo ${newList[$newIdx]} | awk  {'print $1'}`
		break
	done
else
	newName=$selectedName
fi

arr=( $(kubectl get pods $newName -o jsonpath='{.spec.containers[*].name}') )

if [ "${#arr}" -eq 0 ]; then
    echo "No containers in the pod : $newName"
    exit 1
elif [ "${#arr[@]}" -eq 1 ]; then
	selectedIdx2=0
else
	for (( i=0; i<${#arr[@]}; i++ )); do echo "[$i] - "${arr[i]}; done
	echo ""
	echo "Enter the container number to view logs"
	while [[ true ]]; do
		read selectedIdx2
		if ! [[ $selectedIdx2 =~ $re ]] ; then
		   echo "error: Not a number"
		   continue
		fi
		if [ $selectedIdx2 -ge "${#arr[@]}" ] ; then
		   echo "error: Index out of range"
		   echo ""
		   continue
		fi
		break
	done
fi

kubectl logs -f pod/$newName ${arr[$selectedIdx2]}
