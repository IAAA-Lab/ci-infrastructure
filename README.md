# ci-infrastructure

<!-- TOC START min:2 max:4 link:true update:true -->
- [Components](#components)
- [Start-up](#start-up)
  - [SSH](#ssh)
  - [Jenkins Master setup](#jenkins-master-setup)
    - [Wizard - Secret key](#wizard---secret-key)
    - [Wizard - Recommended Plugins](#wizard---recommended-plugins)
    - [Private SSH key - ssh-keygen](#private-ssh-key---ssh-keygen)
    - [Private SSH key - Jenkins](#private-ssh-key---jenkins)
    - [Add a slave node](#add-a-slave-node)
- [Project setup](#project-setup)
  - [Blue Ocean](#blue-ocean)
  - [Old GUI](#old-gui)
    - [Project settings](#project-settings)
    - [Github webhook config](#github-webhook-config)
- [Jenkinsfile](#jenkinsfile)
- [SonarQube](#sonarqube)

<!-- TOC END -->

## Components

This Jenkins infrastructure has an scalable, distributed architechture. Each one running in a different container:

- 1x Jenkins Master
- Nx Jenkins Slaves
- 1x SonarQube
- 1x SonarQube DB
- 1x Sidecar `rsa key-pair` generation

## Start-up

### SSH

The communication between `master` and `slave` is done by an `ssh` session. The master, should have a `private key` and the slaves an `authored key` (the public one). In order to automate this _key sharing_ we introduced the `sidecar container` (_aka one-shot container_) which shares a `volume` with the other containers.

In this `shared volume`, the sidecar stores the generated `rsa keys` which are automatically available for `slave`.

### Jenkins Master setup

#### Wizard - Secret key

Jenkins has an installation wizard which creates the `admin` user and asks you about the plugins to install. The first step of this wizard requieres a private token that is printed in the logs so you can copy it.

There are many way of getting this log:

_If you have direct access to the docker CLI_
```bash
docker ps # lists all containers
docker logs CONTAINER_ID
```

_If you have direct access to the Rancher Console_
```bash
Stacks > STACK_NAME > jenkins-master > containers > CONTAINER_NAME > Options [3-dots] > View Logs
```

#### Wizard - Recommended Plugins

The recommended plugins for this set up are:

- Pipeline
- Blue Ocean
- Git plugin
- GitHub plugin

**Note:** The may be already installed depending on the base image patch.

#### Private SSH key - ssh-keygen

The keygen container is programmed to print te private key (**read the security warn**). You can copy as you did with the jenkins token.

#### Private SSH key - Jenkins

The Jenkins version used doesn't allow to specify a path where the private key is stored so you have to copy it manually (**read the security warn**).

Go to:
```
Jenkins Home Page > Credentials > (global) > Add Credentials
```

Fill:
```
Kind: SSH username with private key
Scope: Global
Username: jenkis
Private Key: (*) Enter directly
Key: -----BEGIN RSA PRIVATE KEY-----
```

**Security warning:** Copying the key to the web browser and sending it in a POST FORM is not the safest way. Be sure that you are using an https connection or your key will travel in plain text and your agents could be controlled by anyone that has access to it's ssh port. Another security measure is not-exposing the ssh port to the host and restict the access to the managed network (docker bridge, docker overlay, rancher managed, flannel, etc)

#### Add a slave node

Go to:
```
Jenkins Home Page > Manage settings > Manage Nodes > New Node
```

Fill in the first form:
```
Node name: <name>
(*) Permanent agent

```

Fill in the second form:
```
Name: <name>
# of executors: <n based on your host resources>
Remote root directory: /home/jenkins (it will create a directory named workspace)
Labels: docker docker-compose (this helps the scheduler to assign the proper machine)
Usage: Use this node as much as possible
Launch method: Launch slave agents via SSH
  Host: <"jenkins-slave" if you have 1 single service or container-ip>
  Credentials: jenkins/****
  host Key Verification Strategy: Non verifying--
```
**Note:** Labels are crucial to this set-up because they reveal "properties" of the nodes. If you have a node that has installed `go-lang` builder, you can label this node with `go` and label the build script with `go` too, so the scheduler will always run this work on the labeled node.

## Project setup

There are two ways of setting up your projects:

- Using Blue Ocean
- Using old Jenkins GUI

Assuming that the project is stored on GitHub, it's mandatory to have a user with access to the repository (if it is private) and permissions to manage web-hooks (if you want to trigger the build on pushing).

### Blue Ocean

Just go to Blue Ocean and do:
```
New Pipeline > <Follow the dumb-proof instructions>
```

### Old GUI

#### Project settings

Go to:
```
Jenkins Home Page > Multybranch Pipeline > Manage Nodes > New Node
```
Fill:
```
Credentials: <credentials for the user>
Owner: <The owner of the repo (github.com/<owner>/<repo>)>
Repository: <The repo (github.com/<owner>/<repo>)
```

**Note:** If the project id owned by an Organization, having permissions over that repo is not enought. The account has to be part of that organization with, at least, reading permisions.

#### Github webhook config

 In Jenkins, go to:
 ```
 Jenkins Home Page > Manage Jenkins > Configure System > GitHub
 ```

Create a New GitHub server:
```
Name: <whatever>
API URL: https://api.github.com
Credentials: <login token (it's a secret text type, not a user/pass)>
Manage hooks (*)
```

In Github, go to the repo, and the go to:
```
Settings > Webhooks > Add Webhook
```

Fill:
```
Payload URL: http(s)://{JENKINS_HOMEPAGE_URL}/github-webhook/
(*) Just the `push` event
(*) Active
```

## Jenkinsfile

The key of this set up is that the ci-pipe is managed under version control, in the root of each project unlike the traditional Jenkins where the config lived only in the Jenkins Master.

## SonarQube

> Available soon

# Host minimal Requierements

The tecnical requirements of the services included in this bundle are not trivial:

Average memory allocation is:

- Jenkins Master: ~1.30 GiB
- Jenkins Slave (waiting): ~300 MiB
- Jenkins Slave (running pipes): <highly project-dependent>
- SonarQube: 1.77 GiB
- Sonar Databse (Postgre SQL): ~50 MiB
