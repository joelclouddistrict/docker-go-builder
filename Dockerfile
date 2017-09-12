# $ docker run -ti -v $PWD:/go/src/bitbucket.org/acbapis/legalitas -v /Users/jllopis/devel/go/own/src/bitbucket.org/acbapis/acbapis:/go/src/bitbucket.org/acbapis/acbapis buildert bitbucket.org/acbapis/legalitas bGludXgK
FROM debian:buster-slim

# gcc for cgo
RUN apt-get update && apt-get install -y --no-install-recommends \
		g++ \
		gcc \
		libc6-dev \
		make \
		pkg-config \
		wget \
		git \
		unzip \
		ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

ENV GOLANG_VERSION 1.9
ENV PROTOC_VERSION 3.4.0

RUN set -eux; \
	url="https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz"; \
	wget --no-check-certificate -O go.tgz "$url"; \
	tar -C /usr/local -xzf go.tgz; \
	rm go.tgz; \
	export PATH="/usr/local/go/bin:$PATH"; \
	go version

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

COPY run.sh /run.sh

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH

# Install protocol buffers compiler
RUN wget "https://github.com/google/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip" ; \
unzip -p protoc-${PROTOC_VERSION}-linux-x86_64.zip bin/protoc > /usr/local/bin/protoc ; \
chmod +x /usr/local/bin/protoc ; \
rm protoc-${PROTOC_VERSION}-linux-x86_64.zip

# Install gogoprotobuf
RUN go get -u github.com/gogo/protobuf/proto ; \
	go get -u github.com/gogo/protobuf/jsonpb ; \
	go get -u github.com/gogo/protobuf/protoc-gen-gogo ; \
	go get -u github.com/gogo/protobuf/gogoproto

# Install grpc-go and grpc-gateway and companions
RUN go get -u google.golang.org/grpc ; \
	go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway ; \
	go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger ; \
	go get -u github.com/golang/protobuf/protoc-gen-go

# Copy compiled files (do not compile with protogogo. Must be fixed!
COPY annotations.pb.go /go/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis/google/api
COPY http.pb.go /go/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis/google/api

ENTRYPOINT ["/run.sh"]
