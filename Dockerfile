FROM crystallang/crystal:latest
COPY . /code
WORKDIR /code
RUN apt-get update && apt-get install -y g++ webkit2gtk-4.0-dev make
CMD [/usr/bin/make]
