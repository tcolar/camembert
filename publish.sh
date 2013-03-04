#!/bin/sh

env=/home/tcolar/DEV/fantom_env/fantom_cam/lib/fan/

echo "Publishing from : "
echo "${env}"
echo "continue y/n ?"
read var

if [ $var != "y" ]
then
  echo "bye."
  exit 5
fi

# list current stuff so we know what's there
fanr query -r http://repo.status302.com/fanr/ cam*

# offer to publish pods
fanr publish -r http://repo.status302.com/fanr/ ${env}netColarUtils.pod
fanr publish -r http://repo.status302.com/fanr/ ${env}netColarUI.pod
fanr publish -r http://repo.status302.com/fanr/ ${env}petanque.pod
fanr publish -r http://repo.status302.com/fanr/ ${env}camembert.pod
fanr publish -r http://repo.status302.com/fanr/ ${env}camFantomPlugin.pod
fanr publish -r http://repo.status302.com/fanr/ ${env}camMavenPlugin.pod
fanr publish -r http://repo.status302.com/fanr/ ${env}camNodePlugin.pod
fanr publish -r http://repo.status302.com/fanr/ ${env}camPythonPlugin.pod
fanr publish -r http://repo.status302.com/fanr/ ${env}camembertIde.pod

fanr publish -r http://repo.status302.com/fanr/ ${env}camAxonPlugin.pod


