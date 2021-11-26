#!/bin/bash
cat <<EOF > /mamede-teste/configmap.yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-configmap
data:
  USER: root
  DATABASE_URL: mysql://10.50.10.41:3306/SpringWebYoutube?useTimezone=true&serverTimezone=UT
EOF

cat <<EOF > /mamede-teste/nodeport.yml
apiVersion: v1
kind: Service
metadata:
  name: nodeport-pod-javadb
spec:
  type: NodePort
  ports:
    - port: 8080
      nodePort: 30002 # 30000 ~ 32767
  selector:
    app: pod-javadb
EOF

sleep 15

VAR_1="$1"
echo $VAR_1
cd ./mamede-teste
ANSIBLE_OUT=$(ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts provisionar.yml --extra-vars "hosts=$VAR_1" -u ubuntu --private-key /var/lib/jenkins/treinamentoitau_mauricio2.pem)
echo $ANSIBLE_OUT

## Mac ##
# MYSQL_POD_NAME=$(echo $ANSIBLE_OUT | grep -oE "(mysql-.*? )" )
## Linux ##
# MYSQL_POD_NAME=$(echo $ANSIBLE_OUT | grep -oP "(mysql-.*? )" )

echo "Esperando subir os pods ..."
sleep 300

cat <<EOF > restore-dump-mysql.yml
- hosts: 
  - mysql-dev
  become: yes
  tasks:
    - name: "Upload dump"
      copy:
        src: "k8s-deploy/1.2-dump-mysql.sql"
        dest: "/root/"

    - name: "Create dabatase"
      shell: echo "create database SpringWebYoutubeTest;" 
    
    - name: "Restore dump mysql"
      shell: "mysql root -p'root' < /root/1.2-dump-mysql.sql"
EOF

#ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts restore-dump-mysql.yml -u ubuntu --private-key /var/lib/jenkins/treinamentoitau_mauricio2.pem
