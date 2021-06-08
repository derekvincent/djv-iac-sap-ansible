



Run Sample: 

`./ansible-play-ssm-key.sh /sapm/sap-dev/keypairs/sapm-sap-dev-us-east-1 -i inventory/dev_aws_ec2.yml --limit eccdev.aws.domain.com -e "@dev-variables.yml"  sap-abap-deployment.yml`

```
./ansible-play-ssm-key.sh /sapm/sap-qa/keypairs/sapm-sap-qa-us-east-1 -i inventory/qa_aws_ec2.yml --limit eccqa.aws.domain.com -e "@deploy-vars/qas-variables.yml" sap-abap-deployment.yml
```

../SWPM/sapinst SAPINST_INPUT_PARAMETERS_URL=sap-nw-750-abap-ase.init SAPINST_EXECUTE_PRODUCT_ID=NW_ABAP_OneHost:NW750.SYBBAP  SAPINST_REMOTE_ACCESS_USER=inst SAPINST_REMOTE_ACCESS_USER_IS_TRUSTED=yes

** NVMe suppoerted Instances **
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nvme-ebs-volumes.html
- https://github.com/transferwise/ansible-ebs-automatic-nvme-mapping