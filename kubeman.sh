#!/bin/bash
# author : Sudheera Palihakkara <catchsudheera@gmail.com>
# version : 1.0

if [ "$1" == "-h" ]; then
	echo "Usage: `basename $0` [your pod name regex]"
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
  exit 0
fi

if [[ $# -eq 0 ]] ; then
    echo 'Invalid number of arguments. Run with "-h" option for help'
    exit 0
fi

numbers=( $(kubectl get pods | grep $1 | grep Running| awk  {'print $1'}) )

re='^[0-9]+$'
if [ "${#numbers}" -eq 0 ]; then
    echo "No pods matching regex : $1"
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
echo "Redeploy pod $selectedName y/n ?"
read input_variable
if [ "$input_variable" = "y" ]; then
	echo "deleting pod : $selectedName" 
	kubectl delete pod/$selectedName
	sleep 4
fi

for i in {2..4}
do
	simpleName=`echo $selectedName | rev | cut -d"-" -f$i-  | rev`
	echo $simpleName
	if [ -z "$simpleName" ]; then 
		echo "Could not find the new pod name for $selectedName"
		exit 1
	fi
	newPodLine=`kubectl get pods | grep $simpleName | grep "[Running,ContainerCreating]" | head -n 1`
	if [ -n "$newPodLine" ]; then
		newPodName=`echo $newPodLine | awk  {'print $1'}`
		echo ""
		newName=`kubectl get pods | grep $newPodName | grep "[Running,ContainerCreating]" | awk  {'print $1'}`
		echo "New pod for $simpleName ==> $newName"
		break;
	fi
done

if [ -n "$newPodName" ]; then
	while [[ true ]]; do
		newList=( $(kubectl get pods | grep $1 | grep Running| awk  {'print $1'}) )
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
