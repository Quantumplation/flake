{ pkgs, ... }: {
  # Define user accounts
  users.users.pi = {
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "tty" "dialout" "docker" ];
    initialPassword = "password";
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCyexXui4Jvxh85549AtNVyUfYrj+esUZkT0a6XKnCeUaMbWmQpA1K0gGfZ9GXTCc8WhpkeizRQbUX42d2NYp7KUzRCB6wcrTwNMfr2yGtg6eyvkF3xfGB8Zlv9lCJ77TQuCS7gJnxMuao4f9KlpSFdUnt/ljjMXBFCkXE0p91cHaDgf9tHnQDnb4pRV7QL7xGw4HqQDnD0GbjcHIKh77yIF01lE3/N4eL/AGoDmRB7W1n0Bq7gMLW3bJHSOv2weIuNUyPqZjy0yuqHZgS1HlbcYxmqRXOB23IWKliNokWtP7zj2rvmaq5asOeAZ3DdukWaMcb3/75Xam5MXYhyqwZ385ULXU3bp0Stj5KFlDHPy93KRVDq1xYRIqok89KtNPvZhH8uR3nrLNB9LrC3w2A5KK3xCdKgcN+V7PHPLY5J6BhMbJaaH7rid/eMADM/RhGpxeogNzvbpI3px2lgtCXgqTDRsXzE6pOw4uKfOLjBWOSBNtWM2oNqmMUhcqSOQzM= pi"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIJ/dREQHWeS7YuT3x8UK7jbgTLUFyJ84aeJrYootfYa quantumplation@QuantumtionsMBP.lan"
    ];
  };
}
