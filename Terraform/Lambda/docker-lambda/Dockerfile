# Use the official Python 3.9 image as the base image
FROM public.ecr.aws/lambda/python:3.9

# Copy the Lambda function code into the container
COPY lambda_function.py ${LAMBDA_TASK_ROOT}

# Install the requests library
RUN pip install requests

# Set the CMD to your handler
CMD ["lambda_function.lambda_handler"]