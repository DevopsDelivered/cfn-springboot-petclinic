aws cloudformation create-stack --stack-name petclinic-basic-network \
--template-body file://network.yml --capabilities CAPABILITY_IAM

aws cloudformation wait stack-create-complete \
--stack-name petclinic-basic-network

aws cloudformation create-stack --stack-name petclinic-basic-service \
--template-body file://service.yml \
--parameters ParameterKey=NetworkStackName,ParameterValue=petclinic-basic-network ParameterKey=ServiceName,ParameterValue=spring-boot-petclinic ParameterKey=ImageUrl,ParameterValue=docker.io/niharsamantaray/spring-boot-petclinic-v1:latest ParameterKey=ContainerPort,ParameterValue=80


aws cloudformation wait stack-create-complete \
--stack-name petclinic-basic-service

CLUSTER_NAME=$(
  aws cloudformation describe-stacks \
    --stack-name petclinic-basic-network \
    --output text \
    --query 'Stacks[0].Outputs[?OutputKey==`ClusterName`].OutputValue | [0]'
)


TASK_ARN=$(
  aws ecs list-tasks \
    --cluster $CLUSTER_NAME \
    --output text --query 'taskArns[0]'
)

echo "ECS Task:          " $TASK_ARN

ENI_ID=$(
  aws ecs describe-tasks \
    --cluster $CLUSTER_NAME \
    --tasks $TASK_ARN \
    --output text \
    --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value'
)

echo "Network Interface: " $ENI_ID

PUBLIC_IP=$(
  aws ec2 describe-network-interfaces \
    --network-interface-ids $ENI_ID \
    --output text \
    --query 'NetworkInterfaces[0].Association.PublicIp'
)