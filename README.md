## Running petclinic locally
Petclinic is a [Spring Boot](https://spring.io/guides/gs/spring-boot) application built using [Maven](https://spring.io/guides/gs/maven/). You can build a jar file and run it from the command line:

```
git clone https://github.com/DevopsDelivered/cfn-springboot-petclinic.git
cd cfn-springboot-petclinic
mvn clean package
java -jar target/*.jar
```

You can then access petclinic here: http://localhost:80/

## Database configuration

In its default configuration, Petclinic uses an in-memory database (H2) which
gets populated at startup with data. The h2 console is automatically exposed at `http://localhost:80/h2-console`
and it is possible to inspect the content of the database using the `jdbc:h2:mem:testdb` url.
 
A similar setup is provided for MySql in case a persistent database configuration is needed. Note that whenever the database type is changed, the app needs to be run with a different profile: `spring.profiles.active=mysql` for MySql.

## Publishing the App to Docker Hub

To create a Docker image

```
docker build -t niharsamantaray/springboot-petclinic-v1:latest .
```

To deploy this Docker image to AWS, we need to make it available to AWS somehow. One way to do that is to publish it to Docker Hub, which is the official registry for Docker images. To do this, we call docker login and docker push:

```
docker login
docker push niharsamantaray/springboot-petclinic-v1:latest
```

## Getting Started with AWS Resources

### Create the network stack in CloudFormation

```
aws cloudformation create-stack \
  --stack-name petclinic-network \
  --template-body file://network.yml \
  --capabilities CAPABILITY_IAM

aws cloudformation wait stack-create-complete \
  --stack-name petclinic-network
```

### Create the service stack in CloudFormation

```
aws cloudformation create-stack \
  --stack-name petclinic-service \
  --template-body file://service.yml \
  --parameters \
    ParameterKey=NetworkStackName,ParameterValue=petclinic-network \
    ParameterKey=ServiceName,ParameterValue=springboot-petclinic-v1 \
    ParameterKey=ImageUrl,ParameterValue=docker.io/niharsamantaray/springboot-petclinic-v1:latest \
    ParameterKey=ContainerPort,ParameterValue=80

aws cloudformation wait stack-create-complete \
  --stack-name petclinic-service
```
### AWS command-line magic to extract the public IP address of the running applicatio

```
CLUSTER_NAME=$(
  aws cloudformation describe-stacks \
    --stack-name stratospheric-basic-network \
    --output text \
    --query 'Stacks[0].Outputs[?OutputKey==`ClusterName`].OutputValue | [0]'
)
echo "ECS Cluster:       " $CLUSTER_NAME
```
```
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
```
```
PUBLIC_IP=$(
  aws ec2 describe-network-interfaces \
    --network-interface-ids $ENI_ID \
    --output text \
    --query 'NetworkInterfaces[0].Association.PublicIp'
)
echo "Public IP:         " $PUBLIC_IP
echo "You can access your service at http://$PUBLIC_IP:80"
```

### Delete the service stack in CloudFormation

```
aws cloudformation delete-stack \
  --stack-name petclininc-service

aws cloudformation wait stack-delete-complete \
  --stack-name petclininc-service
```

### Delete the network stack in CloudFormation

```
aws cloudformation delete-stack \
  --stack-name petclininc-network

aws cloudformation wait stack-delete-complete \
  --stack-name petclininc-network
```