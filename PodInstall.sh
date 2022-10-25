#!/bin/sh
###
 # @Author: 梅继高
 # @Date: 2022-06-23 10:15:23
 # @LastEditTime: 2022-10-20 09:57:22
 # @LastEditors: 梅继高
 # @Description: 
 # @FilePath: /JGSourceBase/PodInstall.sh
 # Copyright © 2022 MeiJiGao. All rights reserved.
### 

function installPodsInDir() {
    podfileDir=$1
    if [[ "${podfileDir}" != "" ]]; then
        cd "./${podfileDir}"
    fi
    rm -fr Pods
    pod install
    while [ $? -ne 0 ]; do
        echo "\n\n\n"
        pod install
    done
}

echo "execute 'pod install' in root directory"
installPodsInDir "."

echo "\n\n\n"
echo "execute 'pod install' in 'JGSourceBaseDemo'"
installPodsInDir "JGSourceBaseDemo"