---
title: "Running github-pages gem locally with Docker (part 2)"
date: 2024-07-19
---

After my first attempt at [running the github-pages gem locally]({% post_url 2023-10-10-running-github-pages-gem-locally-with-docker %}), I realized that the docker image in the [pages-gem](https://github.com/github/pages-gem) repository is intended for development of the github-pages gem itself.
The image contains the source of the github-pages gem and installs it from a local folder, which is not something
you need if you only need to run a GitHub Pages site.

For simply running the latest version of the github-pages gem, you can use a docker image which
installs the latest version of github-pages from [rubygems.org](https://rubygems.org/).

The `Dockerfile` looks like this:

```dockerfile
FROM ruby:3.3
COPY Gemfile .
RUN bundle install
WORKDIR /src/site
CMD ["jekyll", "serve", "-H", "0.0.0.0", "-P", "4000"]
```

The `Gemfile` looks like this:

```ruby
source 'https://rubygems.org'
gem 'github-pages', group: :jekyll_plugins
gem 'webrick', '~> 1.8'
```

The `bundle install` command will install the gems specified in the `Gemfile`: the 'github-pages' gem will bootstrap all dependencies for setting up a local Jekyll environment in sync with GitHub Pages, and the 'webrick' gem is required by Jekyll but no longer included with Ruby 3 so needs to be installed separately.

You can build the docker image and run it from the site root folder like this:

```sh
git clone https://gist.github.com/0b345a2656abe079c322ad0a90a32c61.git github-pages-docker
cd github-pages-docker
docker build -t gh-pages .
cd /github-pages-site
docker run --rm -it -p 4000:4000 -v ${PWD}:/src/site gh-pages
```

To make things easier to run, you can place this docker `compose.yaml` file at the root of the site and simply run `docker compose up`:

```yaml
services:
  gh-pages:
    build:
      context: https://gist.github.com/0b345a2656abe079c322ad0a90a32c61.git
      dockerfile: Dockerfile.alpine
    ports:
      - "4000:4000"
    volumes:
      - "./:/src/site"
```

Auto-regeneration did not work for me when running the site on Windows, i.e. the site was not automatically rebuilt and I had to restart Jekyll on each file change. The workaround is to use the `--force_polling` flag which can be specified in the startup command like this:

```yaml
services:
  gh-pages:
    build:
      context: https://gist.github.com/0b345a2656abe079c322ad0a90a32c61.git
      dockerfile: Dockerfile.alpine
    command: sh -c "jekyll serve -H 0.0.0.0 -P 4000 --watch --force_polling"
    ...
```

GitHub Gist: 
__[https://gist.github.com/pmarinova/0b345a2656abe079c322ad0a90a32c61](https://gist.github.com/pmarinova/0b345a2656abe079c322ad0a90a32c61)__