provider "aws" {
	region = "us-east-1"
}


resource "aws_s3_bucket" "aws-bucket" {
  bucket = "${var.s3-source-buc-name}"
  acl    = "private"

  tags {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket" "aws-dest-bucket" {
  bucket = "${var.s3-destination-buc-name}"
  acl    = "private"

  tags {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_cloudtrail" "ct" {
  name                          = "tf-trail-ct"
  s3_bucket_name                = "${aws_s3_bucket.ct-bucket.id}"
  s3_key_prefix                 = "prefix"
  include_global_service_events = false
  event_selector {
    read_write_type = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      # Make sure to append a trailing '/' to your ARN if you want
      # to monitor all objects in a bucket.
      values = ["${aws_s3_bucket.aws-bucket.arn}/"]
    }
  }
}

resource "aws_s3_bucket" "ct-bucket" {
  bucket        = "ct-tf-events-lambda"
  force_destroy = true

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::ct-tf-events-lambda"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::ct-tf-events-lambda/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}



resource "aws_lambda_function" "demo_lambda" {
    function_name = "${lambda_name}"
    handler = "test.sample"
    runtime = "python2.7"
    filename = "function.zip"
    source_code_hash = "${base64sha256(file("function.zip"))}"
    role = "${aws_iam_role.lambda_exec_role.arn}"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }

  ]
}
EOF
}

resource "aws_iam_role_policy" "test_policy" {
  name = "test_policy"
  role = "${aws_iam_role.lambda_exec_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}


resource "aws_cloudwatch_event_rule" "s3-upload" {
  name        = "capture-s3-upload"
  description = "Capture each upload to s3"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.s3"
  ],
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "s3.amazonaws.com"
    ],
    "eventName": [
      "PutObject"
    ],
    "requestParameters": {
      "bucketName": [
        "lambda-source-up-test"
      ]
    }
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "s3" {
  rule      = "${aws_cloudwatch_event_rule.s3-upload.name}"
  target_id = "trigger-lambda"
  arn       = "${aws_lambda_function.demo_lambda.arn}"
}
