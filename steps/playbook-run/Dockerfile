FROM relaysh/core:latest-python
RUN apk --no-cache add --virtual ansible-build-deps gcc libc-dev libffi-dev \
    && pip --no-cache-dir install ansible \
    && apk --no-cache del ansible-build-deps
COPY step.sh /
CMD ["sh", "-c", "/step.sh"]
