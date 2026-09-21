output "ecs_security_group_id" {
  description = "ID of the ECS security group."
  value       = aws_security_group.ecs.id
}

output "bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.frontend.id
}