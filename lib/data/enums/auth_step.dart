enum AuthStep {
  none, // Not in auth flow, processing orders
  awaitingChoice, // "Sign in or Register?"
  awaitingLoginEmail,
  awaitingLoginPassword,
  awaitingRegisterEmail,
  awaitingRegisterPassword,
  awaitingRegisterConfirm
}