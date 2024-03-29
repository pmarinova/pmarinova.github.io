---
title: "Running github-pages gem locally with Docker"
date: 2023-10-10
---

One of the first challenges I faced while setting up this blog was about testing it locally before pushing any changes to GitHub.
After some research, I stumbled upon the GitHub [pages-gem](https://github.com/github/pages-gem) project, which is exactly what I needed.

I definitely didn't want to install yet another development environment with Ruby and Jekyll, so I went directly for the containerized approach 
hoping to use it as a black box, without getting into too much detail of how it works. My goal was to just replicate whatever GitHub Pages was 
doing after pushing any changes to the repository.

I followed the exact steps as described in the readme:
1. Run docker build from the root of the pages-gem directory:

    ```sh
    docker build -t gh-pages .
    ```

2. Start an instance of the server by running this command from the root of the site:

    ```sh
    docker run --rm -it -p 4000:4000 -v ${PWD}:/src/site gh-pages
    ```

But it didn't work for me - the generated site was just plain text:
![Screenshot of site not working](/assets/images/2023-10-10/site_not_working.png)

After some more digging I realized my site was missing the `Gemfile` which brings the `github-pages` gem dependency.
Why did I miss the Gemfile? Because I had created the repository by following the official [GitHub Pages tutorial](https://github.com/skills/github-pages).
Turns out that GitHub Pages ignores the project Gemfile and uses its own, because it supports only a [limited set of plugins](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/about-github-pages-and-jekyll#plugins).

To run the site locally I had to add this Gemfile at the project root:
```ruby
source 'https://rubygems.org'
gem 'github-pages', group: :jekyll_plugins
```

Now when I attempted to start the site with Jekyll I got the following error:
> Could not find github-pages-228 in locally installed gems (Bundler::GemNotFound)

Apparently I had to run `bundle install` before `jekyll serve`. To do this I simply started the container by chaining the commands like this:
```sh
docker run --rm -it \
    -p 4000:4000 \
    -v ${PWD}:/src/site \
    gh-pages \
    sh -c "bundle install && jekyll serve -H 0.0.0.0 -P 4000" 
```

Now the site is running:
![Screenshot of site working](/assets/images/2023-10-10/site_working.png)

As someone who has no experience with Ruby, Jekyll and the rest of the GitHub Pages stack I would say the containerized approach 
for github-pages needs improvement or at least a better readme. I submitted an [issue](https://github.com/github/pages-gem/issues/891)
for this and perhaps someone will clarify how the container should be used.

#### Update 2024-02-12

After updating to the latest version of the pages-gem (v229), I got a new error:
> /usr/local/bundle/gems/jekyll-3.9.4/lib/jekyll/commands/serve/servlet.rb:3: warning: webrick was loaded from the standard library, but is not part of the default gems since Ruby 3.0.0. Add webrick to your Gemfile or gemspec. Also contact author of jekyll-3.9.4 to add webrick into its gemspec.
> /usr/local/lib/ruby/3.3.0/bundled_gems.rb:74:in `require': cannot load such file -- webrick (LoadError)

This was because the docker image was updated to Ruby 3 and causes [issue 752](https://github.com/github/pages-gem/issues/752).

The workaround is to add the `webrick` dependency explicitly in your Gemfile like this:

```ruby
source 'https://rubygems.org'
gem 'github-pages', group: :jekyll_plugins
gem 'webrick', '~> 1.8'
```