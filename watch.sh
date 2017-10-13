#!/bin/bash
while true; do
    inotifywait -e modify,create,delete -r . && \
        pkill python && rm -r _build && make && $(cd ./_build && python -m SimpleHTTPServer)
done
