# Use AWS Lambda Python 3.11 base image
FROM public.ecr.aws/lambda/python:3.11

# Copy requirements file
COPY requirements.txt .

# Install dependencies to /asset directory
RUN pip install -r requirements.txt -t /asset --no-cache-dir

# Copy Lambda function code
COPY lambda_function.py /asset/

# Set working directory
WORKDIR /asset
