FROM grafana/mimir:3.2.3
COPY mimir.yaml /etc/mimir/config.yaml
CMD ["-config.file=/etc/mimir/config.yaml", "-config.expand-env=true"]
