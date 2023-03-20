let
  keys = [
    # srid 
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCYQ003p7fB5ICQehLwhDBomY9WzkNBeijkSw9ADGU+ECrPakeIH3pntUWRJH1W93vKnLqpkn6HLGEXD9MCR0s98uhh8hT7uAYCxQTbEeKT3PYkfz3oe7XaR8rE601sds0ZyFwH7l8cvK97pGr+uhFXAaohiV6VqmLVXhManEjZZ8GfYWBD9BCmIJk43G3OGa5QYFeHqztprXaJNU5dFPv2Uq2C+L6EvfCfkK2OO1BLZgL+Rai5jjyy6k0fcfsxxd9BdGUwqDhcBeyTIzX9rePMugf/xD+6uNRxTU+vjVpGUtFOw6rpgmVyFv9mn3QMNdQBc5hYKVbIQwMNGTzGgcQv"
    # host key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJsX5jbMaKzkBgz+Ltz6doW9LkbNwzqCmoXkW9jdSS2c root@nixos"
  ];
in
# How I rekey on macOS:
  # agenix  -r -i =(op read 'op://Personal/id_rsa/private key')
{
  "ngrok-token.age".publicKeys = keys;
}
