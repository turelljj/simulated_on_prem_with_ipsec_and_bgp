# Goal
simulate On-Prem env with centos on AWS (different vpc)

# pre
this module use ansible for configuring 'on-prem', so ansible is needed.

# Tools
on-prem : centos8
ipsec   : strongswan
bgp     : frrouting


# Required variables
- AWS_SECRET_ID
- AWS_KEY_ID
- tunnel1_public_ip
- tunnel1_shared_key
- aws_tunnel_1_insde_ip
- on_prem_tunnel_1_inside_ip

- tunnel2_public_ip
- tunnel2_shared_key
- aws_tunnel_2_insde_ip
- on_prem_tunnel_2_inside_ip
