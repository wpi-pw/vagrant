Vagrant WordOps for modern WordPress development via WPI
========================
[WPI Cloud](https://cloud.wpi.pw) - [WordOps](https://wordops.net) - [Vagrant](https://vagrantup.com/) - [VagrantCloud](https://app.vagrantup.com/wpi/boxes/box) - [Parallels](https://www.parallels.com)

A LEMP stack with WordOps, Ubuntu 16.04/18.04, vagrant, nginx, apache, php-5-7.4, php-fpm, MariaDB, git, composer, wp-cli and more.

### Run WPI Cloud vagrant init
```shell script
$ curl -sL wpi.pw/wpi > wpi && bash wpi vagrant
```

### Example for generated config
```yaml
ip: "192.168.13.100"
memory: 1024
cpus: 1
hostname: wpi-box
provider: parallels
wpi_email: test@wpi.test # for git and wo notification
wpi_user: test # for git and wo notification
vm_box: wpi/box
id_rsa: ~/.ssh/id_rsa
id_rsa_pub: ~/.ssh/id_rsa.pub

apps:
- host: wpi.test
  status: created
  git:
    scm: github # github, bitbucket
    repo: wpi-pw/app # username/repo-name
    branch: master
  php: php73 # php72
  public_path: htdocs/web # it works only during creation
```