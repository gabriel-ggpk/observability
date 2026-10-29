FROM grafana/tempo:3.1.1
COPY tempo.yaml /etc/tempo/config.yaml
CMD ["-config.file=/etc/tempo/config.yaml", "-config.expand-env=true"]
