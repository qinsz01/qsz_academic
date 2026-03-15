# Academic Pages

![pages-build-deployment](https://github.com/academicpages/academicpages.github.io/actions/workflows/pages/pages-build-deployment/badge.svg)

Academic Pages is a Github Pages template for academic websites.

# Getting Started

1. Register a GitHub account if you don't have one and confirm your e-mail (required!)
1. Click the "Use this template" button in the top right.
1. On the "New repository" page, enter your repository name as "[your GitHub username].github.io", which will also be your website's URL.
1. Set site-wide configuration and add your content.
1. Upload any files (like PDFs, .zip files, etc.) to the `files/` directory. They will appear at https://[your GitHub username].github.io/files/example.pdf.
1. Check status by going to the repository settings, in the "GitHub pages" section
1. (Optional) Use the Jupyter notebooks or python scripts in the `markdown_generator` folder to generate markdown files for publications and talks from a TSV file.

See more info at https://academicpages.github.io/

## Running Locally

When you are initially working your website, it is very useful to be able to preview the changes locally before pushing them to GitHub. To work locally you will need to:

1. Clone the repository and made updates as detailed above.
1. Make sure you have ruby-dev, bundler, and nodejs installed
    
    On most Linux distribution and [Windows Subsystem Linux](https://learn.microsoft.com/en-us/windows/wsl/about) the command is:
    ```bash
    sudo apt install ruby-dev ruby-bundler nodejs
    ```
    On MacOS the commands are:
    ```bash
    brew install ruby
    brew install node
    gem install bundler
    ```
1. Run `bundle install` to install ruby dependencies. If you get errors, delete Gemfile.lock and try again.
1. Run `jekyll serve -l -H localhost` to generate the HTML and serve it from `localhost:4000` the local server will automatically rebuild and refresh the pages on change.

If you are running on Linux it may be necessary to install some additional dependencies prior to being able to run locally: `sudo apt install build-essential gcc make`

# Maintenance

Bug reports and feature requests to the template should be [submitted via GitHub](https://github.com/academicpages/academicpages.github.io/issues/new/choose). For questions concerning how to style the template, please feel free to start a [new discussion on GitHub](https://github.com/academicpages/academicpages.github.io/discussions).

This repository was forked (then detached) by [Stuart Geiger](https://github.com/staeiou) from the [Minimal Mistakes Jekyll Theme](https://mmistakes.github.io/minimal-mistakes/), which is © 2016 Michael Rose and released under the MIT License (see LICENSE.md). It is currently being maintained by [Robert Zupko](https://github.com/rjzupkoii) and additional maintainers would be welcomed.

## Bugfixes and enhancements

If you have bugfixes and enhancements that you would like to submit as a pull request, you will need to [fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo) this repository as opposed to using it as a template. This will also allow you to [synchronize your copy](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork) of template to your fork as well.

Unfortunately, one logistical issue with a template theme like Academic Pages that makes it a little tricky to get bug fixes and updates to the core theme. If you use this template and customize it, you will probably get merge conflicts if you attempt to synchronize. If you want to save your various .yml configuration files and markdown files, you can delete the repository and fork it again. Or you can manually patch.

## Deploy with Nginx on your own server (auto pull + build)

This project includes a local deployment pipeline that does not use GitHub Pages:

1. A timer triggers `deploy/deploy.sh` every 2 minutes.
1. The script runs `git pull`, builds assets, and builds Jekyll.
1. It publishes to `/var/www/qsz_academic/releases/<timestamp>` and updates `/var/www/qsz_academic/current` atomically.
1. Nginx serves static files from `/var/www/qsz_academic/current`.

### 1) Install dependencies (Ubuntu)

```bash
sudo apt update
sudo apt install -y nginx ruby-full build-essential zlib1g-dev nodejs npm
sudo gem install bundler
```

### 2) Configure project deployment settings

```bash
cd /home/ubuntu/qsz/qsz_academic
cp deploy/deploy.env.example deploy/deploy.env
```

Optional: edit `deploy/deploy.env` if your branch/repo path/deploy path differs.

If your production domain is not `qinsizhong.com`, edit `_config_prod.yml`.

### 3) Configure systemd automation

```bash
sudo cp deploy/systemd/qsz-academic-deploy.service /etc/systemd/system/
sudo cp deploy/systemd/qsz-academic-deploy.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now qsz-academic-deploy.timer
sudo systemctl start qsz-academic-deploy.service
```

Check status/logs:

```bash
systemctl status qsz-academic-deploy.timer
journalctl -u qsz-academic-deploy.service -n 100 --no-pager
```

### 4) Configure Nginx

```bash
sudo cp deploy/nginx/qinsizhong.com.conf /etc/nginx/sites-available/qsz-academic.conf
sudo ln -sf /etc/nginx/sites-available/qsz-academic.conf /etc/nginx/sites-enabled/qsz-academic.conf
sudo nginx -t
sudo systemctl reload nginx
```

### 5) DNS

Point your domain A/AAAA records to this server IP.

For HTTPS, install certbot and issue a certificate after DNS takes effect.
