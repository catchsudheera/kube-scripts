#!/bin/bash
# author : Sudheera Palihakkara <catchsudheera@gmail.com>
# version : 1.1


# foreground color using ANSI escape

fgBLack=`tput setaf 0` # black
fgRed=`tput setaf 1` # red
fgGreen=`tput setaf 2` # green
fgYellow=`tput setaf 3` # yellow
fgBlue=`tput setaf 4` # blue
fgMagenta=`tput setaf 5` # magenta
fgCyan=`tput setaf 6`
fgWhite=`tput setaf 7` # white

# text editing options

txBold=`tput bold`   # bold
txHalf=`tput dim`    # half-bright
txUnderline=`tput smul`   # underline
txEndUnder=`tput rmul`   # exit underline
txReverse=`tput rev`    # reverse
txStandout=`tput smso`   # standout
txEndStand=`tput rmso`   # exit standout
txReset=`tput sgr0`   # reset attributes

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
		for (( i=0; i<${#ctxs[@]}; i++ )); do echo "$fgGreen[$i] - "${ctxs[i]} $txReset; done
	echo ""
	while [[ true ]]; do
		read -p "Enter the context number to switch : " ctxNumber
		if ! [[ $ctxNumber =~ $re ]] ; then
		   echo "${fgRed}error: Not a number $txReset"
		   continue
		fi
		if [ $ctxNumber -ge "${#ctxs[@]}" ] ; then
		   echo "${fgRed}error: Index out of range $txReset"
		   echo ""
		   continue
		fi
		break
	done

	res=`kubectl config use-context ${ctxs[$ctxNumber]}`
	echo "${fgYellow}${txBold}$res $txReset"
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
    echo "${fgRed}No pods matching regex : $inputRegex $txReset"
    exit 1
elif [ "${#numbers[@]}" -eq 1 ]; then
	selectedIdx=0
else
	for (( i=0; i<${#numbers[@]}; i++ )); do echo "${fgGreen}[$i] - "${numbers[i]} $txReset; done
	echo ""
	while [[ true ]]; do
		read -p "Enter the number to select pod : " selectedIdx
		if ! [[ $selectedIdx =~ $re ]] ; then
		   echo "${fgRed}error: Not a number $txReset"
		   continue
		fi
		if [ $selectedIdx -ge "${#numbers[@]}" ] ; then
		   echo "${fgRed}error: Index out of range $txReset"
		   echo ""
		   continue
		fi

		break
	done
fi

selectedName=${numbers[$selectedIdx]}
echo "${txBold}selected" $txGreen $selectedName $txReset
echo ""
read -p "${fgMagenta}Delete pod $selectedName y/n ? : $txReset" input_variable
if [ "$input_variable" = "y" ]; then
	echo "${fgBlue}deleting pod : $selectedName $txReset" 
	res=`kubectl delete pod/$selectedName`
	echo "${fgYellow}${txBold}$res $txReset"
	echo ""
	sleep 4

	while [[ true ]]; do
		newList=( $(kubectl get pods | grep $inputRegex | grep Running| awk  {'print $1'}) )
		for (( i=0; i<${#newList[@]}; i++ )); do echo "${fgGreen}[$i] - "${newList[i]} $txReset; done
		echo ""
		read -p "Enter the pod number to view logs or press Enter key to refresh pod list: " newIdx
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
    echo "${fgRed}No containers in the pod : $newName $txReset"
    exit 1
elif [ "${#arr[@]}" -eq 1 ]; then
	selectedIdx2=0
else
	for (( i=0; i<${#arr[@]}; i++ )); do echo "${fgGreen}[$i] - "${arr[i]} $txReset; done
	echo ""
	while [[ true ]]; do
		read -p "Enter the container number to view logs" selectedIdx2
		if ! [[ $selectedIdx2 =~ $re ]] ; then
		   echo "${fgRed}error: Not a number $txReset"
		   continue
		fi
		if [ $selectedIdx2 -ge "${#arr[@]}" ] ; then
		   echo "${fgRed}error: Index out of range $txReset"
		   echo ""
		   continue
		fi
		break
	done
fi

kubectl logs -f pod/$newName ${arr[$selectedIdx2]}
