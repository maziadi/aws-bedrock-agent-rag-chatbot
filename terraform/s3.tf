########################################
# S3 bucket for voice uploads (Transcribe input)
########################################
resource "aws_s3_bucket" "voice" {
  bucket = var.voice_bucket_name
}

# S3 Bucket (contenant les Documents à indexer)
resource "aws_s3_bucket" "kb_data" {
  bucket = "crayon-knowledge-base-data"
}