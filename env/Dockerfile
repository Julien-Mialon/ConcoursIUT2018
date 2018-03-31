# Base image with Nix installed: https://github.com/LnL7/nix-docker
FROM lnl7/nix:1.11.16

# Survival kit
RUN nix-env -i git gnutar gzip

# Bash fun
RUN nix-env -i coreutils binutils findutils gnused gawk netcat-gnu jq

# Retrieve code
RUN git clone https://github.com/Julien-Mialon/ConcoursIUT2018.git /bot
