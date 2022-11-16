FROM docker.io/perl:5.34.1-slim-threaded
LABEL maintainer="Mac Wynkoop <mwynkoop@siliconiq.com>"
LABEL version 0.1
LABEL description="Unofficial docker image for Bugzilla 5.2"

ENV bugzilla_branch=5.2

ARG DEBIAN_FRONTEND=noninteractive

##################
##   BUILDING   ##
##################

WORKDIR /

# Prepare the entrypoint script just to start the supervisord
ADD entrypoint.sh /entrypoint.sh
RUN chmod 700 /entrypoint.sh
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN chmod 700 /etc/supervisor/conf.d/supervisord.conf

# Install Bugzilla following https://bugzilla.readthedocs.io/en/5.2/installing/index.html
WORKDIR /var/www/html
RUN git clone --branch ${bugzilla_branch} https://github.com/bugzilla/bugzilla
RUN perl -MCPAN -e "install CPAN"

# Ensure Bugzilla installation and Perl is all right, this may take some time
WORKDIR /var/www/html/bugzilla
RUN ./checksetup.pl --check-modules # generates a Perl module check
RUN ./install-module.pl --all  # install missing Perl modules
ADD perl_patch /tmp/perl_patch
# needed to fix Perl5 issue #17271,
# see https://stackoverflow.com/questions/56475712/getting-undefined-subroutine-utf8swashnew-called-at-bugzilla-util-pm-line-109
RUN patch -u /usr/share/perl/5.30.0/Safe.pm -i /tmp/perl_patch
# now we can continue with normal setup
RUN ./checksetup.pl  # generates localconfig file

# Make the images available for backup and restore
VOLUME /var/www/html/bugzilla/images
VOLUME /var/www/html/bugzilla/data
VOLUME /var/www/html/bugzilla/lib

# Start the supervisord
WORKDIR /tmp
CMD ["/entrypoint.sh"]
