resource "aws_s3_bucket" "app_public_files" {
  bucket        = "${local.prefix}-files-75bec91675393dcddb"
  acl           = "public-read"
  force_destroy = true # easily destroy our bucket whenever we want.
}