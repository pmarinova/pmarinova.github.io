This is the repository from which my site https://pmarinova.github.io/ is generated.

To run the site locally with Docker:

1. Build a recent github-pages image (replace v229 with the latest tagged release)

```sh
git clone https://github.com/github/pages-gem
cd pages-gem
git checkout v229
docker build -t gh-pages .
```

2. Run the github-pages image by executing either `gh-pages-serve.bat` or `gh-pages-serve.sh`
from the root of the site