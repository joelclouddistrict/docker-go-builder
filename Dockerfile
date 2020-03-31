# $ docker run -ti -v $PWD:/go/src/bitbucket.org/acbapis/legalitas -v /Users/jllopis/devel/go/own/src/bitbucket.org/acbapis/acbapis:/go/src/bitbucket.org/acbapis/acbapis buildert bitbucket.org/acbapis/legalitas bGludXgK
FROM debian:buster-slim AS builder

# gcc for cgo
RUN buildDeps='build-essential curl autoconf automake libtool zlib1g-dev libgflags-dev libgtest-dev clang libc++-dev gcc g++ libc6-dev pkg-config wget apt libc-ares-dev'; \
		apt-get update && apt-get install -y --no-install-recommends \
		make \
		git \
		unzip \
		ca-certificates \
		$buildDeps

ENV GOLANG_VERSION 1.12.4
ENV PROTOC_VERSION 3.7.1
ENV GRPC_GO_VERSION 1.28.0
ENV GRPC_GATEWAY_VERSION 1.8.5

RUN set -eux; \
	url="https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz"; \
	wget --no-check-certificate -O go.tgz "$url"; \
	tar -C /usr/local -xzf go.tgz; \
	rm go.tgz; \
	export PATH="/usr/local/go/bin:$PATH"; \
	go version

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH

# Install protocol buffers compiler
RUN wget https://github.com/google/protobuf/archive/v${PROTOC_VERSION}.tar.gz && \
tar zxvf v${PROTOC_VERSION}.tar.gz  && \
cd protobuf-${PROTOC_VERSION} && \
./autogen.sh && \
./configure && \
make && \
make install && \
ldconfig && \
cd $GOPATH && \
rm v${PROTOC_VERSION}.tar.gz && \
rm -rf protobuf-${PROTOC_VERSION}

# Install grpc-go and grpc-gateway and companions
RUN go get -u google.golang.org/grpc ; \
	go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway ; \
	go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger

# Install go grpc protobuf plugin
RUN go get -u github.com/golang/protobuf/protoc-gen-go

# Install grpc plugins
RUN git clone -b $(curl -L https://grpc.io/release) https://github.com/grpc/grpc && \
cd grpc && \
git submodule update --init && \
for plugin in grpc_php_plugin \
	grpc_python_plugin \
	grpc_ruby_plugin \
	grpc_objective_c_plugin \
	grpc_node_plugin \
	grpc_csharp_plugin \
	grpc_cpp_plugin; \
	do make ${plugin}; \
		cp bins/opt/${plugin} /usr/local/bin/${plugin} ; \
	done && \
cd $GOPATH && \
rm -rf grpc

RUN cp /go/src/google.golang.org/genproto/googleapis/api/annotations/*.pb.go /go/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis/google/api/

# Cleanup
RUN apt purge $buildDeps && rm -rf /var/lib/apt/lists/*

FROM debian:buster-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
		gcc \
		libc6-dev \
		make \
		git \
		unzip \
		ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

COPY --from=builder /usr/local/go /usr/local/go
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/local/include /usr/local/include
COPY --from=builder /go /go

RUN ldconfig

RUN go version

WORKDIR $GOPATH

ENTRYPOINT ["/run.sh"]
