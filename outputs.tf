outputs.tf

output "s3 source bucket arn" {
	value = "${aws_s3_bucket.aws-bucket.arn}"
}

output "s3 destination bucket arn" {
	value = "${aws_s3_bucket.aws-dest-bucket.arn}"
}

output "Lambda arn" {
	value = "${aws_lambda_function.demo_lambda.arn}"
}
