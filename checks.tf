
check "relay_enabled" {
  assert {
    condition     = var.relay_asset_changes || var.relay_audit_log
    error_message = "One of relay_asset_changes or relay_audit_log must be true"
  }
}
