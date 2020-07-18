# Non-official builder image. It's mainly for automating docker hub builds.
# official Dockerfile resides in docker/, and it's called by Makefile targets.

###########################################################
###  builder imageA         ###############################
###########################################################
FROM golang:1.14.6-alpine AS builder

RUN apk --no-cache add ca-certificates make git && update-ca-certificates
WORKDIR /go/src/github.com/zalando/postgres-operator/
COPY . .
RUN make linux

###########################################################
### operator image -> the version with full alpine image ##
###########################################################
## This is optional, only as example. Only last image is used
FROM alpine:3.12.0 as postgres-operator-alpine
MAINTAINER Team ACID @ Zalando <team-acid@zalando.de>
LABEL org.opencontainers.image.authors "Team ACID @ Zalando <team-acid@zalando.de>"
LABEL org.opencontainers.image.url "https://github.com/zalando/postgres-operator/"
LABEL org.opencontainers.image.documentation "https://github.com/zalando/postgres-operator/"
LABEL org.opencontainers.image.source "https://github.com/zalando/postgres-operator/"
LABEL org.opencontainers.image.title "zalando/posgress-operator"
LABEL org.opencontainers.image.description "posgress-operator-alpine - full alpine image"
# We need root certificates to deal with teams api over https
RUN apk --no-cache add ca-certificates && update-ca-certificates
COPY --from=builder /go/src/github.com/zalando/postgres-operator/build/* /
RUN addgroup -g 1000 pgo
RUN adduser -D -u 1000 -G pgo -g 'Postgres Operator' pgo
USER 1000:1000
ENTRYPOINT ["/postgres-operator"]

################################################################
### operator image -> the more secure version (from scratch) ###
################################################################
FROM scratch AS postgres-operator-secure
MAINTAINER Team ACID @ Zalando <team-acid@zalando.de>
LABEL org.opencontainers.image.authors "Team ACID @ Zalando <team-acid@zalando.de>"
LABEL org.opencontainers.image.url "https://github.com/zalando/postgres-operator/"
LABEL org.opencontainers.image.documentation "https://github.com/zalando/postgres-operator/"
LABEL org.opencontainers.image.source "https://github.com/zalando/postgres-operator/"
LABEL org.opencontainers.image.title "zalando/posgress-operator"
LABEL org.opencontainers.image.description "posgress-operator-secure from scratch image"

COPY --from=builder /etc/passwd /etc/group /etc/

# We need root certificates to deal with teams api over https
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /go/src/github.com/zalando/postgres-operator/build/* /

USER nobody
ENTRYPOINT ["/postgres-operator"]

