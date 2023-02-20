FROM docker.io/redhat/ubi8-minimal:8.7

RUN microdnf -y install openssl

WORKDIR /ca

COPY certificate/ ./certificate/
COPY *.sh .
RUN chmod 755 *.sh && mv *.sh /usr/local/bin

CMD ["/usr/local/bin/shell.sh"]
