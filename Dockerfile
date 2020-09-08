FROM golang:alpine AS build

RUN apk add --no-cache curl git alpine-sdk

RUN curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh

ARG SWAGGER_UI_VERSION=3.20.9

RUN go get github.com/go-openapi/runtime \
    && go get github.com/tylerb/graceful \
    && go get github.com/jessevdk/go-flags \
    && go get golang.org/x/net/context \
    && go get github.com/go-openapi/analysis \
    && go get github.com/go-openapi/spec \
    && go get github.com/gorilla/context \
    && go get github.com/go-openapi/loads \
    && go get github.com/go-openapi/validate \
    && go get github.com/go-openapi/inflect \
    && go get github.com/gorilla/handlers \
    && go get github.com/kr/pretty \
    && go get github.com/pkg/errors \
    && go get github.com/spf13/viper \
    && go get github.com/toqueteos/webbrowser \
    && go get golang.org/x/tools/go/ast/astutil \
    && go get golang.org/x/tools/go/packages \
    && go get golang.org/x/tools/imports \ 
    && go get -d -v github.com/go-swagger/go-swagger \
    && go install github.com/go-swagger/go-swagger/cmd/swagger \
    && curl -sfL https://github.com/swagger-api/swagger-ui/archive/v$SWAGGER_UI_VERSION.tar.gz | tar xz -C /tmp/ \
    && mv /tmp/swagger-ui-$SWAGGER_UI_VERSION /tmp/swagger \
    && sed -i 's#"https://petstore\.swagger\.io/v2/swagger\.json"#"./swagger.json"#g' /tmp/swagger/dist/index.html

WORKDIR $GOPATH/src/github.com/servian/TechChallengeApp

COPY go.mod go.sum $GOPATH/src/github.com/servian/TechChallengeApp/

RUN go mod tidy

COPY . .

RUN go build -o /TechChallengeApp

RUN swagger generate spec -o /swagger.json

FROM alpine:latest

WORKDIR /TechChallengeApp

COPY assets ./assets
COPY conf.toml ./conf.toml

COPY --from=build /tmp/swagger/dist ./assets/swagger
COPY --from=build /swagger.json ./assets/swagger/swagger.json
COPY --from=build /TechChallengeApp TechChallengeApp

#ENTRYPOINT [ "./TechChallengeApp" ]
RUN chmod +x ./TechChallengeApp
CMD ./TechChallengeApp  serve