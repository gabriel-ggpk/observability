FROM grafana/loki:3.7.9
COPY loki.yaml /etc/loki/config.yaml
CMD ["-config.file=/etc/loki/config.yaml", "-config.expand-env=true"]
