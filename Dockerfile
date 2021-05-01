ARG ISTIO_VERSION
FROM istio/proxyv2:${ISTIO_VERSION}

COPY entrypoint .

ENTRYPOINT ["bash", "entrypoint"]
