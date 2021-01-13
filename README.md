



Run Sample: 

`./ansible-play-ssm-key.sh /sapm/sap-dev/keypairs/sapm-sap-dev-us-east-1 -i inventory/dev_aws_ec2.yml --limit eccdev.aws.domain.com -e "@dev-variables.yml"  sap-abap-deployment.yml`

** NVMe suppoerted Instances **
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nvme-ebs-volumes.html
- https://github.com/transferwise/ansible-ebs-automatic-nvme-mapping