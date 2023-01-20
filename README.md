# System Setup and SAP Installation Ansible
The Ansible playbooks are used to automate the OS of the deployments 

## Secrets Storage in SSM Parameter Store
The master password and ssh keys are stored in an AWS SSM parameter value in order to remove the need to maintain these on the each instance or store them as a variable in a file. 

### SAP Master Password 
The SAP master password is used from the SAP ABAP deployment ansible playbook and the parameter name is specified in the variables files under the `master_password_ssm_key` variable. 

<ins>Setting the master password example:</ins>
```
aws ssm put-parameter \
        --name "/sapm/sap-prod/PRD/master_password" \
        --type SecureString \
        --value "trUGsN_d7B,Nvse"
```

### EC2 Instance SSH key
The instance ssh key is used from a script provided `ansible-play-ssm-key.sh` that will take the parameter key name as an input as well as the rest of the ansible command line. It will fetch the SSH key from the parameter store and temporarily set it with the ssh-agent.  

<ins>Setting the SSH key example:</ins>
```
aws ssm put-parameter \
        --name "/sapm/sap-dev/keypairs/sapm-sap-dev-us-east-1" \
        --type SecureString \
        --value "$(cat ~/Downloads/sapm-sap-dev-us-east-1.pem)"
```
## SAP ABAP Build 
The Ansible playbook `sap-abap-build.yml` is generally invoked by a Terraform and it completes the EC2 instance provisioning for an SAP based system. 

It provides the following: 
- If the system uses NVME based disk mapping is done
- Sets up the disk as per the input variables
  - Enables the swap device 
  - Creates and enables the LVM devices
  - Creates the block devices
- Sets the hostname and updates the host file
- Sets the timezone (America/Toronto)
- Set the following Kernel parameters for SAP
  - vm.swappiness - 20
  - fs.aio-max-nr - 1048576
  - fs.file-max - 6291456
  - vm.nr_hugepages_size - input variable
  - Add `/etc/security/limits.d/sap-hugepage.conf` with @sapsys, @dba, @sdba memlock unlimited
- Update `/etc/profile.local` with TMOUT=600 and CPIC_MAC_CONV=2000
- Add a `~/.aws/config` with a profile for the S3 role ARN (input variable) assumed role
- Applies package updates and install additional packages as follows:
  - Updates all packages
  - Install, enable and starts the syststat package
  - Install, enable and starts the uuidd package
  - Install the libaio1 package
  - Install the unzip package
  - Install the unrar package
  - Install the sapconf package 
  - Install, enable and starts the Amazon SSM Agent package  
  - Install the Amazon EFS Utils package
  - Install the Amazon SAP Data providers package
- If the system type is ADS also installs:
  - glibc-32bit
  - glibc-i18ndata
  - glibc-locale-32bit
  - libgcc_s1-32bit
  - libidn11-32bit
  - libX11-6-32bit
  - libcurl4-32bit
  - libz1-32bit
  - libuuid1-32bit
- If EFS is used determines the proper mount devices for the AZ and mounts the EFS file system

## SAP ABAP Deployment
The Ansible `sap-abap-deployment.yml` playbook with provision vanilla SAP ABAP system on ASE with the option to drop the database in preparation for a migration.  

___NOTE: This deployment can run upwards or an hour and sessions timeouts occur, use the `screen` command to create a new session and work in that.___

The playbook provides the following: 
- Fetch the master password from the parameter store
- Creates the software and SWPM directories under the `/sapmnt/sltools` folder. 
- Downloads S3 files from the specified bucket and prefix
- Move the `sapcar` program to `/usr/local/bin` and make it executable
- Expands the export archives 
- Expands the SWPM sar file 
- Creates the `sapinst` user group 
- Prepare the installation folder with SAP installation parameter file and updates the file from the input parameters
- Installs the SAP ABAP system 
- Installs the SAP DAA agent 
- Stop the SAP system and run the SAP `cleanSAPSR3Schema.sql` in order to drop the entire SAP database in preparation for the migration.
- Removes the `sap_install` and `daa_install` as part of the post cleanup

### How to run the playbook

In order to run the playbooks a parameters are required 
  
- An inventory file is needed and is pulling live from AWS, these are setup by different files and in the inventory folder and these files filter based on `sapm:environment` tags assigned to EC2 instances. If an new account or environment is being setup then a new files needs to be created and adapted. 
- It is very important to use the `limit` parameter to specify the system you want to run the playbook on. If wide open you run the risk of running it on all instances available with the inventory file.
- The specific deployment variables are set in a file in the `deploy-vars` folder. The base files are the minimum required for a system install but any variables or facts found in the playbooks can be set. 

<ins>Example Run</ins>
```
./ansible-play-ssm-key.sh /sapm/sap-qa/keypairs/sapm-sap-qa-us-east-1 -i inventory/qa_aws_ec2.yml --limit eccqa.aws.domain.com -e "@deploy-vars/QAS-variables.yml" sap-abap-deployment.yml
```

### Debugging the Installation
At time the SAP installation runs into issues and after looking through the logs file another debugging method is to start `sapinst` in interactive mode. 

In order to do this an OS user needs to be create with a password that is specified in the `SAPINST_REMOTE_ACCESS_USER` parameter in order to be able to log into the `sapinst` gui. 

Once this is done this command can be run from the `/sapmnt/sltools/sap_install` folder. 
```
../SWPM/sapinst SAPINST_INPUT_PARAMETERS_URL=sap-nw-750-abap-ase.init SAPINST_EXECUTE_PRODUCT_ID=NW_ABAP_OneHost:NW750.SYBBAP  SAPINST_REMOTE_ACCESS_USER=os-user SAPINST_REMOTE_ACCESS_USER_IS_TRUSTED=yes
```
## Commvault Agent 
The `commvault-agent.yml` playbook installs a pre-build Commvault agent package for SAP ASE. In order run the playbook the ASE database need to be installed on the instance already. Due to this it is run separately after the migration is completed. 

The playbook provides:
- Creation of the ocs.cfg file in Sybase OCS-16 directory
- Installed the pre-requisite packages libncurses5 and device-mapper 
- Download and install the Commvault agent 

<ins>Commvault agent command sample:</ins>
```
./ansible-play-ssm-key.sh /sapm/sap-qa/keypairs/sapm-sap-qa-us-east-1 -i inventory/qa_aws_ec2.yml --limit eccqa.aws.domain.com commvault-agent.yml
```

## SAP Business Connector
The Ansible playbook `sap-bc-playbook.yml` is generally invoked by a Terraform and it completes the EC2 instance provisioning for an SAP based system. 

The playbook provides:
- Sets the hostname and updates the host file
- Sets the timezone (America/Toronto)
- Add a `~/.aws/config` with a profile for the S3 role ARN (input variable) assumed role
- Updates all packages and installs the following:
  - unzip
  - nfs-client
  - insserv
  - glibc
  - glibc-32bit
  - java
  - Amazon SSM Agent
- Downloads the SAP BC software from the specified S3 bucket and prefix
- Installs the SAP BC software in the /opt/sapbc48
- Applies the specified SAP BC license 
- Updates the SAP JVM for BC
- Patches the BC
- Enables and starts the SAP BC service 
- Add the specified NFS mount points to the `fstab`




# References
**NVMe supported Instances**
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nvme-ebs-volumes.html
- https://github.com/transferwise/ansible-ebs-automatic-nvme-mapping

**Transient SSH key usage**
- https://alestic.com/2018/12/aws-ssm-parameter-store-git-key/