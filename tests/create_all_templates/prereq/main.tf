resource "random_string" "this" {
  length  = 6
  upper   = false
  special = false
  numeric = false
}

output "random_string" {
  value = random_string.this
}
