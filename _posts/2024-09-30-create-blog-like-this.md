---
title: How to create a blog like this
description: This is a guide to using the Chirpy Jekyll theme to create a personal blog like this
author: hoan9x
date: 2024-09-30 12:00:00 +0700
categories: [Personal blog, Chirpy Jekyll theme]
---

## About GitHub Pages

This blog uses the **GitHub Pages** feature which allows you to host static web pages directly from your GitHub repository. You can find all information about GitHub Pages features [here](https://docs.github.com/en/pages/getting-started-with-github-pages/about-github-pages#about-github-pages).

Please read the [usage limits](https://docs.github.com/en/pages/getting-started-with-github-pages/about-github-pages#usage-limits) section carefully and consider whether the GitHub Pages feature is suitable for you.

> This guide focuses on Windows OS users only. If you are using another operating system, please refer to the official guide [here](https://chirpy.cotes.page/posts/getting-started) to create your own blog with the same theme.
{: .prompt-warning }

## Preparation

- GitHub account: You can go to [github.com](https://github.com) to **Sign up**, or **Sign in** if you already have an account.
- Choose a suitable and memorable **username** for your GitHub account: Because your final blog will have a domain in the format `http(s)://<username>.github.io`, so the username is quite important.

![Desktop View](/assets/img/2024-09-create-blog-like-this/01_change_username.png){: width="928" height="171" .w-30}
> You can change **username** in your account settings.
{: .prompt-tip }

- Install [Docker Desktop](https://www.docker.com/products/docker-desktop).

> Docker is a virtual environment, where you can write posts and review your blog locally before publishing it.

- Install [Visual Studio Code (VSCode)](https://code.visualstudio.com/download) and the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension.

> If you don't know how to install extensions for VSCode, please refer [here](https://code.visualstudio.com/docs/editor/extension-marketplace).

## Step by step to create a blog like this

### Step 1: Fork your own copy from repository [Chirpy Jekyll theme](https://github.com/cotes2020/jekyll-theme-chirpy).

![Desktop View](/assets/img/2024-09-create-blog-like-this/02_fork_chirpy_jekyll_theme.png){: width="1585" height="381" }
![Desktop View](/assets/img/2024-09-create-blog-like-this/03_create_fork_repo.png){: width="749" height="550" .w-75}
> [1] Enter `Repository name` in the format `<username>.github.io`, replacing `username` with your GitHub username. This will be the domain name of the blog when it is hosted.<br>
> [2] Click `Create fork`.

After forking the repository, we will configure a few more steps so that GitHub Pages can build and deployment automatically.
![Desktop View](/assets/img/2024-09-create-blog-like-this/04_settings_pages_github_action.png){: width="1002" height="527" }
> [1] Go to the `Settings` of the repository you just forked.<br>
> [2] Click `Pages`.<br>
> [3] Choose Build and deployment Source is `GitHub Actions`.

![Desktop View](/assets/img/2024-09-create-blog-like-this/05_enable_workflows_github_action.png){: width="1313" height="461" }
> [1] Go to the `Actions` of your repository.<br>
> [2] Click `I understand...enable them`.

### Step 2: Clone and setup docker environment.



Step 3: Publish your first initialize page.

Step 4: Access the domain `<username>.github.io` and see the results.

Step 5: Configure your personal information.

Step 6: Write a 'Hello world!' post.
