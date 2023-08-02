![alt text](ecs.logo.JPG)

# [awx_terraform_pg](https://bitbucket.cdmdashboard.com/projects/DBOPS/repos/awx_terraform_pg/browse)
# [awx](https://github.com/ansible/awx)

* This repository contains the necessary source code files to deploy a rhel8 AWX ec2 instance from ami and includes ec2, alb, alb-sg, ec2-sg, certificate and target group from terraform. Next it contains the instructions to deploy AWX on the ec2 deployed from terraform. For additional details, please email at [c.sargent-ctr@ecstech.com](mailto:c.sargent-ctr@ecstech.com). 

# Deploy This Project from Git
1. ssh -i alpha_key_pair.pem ec2-user@PG-TerraformPublicIP
2. cd /home/christopher.sargent/ && git clone https://bitbucket.cdmdashboard.com/projects/DBOPS/repos/awx_terraform_pg.git
3. cd awx_terraform_pg/ && vim providers.tf
```
# Playground 
provider "aws" {
  region = var.selected_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
```
4. vim alpha_key_pair.pem
```
# alpha_key_pair.pem.pem key is in AWS secrets manager in playground. Cut and paste key into this file and save
```
5. chmod 400 alpha_key_pair.pem
6. vim variables.tf
```
Playground terraform_service_user aws_access_key and aws_secret_key is in AWS secrets manager
variable "aws_access_key" {
  type    = string
  default = "" # specify the access key
}
variable "aws_secret_key" {
  type    = string
  default = "" # specify the secret key
}
variable "selected_region" {
  type    = string
  default = "us-gov-west-1" # specify the aws region
}
# aws ssh key
variable "ssh_private_key" {
  default         = "alpha_key_pair.pem"
  description     = "alpha_key_pair"
}
```
7. terraform init && terraform plan --out awx.out
8. terraform apply "awx.out"
9. https://console.amazonaws-us-gov.com > EC2 > search for awx-pg-terraform-ec2 and verify instance is up
10. https://console.amazonaws-us-gov.com > Load Balancers > search for awx-pg-terraform-alb and get DNS name
11. https://DNSnamefromstep10 > Login to AWX

# Update Names
1. ssh -i alpha_key_pair.pem ec2-user@PG-TerraformPublicIP
2. sudo -i
3. cd /home/christopher.sargent/ecs_threatq_terraform_ps
4. cp main.tf main.tf.BAK
5. sed -i -e 's|terraform|terraform01|g' main.tf
```
The resources are now named

awx-pg-terraform01-ec2 and awx-pg-terraform01-alb

versus

awx-pg-terraform-ec2 and awx-pg-terraform-alb
```
# Destroy if needed
1. ssh -i alpha_key_pair.pem ec2-user@PG-TerraformPublicIP
2. sudo -i
3. cd /home/christopher.sargent/awx_terraform_pg
4. terraform destroy

# Install EPEL, docker, docker-compose 
* Note docker and docker-compose was installed on the AMI
1. ssh -i alpha_key_pair.pem ec2-user@PG-TerraformPublicIP
2. sudo -i
3. cd /home/sysadmin && ssh -i alpha_key_pair.pem ec2-user@awx-pg-terraform-ec2PrivateIP
4. sudo -i 
5. dnf upgrade -y && dnf install yum-utils -y && reboot 
6. steps 1 - 4 under Deploy AWX 21.11.1 on awx-pg-terraform-ec2
7. dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y && dnf update && dnf install htop -y
8. cp /etc/profile /etc/profile.ORIG && echo "export PROMPT_COMMAND='echo -n \[\$(date +%F-%T)\]\ '" >> /etc/profile && echo "export HISTTIMEFORMAT='%F-%T '" >> /etc/profile && source /etc/profile
9. dnf install git gcc gcc-c++ nodejs gettext device-mapper-persistent-data lvm2 bzip2 python3-pip ansible vim -y
10. dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
11. dnf install --nobest --allowerasing docker-ce -y
12. curl -SL https://github.com/docker/compose/releases/download/v2.3.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose && ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
13. docker --version && docker-compose --version
```
Docker version 24.0.5, build ced0996
Docker Compose version v2.3.3
```
14. systemctl enable docker.service && systemctl start docker.service
# Deploy AWX 21.11.1 on awx-pg-terraform-ec2
1. ssh -i alpha_key_pair.pem ec2-user@PG-TerraformPublicIP
2. sudo -i
3. cd /home/sysadmin && ssh -i alpha_key_pair.pem ec2-user@awx-pg-terraform-ec2PrivateIP
4. sudo -i 
6. cd /home && git clone -b 21.11.0 https://github.com/ansible/awx.git
7. cd /home && mv awx awx21 && cd /home/awx21/tools/docker-compose
8. vim inventory 
```
# Uncomment and update pg_password, broadcast_websocket_secret, secret_key and awx_image 
localhost ansible_connection=local ansible_python_interpreter="/usr/bin/env python3"

[all:vars]

# AWX-Managed Database Settings
# If left blank, these will be generated upon install.
# Values are written out to tools/docker-compose/_sources/secrets/
pg_password="password"
broadcast_websocket_secret="password40"
secret_key="passwordpasswordpasswordpassword"

# External Database Settings
# pg_host=""
# pg_password=""
# pg_username=""
# pg_hostname=""

awx_image="ghcr.io/ansible/awx_devel"
# migrate_local_docker=false

```
* Note the following take a few minutes each
9. cd /home/awx21 && vim tools/ansible/roles/dockerfile/templates/Dockerfile.j2
* Note you need to update rsyslog-8.2102.0-106.el9 to rsyslog which should be line 119
```
### This file is generated from
### tools/ansible/roles/dockerfile/templates/Dockerfile.j2
###
### DO NOT EDIT
###

# Build container
FROM quay.io/centos/centos:stream9 as builder

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV AWX_LOGGING_MODE stdout


USER root

# Install build dependencies
RUN dnf -y update && dnf install -y 'dnf-command(config-manager)' && \
    dnf config-manager --set-enabled crb && \
    dnf -y install \
    gcc \
    gcc-c++ \
    git-core \
    gettext \
    glibc-langpack-en \
    libffi-devel \
    libtool-ltdl-devel \
    make \
{% if not headless|bool %}
    nodejs \
{% endif %}
    nss \
    openldap-devel \
    patch \
    postgresql \
    postgresql-devel \
    python3-devel \
    python3-pip \
    python3-psycopg2 \
    python3-setuptools \
    swig \
    unzip \
    xmlsec1-devel \
    xmlsec1-openssl-devel

RUN pip3 install virtualenv build

{% if image_architecture == 'ppc64le'  %}
    RUN dnf -y update && dnf install -y wget && \
    wget https://static.rust-lang.org/dist/rust-1.41.0-powerpc64le-unknown-linux-gnu.tar.gz && \
    tar -zxvf rust-1.41.0-powerpc64le-unknown-linux-gnu.tar.gz && \
    cd rust-1.41.0-powerpc64le-unknown-linux-gnu && \
    sh install.sh ;
{% endif %}

# Install & build requirements
ADD Makefile /tmp/Makefile
RUN mkdir /tmp/requirements
ADD requirements/requirements.txt \
    requirements/requirements_tower_uninstall.txt \
    requirements/requirements_git.txt \
    /tmp/requirements/

RUN cd /tmp && make requirements_awx

ARG VERSION
ARG SETUPTOOLS_SCM_PRETEND_VERSION
ARG HEADLESS

{% if (build_dev|bool) or (kube_dev|bool) %}
ADD requirements/requirements_dev.txt /tmp/requirements
RUN cd /tmp && make requirements_awx_dev
{% else %}
# Use the distro provided npm to bootstrap our required version of node

{% if not headless|bool %}
RUN npm install -g n && n 16.13.1
{% endif %}

# Copy source into builder, build sdist, install it into awx venv
COPY . /tmp/src/
WORKDIR /tmp/src/
RUN make sdist && /var/lib/awx/venv/awx/bin/pip install dist/awx.tar.gz

{% if not headless|bool %}
RUN AWX_SETTINGS_FILE=/dev/null SKIP_SECRET_KEY_CHECK=yes SKIP_PG_VERSION_CHECK=yes /var/lib/awx/venv/awx/bin/awx-manage collectstatic --noinput --clear
{% endif %}

{% endif %}

# Final container(s)
FROM quay.io/centos/centos:stream9

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV AWX_LOGGING_MODE stdout

USER root

# Install runtime requirements
RUN dnf -y update && dnf install -y 'dnf-command(config-manager)' && \
    dnf config-manager --set-enabled crb && \
    dnf -y install acl \
    git-core \
    git-lfs \
    glibc-langpack-en \
    krb5-workstation \
    nginx \
    "openldap >= 2.6.2-3" \
    postgresql \
    python3-devel \
    python3-libselinux \
    python3-pip \
    python3-psycopg2 \
    python3-setuptools \
    rsync \
    rsyslog \
    subversion \
    sudo \
    vim-minimal \
    which \
    unzip \
    xmlsec1-openssl && \
    dnf -y clean all

RUN pip3 install virtualenv supervisor dumb-init

RUN rm -rf /root/.cache && rm -rf /tmp/*

{% if (build_dev|bool) or (kube_dev|bool) %}
# Install development/test requirements
RUN dnf -y install \
    crun \
    gdb \
    gtk3 \
    gettext \
    hostname \
    procps \
    alsa-lib \
    libX11-xcb \
    libXScrnSaver \
    iproute \
    strace \
    vim \
    nmap-ncat \
    libpq-devel \
    nodejs \
    nss \
    make \
    patch \
    socat \
    tmux \
    wget \
    diffutils \
    unzip && \
    npm install -g n && n 16.13.1 && npm install -g npm@8.5.0 && dnf remove -y nodejs

RUN pip3 install black git+https://github.com/coderanger/supervisor-stdout setuptools-scm

# This package randomly fails to download.
# It is nice to have in the dev env, but not necessary.
# Add it back to the list above if the repo ever straighten up.
RUN dnf --enablerepo=baseos-debug -y install python3-debuginfo || :

RUN dnf install -y epel-next-release && dnf install -y inotify-tools && dnf remove -y epel-next-release
{% endif %}

# Copy app from builder
COPY --from=builder /var/lib/awx /var/lib/awx

RUN ln -s /var/lib/awx/venv/awx/bin/awx-manage /usr/bin/awx-manage

{%if build_dev|bool %}
COPY --from={{ receptor_image }} /usr/bin/receptor /usr/bin/receptor

RUN openssl req -nodes -newkey rsa:2048 -keyout /etc/nginx/nginx.key -out /etc/nginx/nginx.csr \
        -subj "/C=US/ST=North Carolina/L=Durham/O=Ansible/OU=AWX Development/CN=awx.localhost" && \
    openssl x509 -req -days 365 -in /etc/nginx/nginx.csr -signkey /etc/nginx/nginx.key -out /etc/nginx/nginx.crt && \
    chmod 640 /etc/nginx/nginx.{csr,key,crt}
{% endif %}

{% if build_dev|bool %}
RUN dnf install -y podman && rpm --restore shadow-utils 2>/dev/null

# chmod containers.conf and adjust storage.conf to enable Fuse storage.
RUN sed -i -e 's|^#mount_program|mount_program|g' -e '/additionalimage.*/a "/var/lib/shared",' -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' /etc/containers/storage.conf

ENV _CONTAINERS_USERNS_CONFIGURED=""

# Ensure we must use fully qualified image names
# This prevents podman prompt that hangs when trying to pull unqualified images
RUN mkdir -p /etc/containers/registries.conf.d/ && echo "unqualified-search-registries = []" >> /etc/containers/registries.conf.d/force-fully-qualified-images.conf && chmod 644 /etc/containers/registries.conf.d/force-fully-qualified-images.conf
{% endif %}

# Create default awx rsyslog config
ADD tools/ansible/roles/dockerfile/files/rsyslog.conf /var/lib/awx/rsyslog/rsyslog.conf
ADD tools/ansible/roles/dockerfile/files/wait-for-migrations /usr/local/bin/wait-for-migrations
ADD tools/ansible/roles/dockerfile/files/stop-supervisor /usr/local/bin/stop-supervisor

## File mappings
{% if build_dev|bool %}
ADD tools/docker-compose/launch_awx.sh /usr/bin/launch_awx.sh
ADD tools/docker-compose/nginx.conf /etc/nginx/nginx.conf
ADD tools/docker-compose/nginx.vh.default.conf /etc/nginx/conf.d/nginx.vh.default.conf
ADD tools/docker-compose/start_tests.sh /start_tests.sh
ADD tools/docker-compose/bootstrap_development.sh /usr/bin/bootstrap_development.sh
ADD tools/docker-compose/entrypoint.sh /entrypoint.sh
ADD tools/scripts/config-watcher /usr/bin/config-watcher
ADD https://raw.githubusercontent.com/containers/libpod/master/contrib/podmanimage/stable/containers.conf /etc/containers/containers.conf
ADD https://raw.githubusercontent.com/containers/libpod/master/contrib/podmanimage/stable/podman-containers.conf /var/lib/awx/.config/containers/containers.conf
{% else %}
ADD tools/ansible/roles/dockerfile/files/launch_awx.sh /usr/bin/launch_awx.sh
ADD tools/ansible/roles/dockerfile/files/launch_awx_task.sh /usr/bin/launch_awx_task.sh
ADD tools/ansible/roles/dockerfile/files/uwsgi.ini /etc/tower/uwsgi.ini
ADD {{ template_dest }}/supervisor.conf /etc/supervisord.conf
ADD {{ template_dest }}/supervisor_task.conf /etc/supervisord_task.conf
{% endif %}
{% if (build_dev|bool) or (kube_dev|bool) %}
ADD tools/docker-compose/awx.egg-link /tmp/awx.egg-link
ADD tools/docker-compose/awx-manage /usr/local/bin/awx-manage
ADD tools/scripts/awx-python /usr/bin/awx-python
{% endif %}

# Pre-create things we need to access
RUN for dir in \
      /var/lib/awx \
      /var/lib/awx/rsyslog \
      /var/lib/awx/rsyslog/conf.d \
      /var/lib/awx/.local/share/containers/storage \
      /var/run/awx-rsyslog \
      /var/log/nginx \
      /var/lib/postgresql \
      /var/run/supervisor \
      /var/run/awx-receptor \
      /var/lib/nginx ; \
    do mkdir -m 0775 -p $dir ; chmod g+rwx $dir ; chgrp root $dir ; done && \
    for file in \
      /etc/subuid \
      /etc/subgid \
      /etc/group \
      /etc/passwd \
      /var/lib/awx/rsyslog/rsyslog.conf ; \
    do touch $file ; chmod g+rw $file ; chgrp root $file ; done

{% if (build_dev|bool) or (kube_dev|bool) %}
RUN for dir in \
      /etc/containers \
      /var/lib/awx/.config/containers \
      /var/lib/awx/.config/cni \
      /var/lib/awx/.local \
      /var/lib/awx/venv \
      /var/lib/awx/venv/awx/bin \
      /var/lib/awx/venv/awx/lib/python3.9 \
      /var/lib/awx/venv/awx/lib/python3.9/site-packages \
      /var/lib/awx/projects \
      /var/lib/awx/rsyslog \
      /var/run/awx-rsyslog \
      /.ansible \
      /var/lib/shared/overlay-images \
      /var/lib/shared/overlay-layers \
      /var/lib/shared/vfs-images \
      /var/lib/shared/vfs-layers \
      /var/lib/awx/vendor ; \
    do mkdir -m 0775 -p $dir ; chmod g+rwx $dir ; chgrp root $dir ; done && \
    for file in \
      /etc/containers/containers.conf \
      /var/lib/awx/.config/containers/containers.conf \
      /var/lib/shared/overlay-images/images.lock \
      /var/lib/shared/overlay-layers/layers.lock \
      /var/lib/shared/vfs-images/images.lock \
      /var/lib/shared/vfs-layers/layers.lock \
      /var/run/nginx.pid \
      /var/lib/awx/venv/awx/lib/python3.9/site-packages/awx.egg-link ; \
    do touch $file ; chmod g+rw $file ; done && \
    echo "\setenv PAGER 'less -SXF'" > /var/lib/awx/.psqlrc
{% endif %}

{% if not build_dev|bool %}
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log
{% endif %}

ENV HOME="/var/lib/awx"
ENV PATH="/usr/pgsql-12/bin:${PATH}"

{% if build_dev|bool %}
ENV PATH="/var/lib/awx/venv/awx/bin/:${PATH}"

EXPOSE 8043 8013 8080 22

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
{% else %}
USER 1000
EXPOSE 8052

ENTRYPOINT ["dumb-init", "--"]
CMD /usr/bin/launch_awx.sh
VOLUME /var/lib/nginx
VOLUME /var/lib/awx/.local/share/containers
{% endif %}
```

10. make docker-compose-build
11. docker image ls
```
REPOSITORY                  TAG       IMAGE ID       CREATED         SIZE
ghcr.io/ansible/awx_devel   HEAD      847988a0e898   2 minutes ago   1.82GB
quay.io/centos/centos       stream9   7a8f9253940e   3 days ago      155MB

```
12. cd /home/awx21 && make docker-compose COMPOSE_UP_OPTS=-d

13. docker exec tools_awx_1 make clean-ui ui-devel
14. docker exec -ti tools_awx_1 awx-manage createsuperuser
* Note to store these creds in secrets manager root password
```
Username (leave blank to use 'root'):
Email address: christ.sargent-CTR@ecstech.com
Password:
Password (again):
Superuser created successfully.

```
15. cp /root/.bashrc /root/.bashrc.ORIG
16. vi /root/.bashrc (add the following aliases)
```
alias awx-start='cd /home/awx21/tools/docker-compose/_sources && docker-compose up -d'
alias awx-stop='cd /home/awx21/tools/docker-compose/_sources && docker-compose down'
alias awx='cd /var/lib/awx/projects/'
```
17. source /root/.bashrc 
18. awx-stop
```
[+] Running 4/4
 ⠿ Container tools_awx_1       Removed                                                                                                                                                                  3.7s
 ⠿ Container tools_redis_1     Removed                                                                                                                                                                  0.3s
 ⠿ Container tools_postgres_1  Removed                                                                                                                                                                  0.2s
 ⠿ Network sources_default     Removed
```
17. vim /home/awx21/tools/docker-compose/_sources/docker-compose.yml
* Note we are adding the bind mount - "/var/lib/awx/projects:/var/lib/awx/projects:rw", setting restart: always so the containers come back up on reboot and updating the ports from 8043:8043 to 443:8043
```
---
version: '2.1'
services:
  # Primary AWX Development Container
  awx_1:
    user: "0"
    image: "ghcr.io/ansible/awx_devel:HEAD"
    container_name: tools_awx_1
    restart: always
    hostname: awx_1
    command: launch_awx.sh
    environment:
      OS: " Operating System: Red Hat Enterprise Linux 8.7 (Ootpa)"
      SDB_HOST: 0.0.0.0
      SDB_PORT: 7899
      AWX_GROUP_QUEUES: tower
      MAIN_NODE_TYPE: "${MAIN_NODE_TYPE:-hybrid}"
      RECEPTORCTL_SOCKET: /var/run/awx-receptor/receptor.sock
      CONTROL_PLANE_NODE_COUNT: 1
      EXECUTION_NODE_COUNT: 0
      AWX_LOGGING_MODE: stdout
      DJANGO_SUPERUSER_PASSWORD: hRBCGBMkDmDRPPGtMpin
      RUN_MIGRATIONS: 1
    links:
      - postgres
      - redis_1
    working_dir: "/awx_devel"
    volumes:
      - "../../../:/awx_devel"
      - "../../docker-compose/supervisor.conf:/etc/supervisord.conf"
      - "../../docker-compose/_sources/database.py:/etc/tower/conf.d/database.py"
      - "../../docker-compose/_sources/websocket_secret.py:/etc/tower/conf.d/websocket_secret.py"
      - "../../docker-compose/_sources/local_settings.py:/etc/tower/conf.d/local_settings.py"
      - "../../docker-compose/_sources/SECRET_KEY:/etc/tower/SECRET_KEY"
      - "../../docker-compose/_sources/receptor/receptor-awx-1.conf:/etc/receptor/receptor.conf"
      - "../../docker-compose/_sources/receptor/receptor-awx-1.conf.lock:/etc/receptor/receptor.conf.lock"
      # - "../../docker-compose/_sources/certs:/etc/receptor/certs"  # TODO: optionally generate certs
      - "/sys/fs/cgroup:/sys/fs/cgroup"
      - "~/.kube/config:/var/lib/awx/.kube/config"
      - "redis_socket_1:/var/run/redis/:rw"
      - "/var/lib/awx/projects:/var/lib/awx/projects:rw"
    privileged: true
    tty: true
    ports:
      - "7899-7999:7899-7999"  # sdb-listen
      - "6899:6899"
      - "8080:8080"  # unused but mapped for debugging
      - "8888:8888"  # jupyter notebook
      - "8013:8013"  # http
      - "443:8043"  # https
      - "2222:2222"  # receptor foo node
      - "3000:3001"  # used by the UI dev env
  redis_1:
    image: redis:latest
    container_name: tools_redis_1
    restart: always
    volumes:
      - "../../redis/redis.conf:/usr/local/etc/redis/redis.conf"
      - "redis_socket_1:/var/run/redis/:rw"
    entrypoint: ["redis-server"]
    command: ["/usr/local/etc/redis/redis.conf"]
  # A useful container that simply passes through log messages to the console
  # helpful for testing awx/tower logging
  # logstash:
  #   build:
  #     context: ./docker-compose
  #     dockerfile: Dockerfile-logstash
  postgres:
    image: postgres:12
    container_name: tools_postgres_1
    restart: always
    # additional logging settings for postgres can be found https://www.postgresql.org/docs/current/runtime-config-logging.html
    command: postgres -c log_destination=stderr -c log_min_messages=info -c log_min_duration_statement=1000 -c max_connections=1024
    environment:
      POSTGRES_HOST_AUTH_METHOD: trust
      POSTGRES_USER: awx
      POSTGRES_DB: awx
      POSTGRES_PASSWORD: 31nst31n
    volumes:
      - "awx_db:/var/lib/postgresql/data"

volumes:
  awx_db:
    name: tools_awx_db
  redis_socket_1:
    name: tools_redis_socket_1
```
18. awx-start
```
[+] Running 4/4
 ⠿ Network sources_default     Created                                                                                                                                                                  0.1s
 ⠿ Container tools_redis_1     Started                                                                                                                                                                  0.8s
 ⠿ Container tools_postgres_1  Started                                                                                                                                                                  0.8s
 ⠿ Container tools_awx_1       Started
```
19. https://DNSnamefromstep10 under Deploy This Project from Git section > Login to AWX 



