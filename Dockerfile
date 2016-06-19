FROM haproxy

RUN apt-get update && \
    apt-get install -y ruby && \
    echo "install: --no-document" > /etc/gemrc && \
    gem update --system && \
    gem install minitest

RUN mkdir /tests
VOLUME /tests

WORKDIR /tests

CMD haproxy -f /usr/local/etc/haproxy/haproxy.cfg && ruby -Ilib example.rb -v -p

# docker build -t proxsee .
# docker run -it --rm -v $(pwd)/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg -v $(pwd):/tests proxsee

