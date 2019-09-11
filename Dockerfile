FROM openjdk:8-jdk-alpine

ARG user=jenkins
ARG group=jenkins
ARG uid=10000
ARG gid=10000

ENV HOME /home/${user}
RUN addgroup -g ${gid} ${group}
RUN adduser -h $HOME -u ${uid} -G ${group} -D ${user}
LABEL Description="This is a base image, which provides the Jenkins agent executable (slave.jar)" Vendor="Jenkins project" Version="3.23"

ARG VERSION=3.23
ARG AGENT_WORKDIR=/home/${user}/agent

ENV KUBE_LATEST_VERSION v1.15.1
ENV KUBE_RUNNING_VERSION 1.13.4
ENV HELM_VERSION v2.13.1
ENV AWSCLI 1.16.236

RUN apk add --update --no-cache coreutils python3-dev postgresql-client vim python-dev xmlstarlet python3 gcc g++ make libxml2-dev py-libxml2 py-libxslt libxml2-utils libxml2-dev libxslt-dev curl bash openssh-client openssl procps ca-certificates git python py-pip gettext \ 
  && curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar \
  && wget -q https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/kubectl \
  && wget -q http://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
  && chmod +x /usr/local/bin/helm 
RUN pip install --upgrade pip \
  && pip install lxml selenium html requests allure-pytest pytest-allure-adaptor \
  && pip install awscli==${AWSCLI} \
  && pip3 install selenium imbox six requests allure-pytest lxml pillow==2.9.0 pdf2image

ADD https://dl.bintray.com/qameta/generic/io/qameta/allure/allure/2.7.0/allure-2.7.0.tgz /opt/
RUN tar -xvzf /opt/allure-2.7.0.tgz --directory /opt/ \
    && rm /opt/allure-2.7.0.tgz

ENV PATH="/opt/allure-2.7.0/bin:${PATH}"

#USER ${user}
ENV AGENT_WORKDIR=${AGENT_WORKDIR}
RUN mkdir /home/${user}/.jenkins && mkdir -p ${AGENT_WORKDIR}

VOLUME /home/${user}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR /home/${user}

COPY jenkins-slave /usr/local/bin/jenkins-slave

ENTRYPOINT ["jenkins-slave"]
