FROM --platform=linux/amd64 ev3dev/debian-stretch-armel-cross

# FIXME: Remove after testing
RUN echo 'hello world'

# # Fix for Debian Stretch end-of-life
# # Adapted from https://stackoverflow.com/a/76095392
# RUN sudo sed -i -e 's/deb.debian.org/archive.debian.org/g' \
#                 -e 's/ftp.debian.org/archive.debian.org/g' \
#                 -e 's|security.debian.org|archive.debian.org/|g' \
#                 -e '/stretch\/updates/d' \
#                 -e '/stretch-updates/d' /etc/apt/sources.list

# # valac does not work with multiarch, hence using debian-stretch-armel-cross, not debian-stretch-cross
# # valac is preinstalled in debian-stretch-armel-cross
# RUN ["sudo", "bash", "-c", "apt-get update && apt install --yes --no-install-recommends libev3devkit-dev:armel libgudev-1.0-dev:armel"]
# ENTRYPOINT [ "/usr/bin/valac", "--pkg=linux", "--pkg=posix", "--pkg=ev3devkit-0.5", "--pkg=gio-unix-2.0", "--pkg=grx-3.0", "--pkg=glib-2.0", "--pkg=gudev-1.0" ]