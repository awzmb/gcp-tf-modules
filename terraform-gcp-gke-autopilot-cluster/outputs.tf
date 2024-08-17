output "http_forwarding_rule_ip" {
  value = google_compute_forwarding_rule.tcp_http[0].ip_address
}

output "https_forwarding_rule_ip" {
  value = google_compute_forwarding_rule.tcp_https[0].ip_address
}
