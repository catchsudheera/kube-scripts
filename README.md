## kube-scripts
Helper scripts for kubernetes related dev work - Wrapper for ```kubectl```


## How to install
1. Clone the shell script
2. Make the script executable by following command
```
    chmod +x kubeman.sh
```
3. Create a symlink so you can execute it from anywhere
```
    sudo ln -s kubeman.sh /usr/bin/kubeman
```
4. Run with a regex
```
    kubeman your-regex
```
## What are the features
* List all the pods matching a regular expression
* View logs (Even with multiple containers in one pod)
* Delete a pod and view logs of new pod (no copy-paste of pod id)
* List and Switch between kube contexts
