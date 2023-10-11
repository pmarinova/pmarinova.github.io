#!/bin/bash
docker run --rm -it \
-p 4000:4000 \
-v ${PWD}:/src/site \
gh-pages \
sh -c "bundle install && jekyll serve -H 0.0.0.0 -P 4000" 