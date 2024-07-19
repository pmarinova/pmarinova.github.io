---
title: "Running github-pages gem locally with Docker (part 2)"
date: 2024-07-19
---

After my first attempt at [running the github-pages gem locally]({% post_url 2023-10-10-running-github-pages-gem-locally-with-docker %}), I realized that the docker image in the [pages-gem](https://github.com/github/pages-gem) repository is intended for development of the github-pages gem itself.

For simply running the latest version of the github-pages gem from [rubygems.org](https://rubygems.org/), you can use a much simpler docker image. The `Dockerfile` looks like this:

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