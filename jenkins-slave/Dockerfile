FROM wedroid/jenkins-dind-ssh-slave

# Install docker binaries
RUN apk add --no-cache python3 && \
    pip3 install "docker-compose>=1.8"

# Copying to /home/jenkins
COPY entry.sh /entry.sh

RUN chmod ug+rx /entry.sh && chown jenkins:jenkins /entry.sh

ENTRYPOINT /entry.sh
