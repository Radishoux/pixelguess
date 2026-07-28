/// Why pixels are being spent. Kept generic so future spends (hints,
/// extra attempts) don't require a new spend path — only a new reason.
enum SpendReason {
  reveal,
  hint,
  extraAttempt,
}
