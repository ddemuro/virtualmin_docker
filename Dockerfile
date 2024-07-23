# The image can be changed for debian:bookworm from Dockerhub.
FROM dkrhub.takelan.com/takelan/core_bookworm:latest AS core

LABEL maintainer="Takelan Development" \
      description="Takelan Virtualmin Image" \
      homepage="www.takelan.com"

WORKDIR /srv

# Prepare for better caching
COPY setup/functions_import.sh setup/functions_import.sh

# Prepares OS
COPY setup/debian_requirements.txt setup/debian_requirements.txt
COPY setup/sudoers setup/sudoers
COPY setup/prepare_os.sh setup/prepare_os.sh
RUN setup/prepare_os.sh

# Prepares virtualenv
COPY setup/setup_env.sh setup/setup_env.sh
RUN setup/setup_env.sh

# Copy Setup
COPY setup/ setup/

# Copy the rest of the project
ADD ./ /srv

#
# Exposed Ports for the container
#

# Named / Bind9
EXPOSE 53/tcp
EXPOSE 53/udp
EXPOSE 953/tcp

# Apache2
EXPOSE 80/tcp
EXPOSE 443/tcp

# SSH
EXPOSE 22/tcp

# MySQL
EXPOSE 3306/tcp

# Postfix
EXPOSE 25/tcp
EXPOSE 587/tcp
EXPOSE 465/tcp

# Dovecot
EXPOSE 110/tcp
EXPOSE 995/tcp
EXPOSE 143/tcp
EXPOSE 993/tcp

# Virtualmin
EXPOSE 10000/tcp
EXPOSE 20000/tcp

ENTRYPOINT ["setup/run.sh"]
