aws cloudformation delete-stack \
  --stack-name petclininc-basic-service

aws cloudformation wait stack-delete-complete \
  --stack-name petclininc-basic-service

aws cloudformation delete-stack \
  --stack-name petclininc-basic-network

aws cloudformation wait stack-delete-complete \
  --stack-name petclininc-basic-network